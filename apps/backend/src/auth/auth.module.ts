import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { ConfigModule, ConfigService } from '@nestjs/config';
import type { SignOptions } from 'jsonwebtoken';

import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';

@Module({
  imports: [
    ConfigModule,

    JwtModule.registerAsync({
      imports: [ConfigModule],
      inject: [ConfigService],

      useFactory: (configService: ConfigService) => ({
        secret: configService.getOrThrow<string>('JWT_SECRET'),

        signOptions: {
          expiresIn: configService.get<string>(
            'JWT_EXPIRES_IN',
            '15m',
          ) as SignOptions['expiresIn'],
        },
      }),
    }),
  ],

  controllers: [AuthController],

  providers: [AuthService],

  exports: [
    AuthService,
    JwtModule,
  ],
})
export class AuthModule {}