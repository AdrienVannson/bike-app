import { DatabaseResumingException } from "@aws-sdk/client-rds-data";
import { handle } from "@hono/aws-lambda";
import { zValidator } from "@hono/zod-validator";
import { Hono } from "hono";
import { z } from "zod";
import { getRide } from "./rides.js";

const app = new Hono();

const idParam = z.object({
  id: z.string().regex(/^\d+$/).transform(Number).pipe(z.int()),
});

app.get(
  "/rides/:id",
  zValidator("param", idParam, (result, c) => {
    if (!result.success) {
      return c.json({ message: "Invalid id" }, 400);
    }
  }),
  getRide,
);

app.notFound((c) => c.json({ message: "Not found" }, 404));

app.onError((error, c) => {
  if (error instanceof DatabaseResumingException) {
    c.header("retry-after", "30");
    return c.json({ message: "Database is starting, try again" }, 503);
  }
  console.error(error);
  return c.json({ message: "Internal server error" }, 500);
});

export const handler = handle(app);
