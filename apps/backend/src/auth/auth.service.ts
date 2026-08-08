import {
  ConflictException,
  Injectable,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { DatabaseService } from '../database/database.service';

/** Fields safe to expose in API responses — never includes internal/sensitive data. */
const USER_SAFE_SELECT = {
  id: true,
  phone: true,
  name: true,
  trustScore: true,
  status: true,
} as const;

@Injectable()
export class AuthService {
  constructor(
    private readonly database: DatabaseService,
    private readonly jwtService: JwtService,
  ) {}

  async findUserByPhone(phone: string) {
    return this.database.user.findUnique({
      where: { phone },
      select: USER_SAFE_SELECT,
    });
  }

  async findUserById(id: string) {
    return this.database.user.findUnique({
      where: { id },
      select: USER_SAFE_SELECT,
    });
  }

  async createUser(phone: string, name?: string) {
    try {
      return await this.database.user.create({
        data: { phone, name },
        select: USER_SAFE_SELECT,
      });
    } catch (error: any) {
      // Prisma unique constraint violation
      if (error?.code === 'P2002') {
        throw new ConflictException('A user with this phone already exists');
      }
      throw error;
    }
  }

  async generateAccessToken(userId: string) {
    const user = await this.database.user.findUnique({
      where: { id: userId },
      select: { ...USER_SAFE_SELECT, status: true },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    if (user.status !== 'ACTIVE') {
      throw new UnauthorizedException('User account is not active');
    }

    const payload = { sub: user.id };

    return {
      accessToken: await this.jwtService.signAsync(payload),
      user: {
        id: user.id,
        phone: user.phone,
        name: user.name,
        trustScore: user.trustScore,
        status: user.status,
      },
    };
  }
}