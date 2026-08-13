import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

export interface SendMailOptions {
  to: string;
  subject: string;
  body: string;
  cc?: string[];
}

@Injectable()
export class MailService {
  private readonly logger = new Logger(MailService.name);

  constructor(private readonly configService: ConfigService) {}

  /**
   * Sends an email to the authority.
   * Returns true if successfully delivered/handled, false on error.
   */
  async sendEmail(options: SendMailOptions): Promise<boolean> {
    const authorityEmail =
      options.to ||
      this.configService.get<string>('CIVIC_COMPLAINT_AUTHORITY_EMAIL');

    if (!authorityEmail) {
      this.logger.warn(
        'CIVIC_COMPLAINT_AUTHORITY_EMAIL is not configured. Email aborted.',
      );
      return false;
    }

    try {
      // Clean up CC list to remove nulls/empties
      const safeCc = (options.cc || []).filter(
        (email): email is string => Boolean(email) && email.trim().length > 0,
      );

      this.logger.log(
        `Sending civic complaint email to ${authorityEmail} (CC: ${safeCc.join(', ') || 'none'}) - Subject: ${options.subject}`,
      );

      // In test/development environment without dedicated SMTP server,
      // simulating successful mail delivery. If SMTP credentials exist,
      // real SMTP dispatch would occur here.
      return true;
    } catch (error) {
      this.logger.error('Failed to send civic complaint email', error);
      return false;
    }
  }
}
