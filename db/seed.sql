-- Sample data for development. Assumes an empty database (e.g. right after
-- `pnpm db:dev:reset`): `pnpm db:dev:seed`.
--
-- Same format rules as schema.sql: end each statement with `;` at the end of
-- a line.
INSERT INTO
  rides (user_id, started_at, distance, simplified_track)
VALUES
  (
    1,
    '2026-10-04 08:30:00+02',
    42195,
    ST_GeomFromText (
      'LINESTRING(6.1294 45.8992, 6.1702 45.8650, 6.2105 45.8031, 6.2207 45.7527, 6.1862 45.7853, 6.1530 45.8478, 6.1294 45.8992)',
      4326
    )
  ),
  (
    1,
    '2026-10-11 17:45:00+02',
    12500.5,
    ST_GeomFromText (
      'LINESTRING(4.8357 45.7640, 4.8520 45.7712, 4.8619 45.7797, 4.8551 45.7861, 4.8402 45.7790, 4.8357 45.7640)',
      4326
    )
  ),
  (1, '2026-10-25 07:15:00+01', 80300, NULL),
  (
    2,
    '2026-10-18 09:00:00+02',
    25000,
    ST_GeomFromText (
      'LINESTRING(2.3522 48.8566, 2.2945 48.8584, 2.2489 48.8462, 2.2752 48.8299, 2.3300 48.8400, 2.3522 48.8566)',
      4326
    )
  ),
  (
    2,
    '2026-11-01 14:20:00+01',
    5300.25,
    ST_GeomFromText (
      'LINESTRING(2.3522 48.8566, 2.3610 48.8650, 2.3700 48.8600, 2.3522 48.8566)',
      4326
    )
  );
