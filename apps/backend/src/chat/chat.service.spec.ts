import {
  BadRequestException,
  ForbiddenException,
  NotFoundException,
} from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import { DatabaseService } from '../database/database.service';
import { NotificationService } from '../notifications/notification.service';
import { ChatService } from './chat.service';
import { UserStatus } from '../generated/prisma/enums';

describe('ChatService', () => {
  let service: ChatService;
  let databaseService: any;
  let notificationService: any;

  beforeEach(async () => {
    databaseService = {
      user: {
        findUnique: jest.fn(),
      },
      conversation: {
        findUnique: jest.fn(),
        create: jest.fn(),
        findMany: jest.fn(),
        count: jest.fn(),
        update: jest.fn(),
      },
      conversationParticipant: {
        update: jest.fn(),
        findMany: jest.fn(),
      },
      message: {
        count: jest.fn(),
        create: jest.fn(),
        findMany: jest.fn(),
        findFirst: jest.fn(),
        findUnique: jest.fn(),
        update: jest.fn(),
      },
      $transaction: jest.fn((cb) => cb(databaseService)),
    };

    notificationService = {
      createNotification: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ChatService,
        { provide: DatabaseService, useValue: databaseService },
        { provide: NotificationService, useValue: notificationService },
      ],
    }).compile();

    service = module.get<ChatService>(ChatService);
  });

  describe('createConversation', () => {
    it('creates a new conversation if it does not exist', async () => {
      databaseService.user.findUnique
        .mockResolvedValueOnce({ id: 'target-1', status: UserStatus.ACTIVE })
        .mockResolvedValueOnce({ id: 'user-123', status: UserStatus.ACTIVE });

      databaseService.conversation.findUnique.mockResolvedValue(null);
      databaseService.conversation.create.mockResolvedValue({
        id: 'conv-123',
        participants: [
          { userId: 'user-123', user: { id: 'user-123', name: 'Alice' } },
          { userId: 'target-1', user: { id: 'target-1', name: 'Bob' } },
        ],
      });

      const result = await service.createConversation('user-123', 'target-1');

      expect(result.id).toBe('conv-123');
      expect(result.participant.id).toBe('target-1');
      expect(result.participant.name).toBe('Bob');
    });

    it('rejects self-chat', async () => {
      await expect(
        service.createConversation('user-123', 'user-123'),
      ).rejects.toThrow(BadRequestException);
    });

    it('rejects chat with deleted target user', async () => {
      databaseService.user.findUnique.mockResolvedValue({
        id: 'target-1',
        status: UserStatus.DELETED,
      });

      await expect(
        service.createConversation('user-123', 'target-1'),
      ).rejects.toThrow(NotFoundException);
    });
  });

  describe('sendMessage', () => {
    it('creates message, touches conversation activity, and triggers notification on first unread message', async () => {
      databaseService.user.findUnique.mockResolvedValue({
        id: 'user-123',
        name: 'Alice',
      });
      databaseService.conversation.findUnique.mockResolvedValue({
        id: 'conv-123',
        participants: [
          { userId: 'user-123', lastReadAt: new Date(0), user: { status: UserStatus.ACTIVE } },
          { userId: 'target-1', lastReadAt: new Date(0), user: { status: UserStatus.ACTIVE } },
        ],
      });

      databaseService.message.create.mockResolvedValue({
        id: 'msg-1',
        conversationId: 'conv-123',
        senderId: 'user-123',
        content: 'Hello Bob',
        createdAt: new Date(),
      });

      databaseService.message.count.mockResolvedValue(1); // First unread message

      const result = await service.sendMessage('user-123', 'conv-123', 'Hello Bob');

      expect(result.id).toBe('msg-1');
      expect(result.content).toBe('Hello Bob');
      expect(notificationService.createNotification).toHaveBeenCalled();
    });

    it('rejects message exceeding 2000 characters', async () => {
      const longMessage = 'a'.repeat(2001);
      await expect(
        service.sendMessage('user-123', 'conv-123', longMessage),
      ).rejects.toThrow(BadRequestException);
    });
  });

  describe('deleteMessage', () => {
    it('soft deletes own message successfully', async () => {
      databaseService.message.findUnique.mockResolvedValue({
        id: 'msg-1',
        senderId: 'user-123',
        conversationId: 'conv-123',
        conversation: {
          participants: [{ userId: 'user-123' }, { userId: 'target-1' }],
        },
      });

      const result = await service.deleteMessage('user-123', 'conv-123', 'msg-1');

      expect(result.success).toBe(true);
      expect(databaseService.message.update).toHaveBeenCalledWith({
        where: { id: 'msg-1' },
        data: expect.objectContaining({ deletedAt: expect.any(Date) }),
      });
    });

    it('denies deleting another users message', async () => {
      databaseService.message.findUnique.mockResolvedValue({
        id: 'msg-1',
        senderId: 'target-1',
        conversationId: 'conv-123',
        conversation: {
          participants: [{ userId: 'user-123' }, { userId: 'target-1' }],
        },
      });

      await expect(
        service.deleteMessage('user-123', 'conv-123', 'msg-1'),
      ).rejects.toThrow(ForbiddenException);
    });
  });
});
