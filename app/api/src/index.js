// TODO: switch to Hono (hono/aws-lambda adapter) once we need path params,
// body parsing or middleware (auth, CORS). Needs a build step (esbuild ->
// dist/) and archive_file pointed at the output, since we'd have dependencies.
import { handler as hello } from "./hello.js";

// Keys use the same "METHOD /path" format as API Gateway route keys, so a
// route can later be moved to its own Lambda + API Gateway route unchanged.
const routes = {
  "GET /hello": hello,
};

export async function handler(event, context) {
  const { method, path } = event.requestContext.http;

  const route = routes[`${method} ${path}`];
  if (!route) {
    return json(404, { message: "Not found" });
  }

  try {
    return await route(event, context);
  } catch (error) {
    console.error(error);
    return json(500, { message: "Internal server error" });
  }
}

function json(statusCode, body) {
  return {
    statusCode,
    headers: { "content-type": "application/json" },
    body: JSON.stringify(body),
  };
}
