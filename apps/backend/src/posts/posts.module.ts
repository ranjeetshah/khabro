import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { PostsController } from './posts.controller';
import { PostsService } from './posts.service';
import { LikesService } from './likes.service';
import { VerificationHistoryService } from './verification.history.service';
import { VerificationService } from './verification.service';
import { WitnessService } from './witness.service';

@Module({
  imports: [AuthModule],
  controllers: [PostsController],
  providers: [
    PostsService,
    LikesService,
    VerificationService,
    WitnessService,
    VerificationHistoryService,
  ],
})
export class PostsModule {}
