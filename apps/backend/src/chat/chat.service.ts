import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  BadRequestException,
} from '@nestjs/common';
import { DatabaseService } from '../database/database.service';
import { NotificationService } from '../notifications/notification.service';
import { UserStatus, NotificationType } from '../generated/prisma/enums';

@Injectable()
export class ChatService {
  constructor(
    private readonly database: DatabaseService,
    private readonly notificationService: NotificationService,
  ) {}

  async createConversation(currentUserId: string, targetUserId: string) {
    if (currentUserId === targetUserId) {
      throw new BadRequestException('Self-chat is not allowed');
    }

    const targetUser = await this.database.user.findUnique({
      where: { id: targetUserId },
    });

    if (!targetUser || targetUser.status === UserStatus.DELETED) {
      throw new NotFoundException('Target user not found or deleted');
    }

    const currentUser = await this.database.user.findUnique({
      where: { id: currentUserId },
    });
    if (!currentUser || currentUser.status === UserStatus.DELETED) {
      throw new ForbiddenException('User account is invalid or deleted');
    }

    const participantKey = [currentUserId, targetUserId].sort().join(':');

    // Atomically find or create the conversation to handle concurrency
    const conversation = await this.database.$transaction(async (tx) => {
      const existing = await tx.conversation.findUnique({
        where: { participantKey },
        include: {
          participants: {
            include: {
              user: {
                select: {
                  id: true,
                  name: true,
                  status: true,
                },
              },
            },
          },
        },
      });

      if (existing) {
        return existing;
      }

      return tx.conversation.create({
        data: {
          participantKey,
          participants: {
            create: [
              { userId: currentUserId },
              { userId: targetUserId },
            ],
          },
        },
        include: {
          participants: {
            include: {
              user: {
                select: {
                  id: true,
                  name: true,
                  status: true,
                },
              },
            },
          },
        },
      });
    });

    const otherParticipant = conversation.participants.find(
      (p) => p.userId === targetUserId,
    );

    return {
      id: conversation.id,
      participant: {
        id: otherParticipant?.user.id ?? targetUserId,
        name: otherParticipant?.user.name ?? 'Anonymous',
      },
    };
  }

  async listConversations(currentUserId: string, page = 1, limit = 20) {
    const take = Math.min(Math.max(limit, 1), 50);
    const skip = (Math.max(page, 1) - 1) * take;

    const [conversations, total] = await Promise.all([
      this.database.conversation.findMany({
        where: {
          participants: {
            some: { userId: currentUserId },
          },
        },
        orderBy: [
          { updatedAt: 'desc' },
          { id: 'desc' },
        ],
        skip,
        take,
        include: {
          participants: {
            include: {
              user: {
                select: {
                  id: true,
                  name: true,
                },
              },
            },
          },
          messages: {
            orderBy: [
              { createdAt: 'desc' },
              { id: 'desc' },
            ],
            take: 1,
          },
        },
      }),
      this.database.conversation.count({
        where: {
          participants: {
            some: { userId: currentUserId },
          },
        },
      }),
    ]);

    const items = await Promise.all(
      conversations.map(async (conv) => {
        const myParticipant = conv.participants.find(
          (p) => p.userId === currentUserId,
        );
        const otherParticipant = conv.participants.find(
          (p) => p.userId !== currentUserId,
        );

        const unreadCount = await this.database.message.count({
          where: {
            conversationId: conv.id,
            senderId: { not: currentUserId },
            createdAt: { gt: myParticipant?.lastReadAt ?? new Date(0) },
            deletedAt: null,
          },
        });

        const lastMsg = conv.messages[0];

        return {
          id: conv.id,
          participant: {
            id: otherParticipant?.user.id ?? '',
            name: otherParticipant?.user.name ?? 'Anonymous',
          },
          lastMessage: lastMsg
            ? {
                id: lastMsg.id,
                content: lastMsg.deletedAt ? 'Message deleted' : lastMsg.content,
                createdAt: lastMsg.createdAt,
                senderId: lastMsg.senderId,
              }
            : null,
          unreadCount,
          updatedAt: conv.updatedAt,
        };
      }),
    );

    return {
      items,
      page,
      limit: take,
      total,
      hasMore: skip + items.length < total,
    };
  }

  async getConversationDetail(currentUserId: string, conversationId: string) {
    const conversation = await this.database.conversation.findUnique({
      where: { id: conversationId },
      include: {
        participants: {
          include: {
            user: {
              select: {
                id: true,
                name: true,
                status: true,
              },
            },
          },
        },
      },
    });

    if (!conversation) {
      throw new NotFoundException('Conversation not found');
    }

    const isMember = conversation.participants.some(
      (p) => p.userId === currentUserId,
    );

    if (!isMember) {
      throw new NotFoundException('Conversation not found');
    }

    const otherParticipant = conversation.participants.find(
      (p) => p.userId !== currentUserId,
    );

    return {
      id: conversation.id,
      participant: {
        id: otherParticipant?.user.id ?? '',
        name: otherParticipant?.user.name ?? 'Anonymous',
      },
    };
  }

