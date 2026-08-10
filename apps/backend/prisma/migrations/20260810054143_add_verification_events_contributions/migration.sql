-- CreateEnum
CREATE TYPE "VerificationEventType" AS ENUM ('POST_CREATED', 'WITNESS_ADDED', 'WITNESS_REMOVED', 'STATUS_CHANGED');

-- CreateEnum
CREATE TYPE "VerificationContributionType" AS ENUM ('WITNESS', 'STATUS_TRANSITION');

-- CreateTable
CREATE TABLE "VerificationEvent" (
    "id" TEXT NOT NULL,
    "postId" TEXT NOT NULL,
    "type" "VerificationEventType" NOT NULL,
    "fromStatus" "VerificationStatus",
    "toStatus" "VerificationStatus",
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "VerificationEvent_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "VerificationContribution" (
    "id" TEXT NOT NULL,
    "postId" TEXT NOT NULL,
    "type" "VerificationContributionType" NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "VerificationContribution_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "VerificationEvent_postId_createdAt_id_idx" ON "VerificationEvent"("postId", "createdAt", "id");

-- CreateIndex
CREATE INDEX "VerificationContribution_postId_createdAt_id_idx" ON "VerificationContribution"("postId", "createdAt", "id");

-- AddForeignKey
ALTER TABLE "VerificationEvent" ADD CONSTRAINT "VerificationEvent_postId_fkey" FOREIGN KEY ("postId") REFERENCES "Post"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "VerificationContribution" ADD CONSTRAINT "VerificationContribution_postId_fkey" FOREIGN KEY ("postId") REFERENCES "Post"("id") ON DELETE CASCADE ON UPDATE CASCADE;
