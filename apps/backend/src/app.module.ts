import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { DatabaseModule } from './database/database.module';
import { HealthModule } from './health/health.module';
import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { LocationModule } from './location/location.module';
import { PostsModule } from './posts/posts.module';
import { FeedModule } from './feed/feed.module';
import { ComplaintsModule } from './complaints/complaints.module';
import { MailModule } from './mail/mail.module';
import { CivicComplaintModule } from './civic-complaint/civic-complaint.module';
import { NotificationsModule } from './notifications/notifications.module';
import { CommentsModule } from './comments/comments.module';
import { ModeratorModule } from './moderator/moderator.module';
import { FeedbackModule } from './feedback/feedback.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
    }),
    DatabaseModule,
    HealthModule,
    AuthModule,
    UsersModule,
    LocationModule,
    PostsModule,
    FeedModule,
    ComplaintsModule,
    MailModule,
    CivicComplaintModule,
    NotificationsModule,
    CommentsModule,
    ModeratorModule,
    FeedbackModule,
  ],
})
export class AppModule {}