  async sendMessage(
    currentUserId: string,
    conversationId: string,
    content: string,
    clientMessageId?: string,
  ) {
    const trimmedContent = content?.trim();
    if (!trimmedContent) {
      throw new BadRequestException('Message content cannot be empty');
    }

    if (trimmedContent.length > 2000) {
      throw new BadRequestException('Message content exceeds 2000 characters');
    }

    const conversation = await this.database.conversation.findUnique({
      where: { id: conversationId },
      include: {
        participants: {
          include: {
            user: {
              select: {
                id: true,
                name: true,
                status: true,
              },
            },
          },
        },
      },
    });

    if (!conversation) {
      throw new NotFoundException('Conversation not found');
    }

    const myParticipant = conversation.participants.find(
      (p) => p.userId === currentUserId,
    );
    const otherParticipant = conversation.participants.find(
      (p) => p.userId !== currentUserId,
    );

    if (!myParticipant || !otherParticipant) {
      throw new NotFoundException('Conversation not found');
    }

    if (otherParticipant.user.status === UserStatus.DELETED) {
      throw new BadRequestException('Recipient account is deleted');
    }

    // Check message idempotency if clientMessageId is provided
    if (clientMessageId) {
      const existing = await this.database.message.findFirst({
        where: {
          conversationId,
          senderId: currentUserId,
          clientMessageId,
        },
      });

      if (existing) {
        return {
          id: existing.id,
          conversationId: existing.conversationId,
          senderId: existing.senderId,
          content: existing.deletedAt ? 'Message deleted' : existing.content,
          createdAt: existing.createdAt,
        };
      }
    }

    const sender = await this.database.user.findUnique({
      where: { id: currentUserId },
    });

    const message = await this.database.$transaction(async (tx) => {
      // 1. Create the message record
      const msg = await tx.message.create({
        data: {
          conversationId,
          senderId: currentUserId,
          content: trimmedContent,
          clientMessageId,
        },
      });

      // 2. Touch/update conversation activity timestamp
      await tx.conversation.update({
        where: { id: conversationId },
        data: { updatedAt: new Date() },
      });

      // 3. Count unread messages for the recipient *before* their lastReadAt.
      // If this is the first unread message, send the notification to prevent spamming.
      const unreadCount = await tx.message.count({
        where: {
          conversationId,
          senderId: currentUserId,
          createdAt: { gt: otherParticipant.lastReadAt },
          deletedAt: null,
        },
      });

      if (unreadCount === 1) {
        await this.notificationService.createNotification(
          tx,
          otherParticipant.userId,
          NotificationType.MESSAGE_RECEIVED,
          'New message',
          `${sender?.name || 'Someone'} sent you a message.`,
          'CONVERSATION',
          conversationId,
        );
      }

      return msg;
    });

    return {
      id: message.id,
      conversationId: message.conversationId,
      senderId: message.senderId,
      content: message.content,
      createdAt: message.createdAt,
    };
  }

  async listMessages(
    currentUserId: string,
    conversationId: string,
    page = 1,
    limit = 20,
  ) {
    const conversation = await this.database.conversation.findUnique({
      where: { id: conversationId },
      include: {
        participants: true,
      },
    });

    if (!conversation) {
      throw new NotFoundException('Conversation not found');
    }

    const isMember = conversation.participants.some(
      (p) => p.userId === currentUserId,
    );

    if (!isMember) {
      throw new NotFoundException('Conversation not found');
    }

    const take = Math.min(Math.max(limit, 1), 50);
    const skip = (Math.max(page, 1) - 1) * take;

    const [messages, total] = await Promise.all([
      this.database.message.findMany({
        where: { conversationId },
        orderBy: [
          { createdAt: 'desc' },
          { id: 'desc' },
        ],
        skip,
        take,
      }),
      this.database.message.count({
        where: { conversationId },
      }),
    ]);

    const items = messages.map((m) => ({
      id: m.id,
      senderId: m.senderId,
      content: m.deletedAt ? null : m.content,
      createdAt: m.createdAt,
      deleted: m.deletedAt !== null,
    }));

    return {
      items,
      page,
      limit: take,
      total,
      hasMore: skip + items.length < total,
    };
  }

  async markAsRead(currentUserId: string, conversationId: string) {
    const conversation = await this.database.conversation.findUnique({
      where: { id: conversationId },
      include: {
        participants: true,
      },
    });

    if (!conversation) {
      throw new NotFoundException('Conversation not found');
    }

    const participant = conversation.participants.find(
      (p) => p.userId === currentUserId,
    );

    if (!participant) {
      throw new NotFoundException('Conversation not found');
    }

    await this.database.conversationParticipant.update({
      where: { id: participant.id },
      data: { lastReadAt: new Date() },
    });

    return { read: true };
  }

  async getGlobalUnreadCount(currentUserId: string) {
    const participants = await this.database.conversationParticipant.findMany({
      where: { userId: currentUserId },
    });

    let totalUnread = 0;

    for (const part of participants) {
      const count = await this.database.message.count({
        where: {
          conversationId: part.conversationId,
          senderId: { not: currentUserId },
          createdAt: { gt: part.lastReadAt },
          deletedAt: null,
        },
      });
      totalUnread += count;
    }

    return { unreadCount: totalUnread };
  }

  async deleteMessage(
    currentUserId: string,
    conversationId: string,
    messageId: string,
  ) {
    const message = await this.database.message.findUnique({
      where: { id: messageId },
      include: {
        conversation: {
          include: {
            participants: true,
          },
        },
      },
    });

    if (!message || message.conversationId !== conversationId) {
      throw new NotFoundException('Message not found');
    }

    const isMember = message.conversation.participants.some(
      (p) => p.userId === currentUserId,
    );

    if (!isMember) {
      throw new NotFoundException('Message not found');
    }

    if (message.senderId !== currentUserId) {
      throw new ForbiddenException('Cannot delete another user\'s message');
    }

    await this.database.message.update({
      where: { id: messageId },
      data: { deletedAt: new Date() },
    });

    return { success: true };
  }
}
