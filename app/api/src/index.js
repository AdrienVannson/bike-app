// TODO: switch to Hono (hono/aws-lambda adapter) once we need body parsing or
// middleware (auth, CORS). Needs a build step (esbuild -> dist/) and
// archive_file pointed at the output, since we'd have dependencies.
import { DatabaseResumingException } from "@aws-sdk/client-rds-data";
import { json } from "./http.js";
import { getRide } from "./rides.js";

// Keys use the same "METHOD /path" format as API Gateway route keys, with
// `{name}` path parameters. Handlers read them from event.pathParameters, like
// API Gateway sets them, so a route can later be moved to its own Lambda + API
// Gateway route unchanged.
const routes = {
  "GET /rides/{id}": getRide,
};

const compiledRoutes = Object.entries(routes).map(([key, route]) => {
  const pattern = key.replace(/[.*+?^$()|[\]\\]/g, "\\$&").replace(/\{(\w+)\}/g, "(?<$1>[^/]+)");
  return { regex: new RegExp(`^${pattern}$`), route };
});

function match(method, path) {
  for (const { regex, route } of compiledRoutes) {
    const m = regex.exec(`${method} ${path}`);
    if (m) {
      const params = Object.fromEntries(
        Object.entries(m.groups ?? {}).map(([k, v]) => [k, decodeURIComponent(v)]),
      );
      return { route, params };
    }
  }
  return undefined;
}

export async function handler(event, context) {
  const { method, path } = event.requestContext.http;

  let matched;
  try {
    matched = match(method, path);
  } catch {
    return json(400, { message: "Bad request" }); // malformed %-encoding
  }
  if (!matched) {
    return json(404, { message: "Not found" });
  }

  try {
    return await matched.route(
      {
        ...event,
        pathParameters: matched.params,
      },
      context,
    );
  } catch (error) {
    if (error instanceof DatabaseResumingException) {
      return json(
        503,
        {
          message: "Database is starting, try again",
        },
        { "retry-after": "10" },
      );
    }
    console.error(error);
    return json(500, { message: "Internal server error" });
  }
}
