import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { PostsController } from './posts.controller';
import { PostsService } from './posts.service';
import { LikesService } from './likes.service';
import { WitnessService } from './witness.service';

@Module({
  imports: [AuthModule],
  controllers: [PostsController],
  providers: [
    PostsService,
    LikesService,
    WitnessService,
  ],
})
export class PostsModule {}