import {
  CanActivate,
  ExecutionContext,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';

@Injectable()
export class JwtAuthGuard implements CanActivate {
  constructor(
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();

    const authHeader = request.headers.authorization;

    if (!authHeader) {
      throw new UnauthorizedException('Authorization header missing');
    }

    const parts = authHeader.split(' ');

    if (parts.length !== 2 || parts[0] !== 'Bearer' || !parts[1]) {
      throw new UnauthorizedException('Invalid authorization format');
    }

    try {
      const payload = await this.jwtService.verifyAsync(parts[1], {
        secret: this.configService.getOrThrow<string>('JWT_SECRET'),
      });

      request.user = payload;

      return true;
    } catch {
      throw new UnauthorizedException('Invalid or expired token');
    }
  }
}