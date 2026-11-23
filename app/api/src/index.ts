import { DatabaseResumingException } from "@aws-sdk/client-rds-data";
import { handle } from "@hono/aws-lambda";
import { zValidator } from "@hono/zod-validator";
import { Hono } from "hono";
import { getRide, getRideTrack, rideParam } from "./rides.ts";

const app = new Hono();

const validateRideParam = zValidator("param", rideParam, (result, c) => {
  if (!result.success) {
    return c.json({ message: "Invalid id" }, 400);
  }
  return undefined;
});

app.get("/rides/:id", validateRideParam, getRide);
app.get("/rides/:id/track", validateRideParam, getRideTrack);

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
