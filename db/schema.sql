-- The whole database schema. Running it recreates everything from scratch and
-- DELETES ALL DATA: `pnpm db:dev:reset` (or db:test:reset).
--
-- db/scripts/sql.ts sends statements one at a time through the RDS
-- Data API, so end each statement with `;` at the end of a line, with no
-- comment after it. `;` inside $$-quoted bodies is fine.
DROP SCHEMA IF EXISTS public CASCADE;

CREATE SCHEMA public;

GRANT USAGE ON SCHEMA public TO PUBLIC;

CREATE EXTENSION postgis;

CREATE TABLE rides (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id bigint NOT NULL,
  started_at timestamptz NOT NULL,
  distance double precision NOT NULL CHECK (distance >= 0), -- meters
  simplified_track geometry (LineString, 4326), -- TODO: give precise limit of nb of points
);

-- A user's rides, most recent first.
CREATE INDEX rides_user_id_started_at_idx ON rides (user_id, started_at DESC);
