import {
  CanActivate,
  ExecutionContext,
  Injectable,
  ForbiddenException,
} from '@nestjs/common';
import { DatabaseService } from '../../database/database.service';
import { UserRole } from '../../generated/prisma/enums';

@Injectable()
export class ModeratorGuard implements CanActivate {
  constructor(private readonly database: DatabaseService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();
    const userPayload = request.user;
    if (!userPayload || !userPayload.sub) {
      throw new ForbiddenException('Access denied');
    }

    const dbUser = await this.database.user.findUnique({
      where: { id: userPayload.sub },
      select: { role: true },
    });

    if (!dbUser || dbUser.role !== UserRole.MODERATOR) {
      throw new ForbiddenException('Access denied');
    }

    return true;
  }
}
