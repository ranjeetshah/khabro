import {
  BadRequestException,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { DatabaseService } from '../database/database.service';
import { CivicComplaintStatus, VerificationStatus } from '../generated/prisma/enums';
import { MailService } from '../mail/mail.service';

export interface SafeCivicComplaintResponse {
  referenceCode: string;
  status: CivicComplaintStatus;
  witnessCount: number;
  sentAt: Date | null;
}

@Injectable()
export class CivicComplaintService {
  private readonly logger = new Logger(CivicComplaintService.name);

  constructor(
    private readonly database: DatabaseService,
    private readonly mailService: MailService,
    private readonly configService: ConfigService,
  ) {}

  get witnessThreshold(): number {
    const configured = this.configService.get<string | number>(
      'CIVIC_COMPLAINT_WITNESS_THRESHOLD',
    );
    const parsed = typeof configured === 'number' ? configured : parseInt(String(configured ?? '20'), 10);
    return isNaN(parsed) || parsed < 1 ? 20 : parsed;
  }

  get maxCcWitnesses(): number {
    const configured = this.configService.get<string | number>(
      'CIVIC_COMPLAINT_MAX_CC_WITNESSES',
    );
    const parsed = typeof configured === 'number' ? configured : parseInt(String(configured ?? '20'), 10);
    return isNaN(parsed) || parsed < 1 ? 20 : parsed;
  }

  get authorityEmail(): string | null {
    const email = this.configService.get<string>(
      'CIVIC_COMPLAINT_AUTHORITY_EMAIL',
    );
    return email && email.trim().length > 0 ? email.trim() : null;
  }

  async evaluateAndGenerateComplaint(postId: string) {
    const post = await this.database.post.findFirst({
      where: { id: postId, deletedAt: null },
      select: {
        id: true,
        content: true,
        verificationStatus: true,
        createdAt: true,
        authorId: true,
        locality: {
          select: {
            name: true,
            city: true,
            state: true,
            country: true,
          },
        },
      },
    });

    if (!post) {
      return null;
    }

    if (post.verificationStatus !== VerificationStatus.LOCALLY_VERIFIED) {
      return null;
    }

    // Check unique witnesses excluding author
    const witnessCount = await this.database.witness.count({
      where: {
        postId,
        userId: { not: post.authorId },
      },
    });

    if (witnessCount < this.witnessThreshold) {
      return null;
    }

    // Check if complaint already exists for this post
    const existing = await this.database.civicComplaint.findUnique({
      where: { postId },
    });

    if (existing) {
      return existing;
    }

    // Single efficient query for opted-in witnesses up to max CC limit
    const optedInWitnesses = await this.database.witness.findMany({
      where: {
        postId,
        userId: { not: post.authorId },
        user: { allowCivicComplaintContactSharing: true },
      },
      take: this.maxCcWitnesses,
      orderBy: { createdAt: 'asc' },
      select: {
        user: {
          select: {
            phone: true,
            name: true,
          },
        },
      },
    });

    const referenceCode = await this.generateUniqueReferenceCode();
    const targetEmail = this.authorityEmail;

    const locationText = post.locality
      ? `${post.locality.name}, ${post.locality.city}, ${post.locality.state}, ${post.locality.country}`
      : 'Local Community';

    const subject = `Community Verified Civic Issue — Khabro Reference ${referenceCode}`;
    const bodyLines = [
      `Khabro Civic Complaint Reference: ${referenceCode}`,
      `Issue Description: ${post.content}`,
      `Reported Date: ${post.createdAt.toISOString()}`,
      `Location: ${locationText}`,
      `Community Witness Count: ${witnessCount}`,
      `Verification Signal: ${witnessCount} local users have indicated that they personally witnessed this situation.`,
      `Request: Please review this community-verified issue and take appropriate civic action.`,
    ];

    const optedInContacts = optedInWitnesses
      .map((w) => w.user.name ? `${w.user.name} (${w.user.phone})` : w.user.phone)
      .filter((contact): contact is string => Boolean(contact));

    if (optedInContacts.length > 0) {
      bodyLines.push(`Opted-in Witness Contacts: ${optedInContacts.join(', ')}`);
    }

    const body = bodyLines.join('\n\n');

    // Step 1: Create DRAFT complaint inside DB transaction
    const complaint = await this.database.civicComplaint.create({
      data: {
        postId,
        referenceCode,
        authorityEmail: targetEmail || 'UNCONFIGURED_AUTHORITY_EMAIL',
        subject,
        body,
        witnessCount,
        status: CivicComplaintStatus.DRAFT,
      },
    });

    // Step 2: Attempt sending email outside DB transaction
    return this.dispatchEmail(complaint.id, targetEmail, subject, body);
  }

  async dispatchEmail(
    complaintId: string,
    targetEmail: string | null,
    subject: string,
    body: string,
  ) {
    if (!targetEmail) {
      this.logger.warn(
        `Authority email missing. Marking complaint ${complaintId} as FAILED.`,
      );
      return this.database.civicComplaint.update({
        where: { id: complaintId },
        data: { status: CivicComplaintStatus.FAILED },
      });
    }

    const emailSent = await this.mailService.sendEmail({
      to: targetEmail,
      subject,
      body,
    });

    if (emailSent) {
      return this.database.civicComplaint.update({
        where: { id: complaintId },
        data: {
          status: CivicComplaintStatus.SENT,
          sentAt: new Date(),
        },
      });
    } else {
      return this.database.civicComplaint.update({
        where: { id: complaintId },
        data: { status: CivicComplaintStatus.FAILED },
      });
    }
  }

  async retryComplaint(complaintId: string) {
    const complaint = await this.database.civicComplaint.findUnique({
      where: { id: complaintId },
    });

    if (!complaint) {
      throw new NotFoundException('Civic complaint not found');
    }

    if (complaint.status === CivicComplaintStatus.SENT) {
      throw new BadRequestException('Complaint has already been sent');
    }

    const targetEmail = this.authorityEmail;
    return this.dispatchEmail(
      complaint.id,
      targetEmail,
      complaint.subject,
      complaint.body,
    );
  }

  async getComplaintForPost(
    postId: string,
  ): Promise<SafeCivicComplaintResponse> {
    const post = await this.database.post.findFirst({
      where: { id: postId, deletedAt: null },
      select: { id: true },
    });

    if (!post) {
      throw new NotFoundException('Post not found');
    }

    const complaint = await this.database.civicComplaint.findUnique({
      where: { postId },
      select: {
        referenceCode: true,
        status: true,
        witnessCount: true,
        sentAt: true,
      },
    });

    if (!complaint) {
      throw new NotFoundException('No civic complaint found for this post');
    }

    return complaint;
  }

  private async generateUniqueReferenceCode(): Promise<string> {
    const year = new Date().getFullYear();
    for (let attempts = 0; attempts < 10; attempts++) {
      const randomDigits = Math.floor(100000 + Math.random() * 900000);
      const code = `KH-${year}-${randomDigits}`;
      const existing = await this.database.civicComplaint.findUnique({
        where: { referenceCode: code },
        select: { id: true },
      });
      if (!existing) {
        return code;
      }
    }
    return `KH-${year}-${Date.now().toString().slice(-6)}`;
  }
}
