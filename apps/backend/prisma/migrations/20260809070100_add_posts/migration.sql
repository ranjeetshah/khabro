CREATE TABLE "Post" (
    "id" TEXT NOT NULL,
    "authorId" TEXT NOT NULL,
    "localityId" TEXT,
    "content" TEXT NOT NULL,
    "deletedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Post_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "Post_authorId_createdAt_idx" ON "Post"("authorId", "createdAt");
CREATE INDEX "Post_localityId_idx" ON "Post"("localityId");

ALTER TABLE "Post"
    ADD CONSTRAINT "Post_authorId_fkey"
    FOREIGN KEY ("authorId") REFERENCES "User"("id")
    ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "Post"
    ADD CONSTRAINT "Post_localityId_fkey"
    FOREIGN KEY ("localityId") REFERENCES "Locality"("id")
    ON DELETE SET NULL ON UPDATE CASCADE;
