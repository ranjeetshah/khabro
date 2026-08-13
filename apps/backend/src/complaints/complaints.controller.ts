import {
  Controller,
  Get,
  Param,
  Query,
  Req,
  UseGuards,
} from '@nestjs/common';
import type { Request } from 'express';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { ComplaintListQueryDto } from './dto/complaint.dto';
import { ComplaintService } from './complaints.service';

type AuthenticatedRequest = Request & { user: { sub: string } };

@Controller('complaints')
@UseGuards(JwtAuthGuard)
export class ComplaintsController {
  constructor(private readonly complaintsService: ComplaintService) {}

  private userId(request: Request): string {
    return (request as AuthenticatedRequest).user.sub;
  }

  @Get('me')
  async mine(@Req() request: Request, @Query() query: ComplaintListQueryDto) {
    return this.complaintsService.findMine(
      this.userId(request),
      query.limit ?? ComplaintService.DEFAULT_PAGE_SIZE,
      query.cursor,
    );
  }

  @Get(':id')
  async findOne(@Req() request: Request, @Param('id') id: string) {
    return this.complaintsService.findOne(id, this.userId(request));
  }
}
