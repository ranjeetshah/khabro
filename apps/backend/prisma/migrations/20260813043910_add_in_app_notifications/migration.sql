-- CreateEnum
CREATE TYPE "NotificationType" AS ENUM ('CIVIC_COMPLAINT_SENT', 'CIVIC_COMPLAINT_ACKNOWLEDGED', 'CIVIC_COMPLAINT_IN_PROGRESS', 'CIVIC_COMPLAINT_RESOLVED', 'CIVIC_COMPLAINT_CONFIRMED', 'CIVIC_COMPLAINT_REOPENED');

-- CreateTable
CREATE TABLE "Notification" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "type" "NotificationType" NOT NULL,
    "title" TEXT NOT NULL,
    "body" TEXT NOT NULL,
    "referenceType" TEXT NOT NULL DEFAULT 'CIVIC_COMPLAINT',
    "referenceId" TEXT NOT NULL,
    "isRead" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Notification_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "Notification_userId_isRead_createdAt_idx" ON "Notification"("userId", "isRead", "createdAt");

-- CreateIndex
CREATE INDEX "Notification_userId_createdAt_idx" ON "Notification"("userId", "createdAt");

-- CreateIndex
CREATE INDEX "Notification_userId_referenceType_referenceId_type_idx" ON "Notification"("userId", "referenceType", "referenceId", "type");

-- AddForeignKey
ALTER TABLE "Notification" ADD CONSTRAINT "Notification_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
