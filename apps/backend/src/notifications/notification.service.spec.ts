import { NotFoundException } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import { DatabaseService } from '../database/database.service';
import { NotificationType } from '../generated/prisma/enums';
import { NotificationService } from './notification.service';

describe('NotificationService', () => {
  let service: NotificationService;
  let database: any;

  beforeEach(async () => {
    database = {
      notification: {
        findFirst: jest.fn(),
        create: jest.fn(),
        findMany: jest.fn(),
        count: jest.fn(),
        update: jest.fn(),
        updateMany: jest.fn(),
      },
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        NotificationService,
        { provide: DatabaseService, useValue: database },
      ],
    }).compile();

    service = module.get<NotificationService>(NotificationService);
  });

  it('creates notification for user', async () => {
    database.notification.findFirst.mockResolvedValue(null);
    database.notification.create.mockResolvedValue({
      id: 'notif-1',
      userId: 'user-1',
      type: NotificationType.CIVIC_COMPLAINT_SENT,
      title: 'Civic complaint sent',
      body: 'Your civic complaint KH-2026-000123 was sent to the concerned authority.',
      referenceType: 'CIVIC_COMPLAINT',
      referenceId: 'KH-2026-000123',
      isRead: false,
      createdAt: new Date(),
    });

    const notif = await service.createCivicComplaintNotification(
      database,
      'user-1',
      NotificationType.CIVIC_COMPLAINT_SENT,
      'KH-2026-000123',
    );

    expect(notif?.id).toBe('notif-1');
    expect(database.notification.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          userId: 'user-1',
          type: NotificationType.CIVIC_COMPLAINT_SENT,
          title: 'Civic complaint sent',
          referenceId: 'KH-2026-000123',
        }),
      }),
    );
  });

  it('does NOT create duplicate notification when event is retried (idempotency)', async () => {
    database.notification.findFirst.mockResolvedValue({
      id: 'existing-notif-1',
      userId: 'user-1',
      type: NotificationType.CIVIC_COMPLAINT_ACKNOWLEDGED,
    });

    const notif = await service.createCivicComplaintNotification(
      database,
      'user-1',
      NotificationType.CIVIC_COMPLAINT_ACKNOWLEDGED,
      'KH-2026-000123',
    );

    expect(notif.id).toBe('existing-notif-1');
    expect(database.notification.create).not.toHaveBeenCalled();
  });

  it('fetches paginated notifications for user', async () => {
    database.notification.findMany.mockResolvedValue([
      {
        id: 'notif-1',
        type: NotificationType.CIVIC_COMPLAINT_ACKNOWLEDGED,
        title: 'Complaint acknowledged',
        body: 'Your civic complaint KH-2026-000123 has been acknowledged.',
        referenceType: 'CIVIC_COMPLAINT',
        referenceId: 'KH-2026-000123',
        isRead: false,
        createdAt: new Date(),
      },
    ]);

    const res = await service.getForUser('user-1', 1, 20);

    expect(res.length).toBe(1);
    expect(database.notification.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { userId: 'user-1' },
        skip: 0,
        take: 20,
      }),
    );
  });

  it('gets unread count scoped to user', async () => {
    database.notification.count.mockResolvedValue(3);

    const res = await service.getUnreadCount('user-1');

    expect(res).toEqual({ unreadCount: 3 });
    expect(database.notification.count).toHaveBeenCalledWith({
      where: { userId: 'user-1', isRead: false },
    });
  });

  it('marks single notification as read if owned by user', async () => {
    database.notification.findFirst.mockResolvedValue({ id: 'notif-1' });
    database.notification.update.mockResolvedValue({ id: 'notif-1', isRead: true });

    const res = await service.markAsRead('user-1', 'notif-1');

    expect(res).toEqual({ isRead: true });
    expect(database.notification.update).toHaveBeenCalledWith({
      where: { id: 'notif-1' },
      data: { isRead: true },
    });
  });

  it('throws NotFoundException when marking notification of another user as read', async () => {
    database.notification.findFirst.mockResolvedValue(null);

    await expect(service.markAsRead('user-2', 'notif-1')).rejects.toThrow(
      NotFoundException,
    );
  });

  it('marks all user notifications as read', async () => {
    database.notification.updateMany.mockResolvedValue({ count: 5 });

    const res = await service.markAllAsRead('user-1');

    expect(res).toEqual({ updatedCount: 5 });
    expect(database.notification.updateMany).toHaveBeenCalledWith({
      where: { userId: 'user-1', isRead: false },
      data: { isRead: true },
    });
  });
});
