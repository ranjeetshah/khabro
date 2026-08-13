-- CreateEnum
CREATE TYPE "UserRole" AS ENUM ('CITIZEN', 'MODERATOR');

-- AlterEnum
-- This migration adds more than one value to an enum.
-- With PostgreSQL versions 11 and earlier, this is not possible
-- in a single migration. This can be worked around by creating
-- multiple migrations, each migration adding only one value to
-- the enum.


ALTER TYPE "CivicComplaintStatus" ADD VALUE 'ACKNOWLEDGED';
ALTER TYPE "CivicComplaintStatus" ADD VALUE 'IN_PROGRESS';
ALTER TYPE "CivicComplaintStatus" ADD VALUE 'RESOLVED';
ALTER TYPE "CivicComplaintStatus" ADD VALUE 'CITIZEN_CONFIRMED';
ALTER TYPE "CivicComplaintStatus" ADD VALUE 'REOPENED';

-- AlterTable
ALTER TABLE "User" ADD COLUMN     "role" "UserRole" NOT NULL DEFAULT 'CITIZEN';

-- CreateTable
CREATE TABLE "CivicComplaintStatusHistory" (
    "id" TEXT NOT NULL,
    "complaintId" TEXT NOT NULL,
    "fromStatus" "CivicComplaintStatus",
    "toStatus" "CivicComplaintStatus" NOT NULL,
    "actorId" TEXT NOT NULL,
    "note" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "CivicComplaintStatusHistory_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "CivicComplaintStatusHistory_complaintId_createdAt_id_idx" ON "CivicComplaintStatusHistory"("complaintId", "createdAt", "id");

-- CreateIndex
CREATE INDEX "CivicComplaintStatusHistory_actorId_idx" ON "CivicComplaintStatusHistory"("actorId");

-- AddForeignKey
ALTER TABLE "CivicComplaintStatusHistory" ADD CONSTRAINT "CivicComplaintStatusHistory_complaintId_fkey" FOREIGN KEY ("complaintId") REFERENCES "CivicComplaint"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "CivicComplaintStatusHistory" ADD CONSTRAINT "CivicComplaintStatusHistory_actorId_fkey" FOREIGN KEY ("actorId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
