DROP INDEX IF EXISTS "Post_localityId_idx";

CREATE INDEX "Post_localityId_deletedAt_createdAt_id_idx"
    ON "Post"("localityId", "deletedAt", "createdAt", "id");
