ALTER TABLE "UserLocation"
    ADD COLUMN "localityId" TEXT;

CREATE INDEX "UserLocation_localityId_idx" ON "UserLocation"("localityId");

ALTER TABLE "UserLocation"
    ADD CONSTRAINT "UserLocation_localityId_fkey"
    FOREIGN KEY ("localityId") REFERENCES "Locality"("id")
    ON DELETE SET NULL ON UPDATE CASCADE;
