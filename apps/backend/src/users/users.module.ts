import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { ModerationModule } from '../moderation/moderation.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { UsersController } from './users.controller';
import { UsersService } from './users.service';
import { FollowService } from './follow.service';
import { SuggestionService } from './suggestion.service';

@Module({
  imports: [AuthModule, ModerationModule, NotificationsModule],
  controllers: [UsersController],
  providers: [UsersService, FollowService, SuggestionService],
  exports: [UsersService, FollowService, SuggestionService],
})
export class UsersModule {}
