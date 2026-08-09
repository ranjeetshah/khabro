DO $$
BEGIN
    CREATE TYPE "GeographicAreaType" AS ENUM ('COUNTRY', 'STATE', 'CITY', 'LOCALITY');
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

ALTER TABLE "Locality"
    ADD COLUMN IF NOT EXISTS "type" "GeographicAreaType" NOT NULL DEFAULT 'LOCALITY',
    ADD COLUMN IF NOT EXISTS "parentId" TEXT;

DROP INDEX IF EXISTS "Locality_name_city_state_country_key";

CREATE UNIQUE INDEX IF NOT EXISTS "Locality_name_type_parentId_key"
    ON "Locality"("name", "type", "parentId");

CREATE INDEX IF NOT EXISTS "Locality_type_idx" ON "Locality"("type");
CREATE INDEX IF NOT EXISTS "Locality_parentId_idx" ON "Locality"("parentId");

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'Locality_parentId_fkey'
    ) THEN
        ALTER TABLE "Locality"
            ADD CONSTRAINT "Locality_parentId_fkey"
            FOREIGN KEY ("parentId") REFERENCES "Locality"("id")
            ON DELETE RESTRICT ON UPDATE CASCADE;
    END IF;
END $$;

-- Small deterministic development hierarchy. Existing rows are preserved.
INSERT INTO "Locality" ("id", "name", "type", "parentId", "city", "state", "country", "createdAt", "updatedAt")
VALUES
    ('development-country-india', 'India', 'COUNTRY', NULL, 'India', 'India', 'India', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('development-state-delhi', 'Delhi', 'STATE', 'development-country-india', 'Delhi', 'Delhi', 'India', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('development-city-delhi', 'Delhi', 'CITY', 'development-state-delhi', 'Delhi', 'Delhi', 'India', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('development-locality-a', 'Test Locality A', 'LOCALITY', 'development-city-delhi', 'Delhi', 'Delhi', 'India', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('development-state-maharashtra', 'Maharashtra', 'STATE', 'development-country-india', 'Mumbai', 'Maharashtra', 'India', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('development-city-mumbai', 'Mumbai', 'CITY', 'development-state-maharashtra', 'Mumbai', 'Maharashtra', 'India', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('development-locality-b', 'Test Locality B', 'LOCALITY', 'development-city-mumbai', 'Mumbai', 'Maharashtra', 'India', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("id") DO NOTHING;
