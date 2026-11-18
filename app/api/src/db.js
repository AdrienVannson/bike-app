// Database access through the RDS Data API. The AWS SDK v3 ships with the
// Lambda Node.js runtime, so it is not bundled.
import {
  DatabaseResumingException,
  ExecuteStatementCommand,
  RDSDataClient,
} from "@aws-sdk/client-rds-data";
import { setTimeout as sleep } from "node:timers/promises";

const client = new RDSDataClient({});

const db = {
  resourceArn: process.env.DB_CLUSTER_ARN,
  secretArn: process.env.DB_SECRET_ARN,
  database: process.env.DB_NAME,
};

/**
 * Runs one SQL statement and returns its rows as plain objects (keys are the
 * column names). `params` maps `:name` placeholders to Data API values, e.g.
 * `{ id: { longValue: 1 } }`.
 */
export async function query(sql, params = {}) {
  const parameters = Object.entries(params).map(([name, value]) => ({
    name,
    value,
  }));
  const command = new ExecuteStatementCommand({
    ...db,
    sql,
    parameters,
    formatRecordsAs: "JSON",
  });

  // The cluster auto-pauses; calls fail while it resumes (~15-30s). Retry for
  // a while, staying under the API Gateway 30s timeout.
  for (let attempt = 1; ; attempt++) {
    try {
      const { formattedRecords } = await client.send(command);
      return JSON.parse(formattedRecords ?? "[]");
    } catch (error) {
      if (!(error instanceof DatabaseResumingException) || attempt === 4) throw error;
      await sleep(5_000);
    }
  }
}
