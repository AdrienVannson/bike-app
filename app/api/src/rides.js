import { query } from "./db.js";
import { json } from "./http.js";

// GET /rides/{id}
export async function getRide(event) {
  const { id } = event.pathParameters;
  if (!/^\d+$/.test(id) || !Number.isSafeInteger(Number(id))) {
    return json(400, { message: "Invalid ride id" });
  }

  const [ride] = await query(`SELECT id, user_id AS "userId", distance FROM rides WHERE id = :id`, {
    id: { longValue: Number(id) },
  });
  if (!ride) {
    return json(404, { message: "Ride not found" });
  }
  return json(200, ride);
}
