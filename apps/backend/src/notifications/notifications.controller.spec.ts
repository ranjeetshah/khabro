import { Test, TestingModule } from '@nestjs/testing';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { NotificationType } from '../generated/prisma/enums';
import { NotificationService } from './notification.service';
import { NotificationsController } from './notifications.controller';

describe('NotificationsController', () => {
  let controller: NotificationsController;
  let service: any;

  const authenticatedRequest = {
    user: {
      sub: 'user-1',
    },
  } as any;

  beforeEach(async () => {
    service = {
      getForUser: jest.fn(),
      getUnreadCount: jest.fn(),
      markAsRead: jest.fn(),
      markAllAsRead: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      controllers: [NotificationsController],
      providers: [
        { provide: NotificationService, useValue: service },
      ],
    })
      .overrideGuard(JwtAuthGuard)
      .useValue({ canActivate: jest.fn().mockReturnValue(true) })
      .compile();

    controller = module.get<NotificationsController>(NotificationsController);
  });

  it('gets notifications for authenticated JWT sub only', async () => {
    service.getForUser.mockResolvedValue([
      {
        id: 'notif-1',
        type: NotificationType.CIVIC_COMPLAINT_SENT,
        title: 'Civic complaint sent',
      },
    ]);

    const result = await controller.getNotifications(authenticatedRequest, '1', '20');

    expect(result.length).toBe(1);
    expect(service.getForUser).toHaveBeenCalledWith('user-1', 1, 20);
  });

  it('gets unread count for JWT user', async () => {
    service.getUnreadCount.mockResolvedValue({ unreadCount: 3 });

    const result = await controller.getUnreadCount(authenticatedRequest);

    expect(result).toEqual({ unreadCount: 3 });
    expect(service.getUnreadCount).toHaveBeenCalledWith('user-1');
  });

  it('marks single notification as read', async () => {
    service.markAsRead.mockResolvedValue({ isRead: true });

    const result = await controller.markAsRead(authenticatedRequest, 'notif-1');

    expect(result).toEqual({ isRead: true });
    expect(service.markAsRead).toHaveBeenCalledWith('user-1', 'notif-1');
  });

  it('marks all notifications as read', async () => {
    service.markAllAsRead.mockResolvedValue({ updatedCount: 4 });

    const result = await controller.markAllAsRead(authenticatedRequest);

    expect(result).toEqual({ updatedCount: 4 });
    expect(service.markAllAsRead).toHaveBeenCalledWith('user-1');
  });
});
