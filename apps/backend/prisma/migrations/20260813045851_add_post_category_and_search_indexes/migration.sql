-- CreateEnum
CREATE TYPE "PostCategory" AS ENUM ('GENERAL', 'INFRASTRUCTURE', 'SAFETY', 'UTILITIES', 'ENVIRONMENT', 'OTHER');

-- AlterTable
ALTER TABLE "Post" ADD COLUMN     "category" "PostCategory" NOT NULL DEFAULT 'GENERAL';

-- CreateIndex
CREATE INDEX "Post_deletedAt_verificationStatus_createdAt_idx" ON "Post"("deletedAt", "verificationStatus", "createdAt");

-- CreateIndex
CREATE INDEX "Post_category_deletedAt_createdAt_idx" ON "Post"("category", "deletedAt", "createdAt");
