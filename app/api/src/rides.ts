import type { Context } from "hono";
import { z } from "zod";
import { query } from "./db.ts";

export const rideParam = z.object({
  id: z.string().regex(/^\d+$/).transform(Number).pipe(z.int()),
});

type RideContext<Path extends string> = Context<
  object,
  Path,
  { in: { param: z.input<typeof rideParam> }; out: { param: z.output<typeof rideParam> } }
>;

type RideRow = {
  id: number;
  user_id: number;
  distance: number;
};

// GET /rides/:id
export async function getRide(c: RideContext<"/rides/:id">) {
  const { id } = c.req.valid("param");

  const [row] = await query<RideRow>(`SELECT id, user_id, distance FROM rides WHERE id = :id`, {
    id: { longValue: id },
  });
  if (!row) {
    return c.json({ message: "Ride not found" }, 404);
  }
  return c.json({
    id: row.id,
    userId: row.user_id,
    distance: row.distance,
  });
}

type TrackRow = {
  track: string | null;
};

type LineString = {
  type: "LineString";
  coordinates: [longitude: number, latitude: number][];
};

// GET /rides/:id/track
//
// The ride's track, as a GeoJSON LineString.
//
// TODO: use the real track, not the DB simplified one
export async function getRideTrack(c: RideContext<"/rides/:id/track">) {
  const { id } = c.req.valid("param");

  const [row] = await query<TrackRow>(
    `SELECT ST_AsGeoJSON(simplified_track, 6) AS track FROM rides WHERE id = :id`,
    { id: { longValue: id } },
  );
  if (!row) {
    return c.json({ message: "Ride not found" }, 404);
  }
  if (row.track === null) {
    return c.json({ message: "Ride has no track" }, 404);
  }
  return c.json(JSON.parse(row.track) as LineString);
}
