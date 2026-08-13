-- AlterTable
ALTER TABLE "ModerationAuditEvent" ADD COLUMN     "actorId" TEXT;

-- CreateIndex
CREATE INDEX "ModerationAuditEvent_actorId_idx" ON "ModerationAuditEvent"("actorId");
