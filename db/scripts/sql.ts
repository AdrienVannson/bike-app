// AI-generated
//
// Runs SQL files against the Aurora database through the RDS Data API, all in
// a single transaction: if any statement fails, nothing is changed.
//
// The Data API takes one statement per call, so the files are split into
// statements (see splitStatements).
//
// Needs: AWS credentials and terraform.

import { execFileSync } from "node:child_process";
import { existsSync, readFileSync } from "node:fs";
import { resolve } from "node:path";
import { createInterface } from "node:readline/promises";
import { setTimeout as sleep } from "node:timers/promises";
import {
  BeginTransactionCommand,
  CommitTransactionCommand,
  DatabaseResumingException,
  ExecuteStatementCommand,
  RDSDataClient,
  RollbackTransactionCommand,
} from "@aws-sdk/client-rds-data";

const DB = "bike";
const ROOT = resolve(import.meta.dirname, "../..");
const ENVS = ["dev", "test", "prod"] as const;
type Env = (typeof ENVS)[number];
const USAGE = "usage: pnpm db:<dev|test|prod>:sql FILE...";

/**
 * Splits a SQL file into statements. A statement ends at a line ending with
 * `;`, unless that line is inside a $$-quoted body (e.g. a function).
 * Whole-line `--` comments are dropped.
 */
export function splitStatements(sql: string): string[] {
  const statements: string[] = [];
  let lines: string[] = [];
  let inDollarQuote = false;

  const flush = () => {
    const statement = lines.join("\n").trim();
    if (statement) statements.push(statement);
    lines = [];
  };

  for (const line of sql.split(/\r?\n/)) {
    if (!inDollarQuote && /^\s*--/.test(line)) continue;
    lines.push(line);
    // An odd number of $$ on the line opens or closes a quoted body.
    if ((line.match(/\$\$/g) ?? []).length % 2 === 1) inDollarQuote = !inDollarQuote;
    if (!inDollarQuote && /;\s*$/.test(line)) flush();
  }
  if (inDollarQuote) throw new Error("unterminated $$-quoted body");
  flush();
  return statements;
}

/** First line of a statement, shortened, for progress messages. */
function summary(statement: string): string {
  return statement.split("\n")[0].trim().slice(0, 72);
}

function terraformOutput(env: Env, name: string): string {
  const dir = resolve(ROOT, "infra/envs", env);
  return execFileSync("terraform", [`-chdir=${dir}`, "output", "-raw", name], {
    encoding: "utf8",
    stdio: ["ignore", "pipe", "inherit"],
  }).trim();
}

/** Splits the arguments into `--env <name>` (required) and files. */
function parseArgs(args: string[]): { env: Env; files: string[] } {
  let env: Env | undefined;
  const files: string[] = [];
  for (let i = 0; i < args.length; i++) {
    if (args[i] !== "--env") {
      files.push(args[i]);
      continue;
    }
    const value = args[++i];
    if (!ENVS.includes(value as Env)) {
      throw new Error(`--env must be one of ${ENVS.join(", ")}, got: ${value ?? "nothing"}`);
    }
    env = value as Env;
  }
  if (!env) throw new Error(`--env is required (one of ${ENVS.join(", ")})`);
  return { env, files };
}

async function confirm(question: string): Promise<boolean> {
  const rl = createInterface({ input: process.stdin, output: process.stdout });
  // No transaction is open yet, so Ctrl-C can simply exit.
  rl.on("SIGINT", () => {
    console.log("\nAborted.");
    process.exit(1);
  });
  try {
    return /^y/i.test(await rl.question(question));
  } finally {
    rl.close();
  }
}

async function run(env: Env, files: string[]): Promise<void> {
  const statements = files.flatMap((f) => {
    try {
      return splitStatements(readFileSync(f, "utf8"));
    } catch (err) {
      throw new Error(`${f}: ${(err as Error).message}`);
    }
  });
  if (statements.length === 0) throw new Error("no statements found");

  const resourceArn = terraformOutput(env, "db_cluster_arn");
  const secretArn = terraformOutput(env, "db_secret_arn");
  const db = { resourceArn, secretArn };
  // arn:aws:rds:REGION:ACCOUNT:cluster:NAME
  const client = new RDSDataClient({ region: resourceArn.split(":")[3] });

  console.log(`Statements to run on ${env} (${resourceArn}):`);
  for (const [i, s] of statements.entries()) {
    console.log(`  ${String(i + 1).padStart(3)}  ${summary(s)}`);
  }
  if (!(await confirm("Run them? [y/N] "))) {
    console.log("Aborted.");
    process.exit(1);
  }

  // Ctrl-C cancels the current call; the transaction is then rolled back.
  const abort = new AbortController();
  process.once("SIGINT", () => abort.abort());
  const { signal } = abort;

  let transactionId: string | undefined;
  try {
    // The cluster auto-pauses; calls fail while it resumes (~15-30s).
    for (let attempt = 1; !transactionId; attempt++) {
      try {
        const res = await client.send(new BeginTransactionCommand({ ...db, database: DB }), {
          abortSignal: signal,
        });
        transactionId = res.transactionId;
      } catch (err) {
        if (!(err instanceof DatabaseResumingException) || attempt === 12) throw err;
        if (attempt === 1) console.log("Database is resuming from auto-pause, waiting...");
        await sleep(10_000, undefined, { signal });
      }
    }

    for (const [i, sql] of statements.entries()) {
      console.log(`  [${i + 1}/${statements.length}] ${summary(sql)}`);
      await client.send(
        new ExecuteStatementCommand({
          ...db,
          database: DB,
          transactionId,
          sql,
        }),
        { abortSignal: signal },
      );
    }

    await client.send(new CommitTransactionCommand({ ...db, transactionId }), {
      abortSignal: signal,
    });
    transactionId = undefined;
    console.log("Done.");
  } finally {
    if (transactionId) {
      console.error("Rolling back.");
      await client.send(new RollbackTransactionCommand({ ...db, transactionId })).catch(() => {});
    }
  }
}

async function main(): Promise<void> {
  const { env, files: args } = parseArgs(process.argv.slice(2));
  if (args.length === 0) {
    console.error(USAGE);
    process.exit(2);
  }
  // pnpm runs scripts from the repo root; resolve paths from where it was called.
  const files = args.map((f) => resolve(process.env.INIT_CWD ?? process.cwd(), f));
  for (const f of files) {
    if (!existsSync(f)) throw new Error(`no such file: ${f}`);
  }

  await run(env, files);
}

if (import.meta.main) {
  main().catch((err: Error) => {
    if (err.name === "AbortError") console.error("Interrupted.");
    else if (err.name === "Error") console.error(`error: ${err.message}`);
    else console.error(`error: ${err.name}: ${err.message}`); // e.g. an AWS error
    process.exit(1);
  });
}
