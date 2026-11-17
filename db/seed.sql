-- Sample data for development. Assumes an empty database (e.g. right after
-- `pnpm db:reset`): `pnpm db:seed`.
--
-- Same format rules as schema.sql: end each statement with `;` at the end of
-- a line.

INSERT INTO rides (user_id, distance) VALUES
    (1, 42195),
    (1, 12500.5),
    (1, 80300),
    (2, 25000),
    (2, 5300.25);
