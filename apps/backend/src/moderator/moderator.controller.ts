import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Query,
  Req,
  UseGuards,
} from '@nestjs/common';
import type { Request } from 'express';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { ModeratorGuard } from '../auth/guards/moderator.guard';
import { ModeratorService } from './moderator.service';
import { ReportsQueryDto } from './dto/reports-query.dto';
import { UpdateReportStatusDto } from './dto/update-report-status.dto';
import { CivicComplaintsQueryDto } from './dto/civic-complaints-query.dto';

type AuthenticatedRequest = Request & {
  user: {
    sub: string;
    role?: string;
  };
};

@Controller('moderator')
@UseGuards(JwtAuthGuard, ModeratorGuard)
export class ModeratorController {
  constructor(private readonly moderatorService: ModeratorService) {}

  private userSub(request: Request): string {
    return (request as AuthenticatedRequest).user.sub;
  }

  @Get('dashboard')
  async getDashboard() {
    return this.moderatorService.getDashboardCounts();
  }

  @Get('reports')
  async getReports(@Query() query: ReportsQueryDto) {
    return this.moderatorService.getReports(query);
  }

  @Get('reports/:id')
  async getReportDetail(@Param('id') id: string) {
    return this.moderatorService.getReportDetail(id);
  }

  @Patch('reports/:id/status')
  async updateReportStatus(
    @Req() request: Request,
    @Param('id') id: string,
    @Body() dto: UpdateReportStatusDto,
  ) {
    return this.moderatorService.updateReportStatus(
      this.userSub(request),
      id,
      dto.status,
    );
  }

  @Get('civic-complaints')
  async getCivicComplaints(@Query() query: CivicComplaintsQueryDto) {
    return this.moderatorService.getCivicComplaints(query);
  }

  @Get('civic-complaints/:id')
  async getCivicComplaintDetail(@Param('id') id: string) {
    return this.moderatorService.getCivicComplaintDetail(id);
  }
}
