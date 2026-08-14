-- CreateEnum
CREATE TYPE "AdvertisementStatus" AS ENUM ('DRAFT', 'ACTIVE', 'PAUSED', 'EXPIRED');

-- CreateEnum
CREATE TYPE "AdvertisementPlacement" AS ENUM ('FEED', 'POST_DETAIL', 'PROFILE');

-- CreateTable
CREATE TABLE "Advertisement" (
    "id" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "description" TEXT,
    "advertiserName" TEXT NOT NULL,
    "creativeUrl" TEXT NOT NULL,
    "destinationUrl" TEXT NOT NULL,
    "ctaLabel" TEXT,
    "placement" "AdvertisementPlacement" NOT NULL,
    "status" "AdvertisementStatus" NOT NULL DEFAULT 'DRAFT',
    "startAt" TIMESTAMP(3),
    "endAt" TIMESTAMP(3),
    "impressionCount" INTEGER NOT NULL DEFAULT 0,
    "clickCount" INTEGER NOT NULL DEFAULT 0,
    "createdById" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "deletedAt" TIMESTAMP(3),

    CONSTRAINT "Advertisement_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "Advertisement_status_placement_deletedAt_startAt_endAt_idx" ON "Advertisement"("status", "placement", "deletedAt", "startAt", "endAt");

-- CreateIndex
CREATE INDEX "Advertisement_createdById_createdAt_idx" ON "Advertisement"("createdById", "createdAt");

-- AddForeignKey
ALTER TABLE "Advertisement" ADD CONSTRAINT "Advertisement_createdById_fkey" FOREIGN KEY ("createdById") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
