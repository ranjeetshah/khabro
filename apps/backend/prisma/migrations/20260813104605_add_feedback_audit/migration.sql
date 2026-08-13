-- AlterEnum
ALTER TYPE "ModerationAuditAction" ADD VALUE 'FEEDBACK_STATUS_UPDATED';

-- AlterTable
ALTER TABLE "ModerationAuditEvent" ADD COLUMN     "feedbackId" TEXT;
