import type { Context } from "hono";
import { z } from "zod";
import { query } from "./db.ts";

export const rideParam = z.object({
  id: z.string().regex(/^\d+$/).transform(Number).pipe(z.int()),
});

type RideContext = Context<
  object,
  "/rides/:id",
  { in: { param: z.input<typeof rideParam> }; out: { param: z.output<typeof rideParam> } }
>;

type RideRow = {
  id: number;
  user_id: number;
  distance: number;
};

// GET /rides/:id
export async function getRide(c: RideContext) {
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
