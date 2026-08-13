import {
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { DatabaseService } from '../database/database.service';
import { NotificationType } from '../generated/prisma/enums';

export interface SafeNotificationResponse {
  id: string;
  type: NotificationType;
  title: string;
  body: string;
  referenceType: string;
  referenceId: string;
  isRead: boolean;
  createdAt: Date;
}

const CIVIC_COMPLAINT_TEMPLATES: Record<
  NotificationType,
  { title: string; body: (ref: string) => string }
> = {
  [NotificationType.CIVIC_COMPLAINT_SENT]: {
    title: 'Civic complaint sent',
    body: (ref) => `Your civic complaint ${ref} was sent to the concerned authority.`,
  },
  [NotificationType.CIVIC_COMPLAINT_ACKNOWLEDGED]: {
    title: 'Complaint acknowledged',
    body: (ref) => `Your civic complaint ${ref} has been acknowledged.`,
  },
  [NotificationType.CIVIC_COMPLAINT_IN_PROGRESS]: {
    title: 'Work started',
    body: (ref) => `Work has started on civic complaint ${ref}.`,
  },
  [NotificationType.CIVIC_COMPLAINT_RESOLVED]: {
    title: 'Complaint resolved',
    body: (ref) => `Your civic complaint ${ref} has been marked resolved.`,
  },
  [NotificationType.CIVIC_COMPLAINT_CONFIRMED]: {
    title: 'Resolution confirmed',
    body: (ref) => `You confirmed resolution of civic complaint ${ref}.`,
  },
  [NotificationType.CIVIC_COMPLAINT_REOPENED]: {
    title: 'Complaint reopened',
    body: (ref) => `Your civic complaint ${ref} has been reopened.`,
  },
};

@Injectable()
export class NotificationService {
  constructor(private readonly database: DatabaseService) {}

  async createNotification(
    dbClient: any,
    userId: string,
    type: NotificationType,
    title: string,
    body: string,
    referenceType: string,
    referenceId: string,
  ) {
    const db = dbClient || this.database;

    const existing = await db.notification.findFirst({
      where: {
        userId,
        referenceType,
        referenceId,
        type,
      },
    });

    if (existing) {
      return existing;
    }

    return db.notification.create({
      data: {
        userId,
        type,
        title,
        body,
        referenceType,
        referenceId,
      },
    });
  }

  async createCivicComplaintNotification(
    dbClient: any,
    userId: string,
    type: NotificationType,
    referenceCode: string,
  ) {
    const template = CIVIC_COMPLAINT_TEMPLATES[type];
    if (!template) return null;

    return this.createNotification(
      dbClient,
      userId,
      type,
      template.title,
      template.body(referenceCode),
      'CIVIC_COMPLAINT',
      referenceCode,
    );
  }

  async getForUser(
    userId: string,
    page = 1,
    limit = 20,
  ): Promise<SafeNotificationResponse[]> {
    const safePage = isNaN(page) || page < 1 ? 1 : page;
    const safeLimit = isNaN(limit) || limit < 1 ? 20 : Math.min(limit, 50);
    const skip = (safePage - 1) * safeLimit;

    return this.database.notification.findMany({
      where: { userId },
      skip,
      take: safeLimit,
      orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
      select: {
        id: true,
        type: true,
        title: true,
        body: true,
        referenceType: true,
        referenceId: true,
        isRead: true,
        createdAt: true,
      },
    });
  }

  async getUnreadCount(userId: string): Promise<{ unreadCount: number }> {
    const unreadCount = await this.database.notification.count({
      where: { userId, isRead: false },
    });
    return { unreadCount };
  }

  async markAsRead(
    userId: string,
    id: string,
  ): Promise<{ isRead: boolean }> {
    const notification = await this.database.notification.findFirst({
      where: { id, userId },
      select: { id: true },
    });

    if (!notification) {
      throw new NotFoundException('Notification not found');
    }

    await this.database.notification.update({
      where: { id: notification.id },
      data: { isRead: true },
    });

    return { isRead: true };
  }

  async markAllAsRead(userId: string): Promise<{ updatedCount: number }> {
    const result = await this.database.notification.updateMany({
      where: { userId, isRead: false },
      data: { isRead: true },
    });

    return { updatedCount: result.count };
  }
}
