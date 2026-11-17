-- Sample data for development. Assumes an empty database (e.g. right after
-- `pnpm db:reset`): `pnpm db:seed`.
--
-- Same format rules as schema.sql: end each statement with `;` at the end of
-- a line.
INSERT INTO
  rides (user_id, started_at, distance)
VALUES
  (1, '2026-10-04 08:30:00+02', 42195),
  (1, '2026-10-11 17:45:00+02', 12500.5),
  (1, '2026-10-25 07:15:00+01', 80300),
  (2, '2026-10-18 09:00:00+02', 25000),
  (2, '2026-11-01 14:20:00+01', 5300.25);
