import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Post,
  Req,
  UseGuards,
} from '@nestjs/common';
import type { Request } from 'express';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CivicComplaintService } from './civic-complaint.service';
import { ReopenComplaintDto } from './dto/reopen-complaint.dto';
import { UpdateComplaintStatusDto } from './dto/update-complaint-status.dto';

type AuthenticatedRequest = Request & {
  user: {
    sub: string;
    role?: string;
  };
};

@Controller('civic-complaints')
@UseGuards(JwtAuthGuard)
export class CivicComplaintController {
  constructor(private readonly civicComplaintService: CivicComplaintService) {}

  private userSub(request: Request): string {
    return (request as AuthenticatedRequest).user.sub;
  }

  private userRole(request: Request): string | undefined {
    return (request as AuthenticatedRequest).user.role;
  }

  @Get(':id')
  async getComplaint(@Param('id') id: string) {
    return this.civicComplaintService.getPublicComplaintById(id);
  }

  @Get(':id/history')
  async getHistory(@Param('id') id: string) {
    return this.civicComplaintService.getStatusHistory(id);
  }

  @Patch(':id/status')
  async updateStatus(
    @Req() request: Request,
    @Param('id') id: string,
    @Body() dto: UpdateComplaintStatusDto,
  ) {
    return this.civicComplaintService.updateStatusByAuthority(
      this.userSub(request),
      this.userRole(request),
      id,
      dto.status,
      dto.note,
    );
  }

  @Post(':id/confirm')
  async confirmResolution(
    @Req() request: Request,
    @Param('id') id: string,
  ) {
    return this.civicComplaintService.confirmResolutionByCitizen(
      this.userSub(request),
      id,
    );
  }

  @Post(':id/reopen')
  async reopenComplaint(
    @Req() request: Request,
    @Param('id') id: string,
    @Body() dto: ReopenComplaintDto,
  ) {
    return this.civicComplaintService.reopenComplaintByCitizen(
      this.userSub(request),
      id,
      dto.reason,
    );
  }
}
