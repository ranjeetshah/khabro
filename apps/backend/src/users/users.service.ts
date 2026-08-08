import { Injectable } from '@nestjs/common';
import { DatabaseService } from '../database/database.service';

/** Profile fields safe to expose in API responses. */
const USER_PROFILE_SELECT = {
  id: true,
  phone: true,
  name: true,
  trustScore: true,
  status: true,
  createdAt: true,
  updatedAt: true,
} as const;

@Injectable()
export class UsersService {
  constructor(private readonly database: DatabaseService) {}

  /**
   * Fetch the authenticated user's profile by ID.
   * Returns null if the user does not exist.
   */
  async findMe(userId: string) {
    return this.database.user.findUnique({
      where: { id: userId },
      select: USER_PROFILE_SELECT,
    });
  }

  /**
   * Update the authenticated user's profile.
   * Only accepts explicitly allowed fields.
   */
  async updateMe(userId: string, data: { name?: string }) {
    // Verify user exists first
    const existing = await this.database.user.findUnique({
      where: { id: userId },
      select: { id: true },
    });

    if (!existing) {
      return null;
    }

    return this.database.user.update({
      where: { id: userId },
      data: {
        ...(data.name !== undefined && { name: data.name }),
      },
      select: USER_PROFILE_SELECT,
    });
  }
}
