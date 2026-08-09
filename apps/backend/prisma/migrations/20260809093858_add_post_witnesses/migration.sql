-- CreateTable
CREATE TABLE "Witness" (
    "id" TEXT NOT NULL,
    "postId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Witness_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "Witness_userId_idx" ON "Witness"("userId");

-- CreateIndex
CREATE INDEX "Witness_postId_createdAt_idx" ON "Witness"("postId", "createdAt");

-- CreateIndex
CREATE UNIQUE INDEX "Witness_userId_postId_key" ON "Witness"("userId", "postId");

-- AddForeignKey
ALTER TABLE "Witness" ADD CONSTRAINT "Witness_postId_fkey" FOREIGN KEY ("postId") REFERENCES "Post"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Witness" ADD CONSTRAINT "Witness_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
