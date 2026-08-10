-- CreateEnum
CREATE TYPE "VerificationStatus" AS ENUM ('REPORTED', 'UNDER_VERIFICATION', 'LOCALLY_VERIFIED');

-- AlterTable
ALTER TABLE "Post" ADD COLUMN     "verificationStatus" "VerificationStatus" NOT NULL DEFAULT 'REPORTED';
