import { query } from "./db.js";

// GET /rides/:id
export async function getRide(c) {
  const { id } = c.req.valid("param");

  const [row] = await query(`SELECT id, user_id, distance FROM rides WHERE id = :id`, {
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
