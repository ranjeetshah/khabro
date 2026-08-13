/*
  Warnings:

  - Changed the type of `reason` on the `UserReport` table. No cast exists, the column would be dropped and recreated, which cannot be done if there is data, since the column is required.

*/
-- CreateEnum
CREATE TYPE "UserReportReason" AS ENUM ('SPAM', 'HARASSMENT', 'IMPERSONATION', 'ABUSIVE_BEHAVIOR', 'OTHER');

-- CreateEnum
CREATE TYPE "CivicComplaintStatus" AS ENUM ('DRAFT', 'SENT', 'FAILED');

-- AlterTable
ALTER TABLE "User" ADD COLUMN     "allowCivicComplaintContactSharing" BOOLEAN NOT NULL DEFAULT false;

-- AlterTable
ALTER TABLE "UserReport" DROP COLUMN "reason",
ADD COLUMN     "reason" "UserReportReason" NOT NULL;

-- CreateTable
CREATE TABLE "CivicComplaint" (
    "id" TEXT NOT NULL,
    "postId" TEXT NOT NULL,
    "referenceCode" TEXT NOT NULL,
    "authorityEmail" TEXT NOT NULL,
    "subject" TEXT NOT NULL,
    "body" TEXT NOT NULL,
    "witnessCount" INTEGER NOT NULL,
    "status" "CivicComplaintStatus" NOT NULL DEFAULT 'DRAFT',
    "sentAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "CivicComplaint_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "CivicComplaint_postId_key" ON "CivicComplaint"("postId");

-- CreateIndex
CREATE UNIQUE INDEX "CivicComplaint_referenceCode_key" ON "CivicComplaint"("referenceCode");

-- CreateIndex
CREATE INDEX "CivicComplaint_postId_idx" ON "CivicComplaint"("postId");

-- CreateIndex
CREATE INDEX "CivicComplaint_status_idx" ON "CivicComplaint"("status");

-- CreateIndex
CREATE INDEX "CivicComplaint_referenceCode_idx" ON "CivicComplaint"("referenceCode");

-- AddForeignKey
ALTER TABLE "CivicComplaint" ADD CONSTRAINT "CivicComplaint_postId_fkey" FOREIGN KEY ("postId") REFERENCES "Post"("id") ON DELETE CASCADE ON UPDATE CASCADE;
