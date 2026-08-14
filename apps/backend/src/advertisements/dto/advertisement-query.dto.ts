import { Transform } from 'class-transformer';
import { IsEnum, IsInt, IsOptional, Max, Min } from 'class-validator';
import {
  AdvertisementPlacement,
  AdvertisementStatus,
} from '../../generated/prisma/enums';

export class AdvertisementQueryDto {
  @IsOptional()
  @Transform(({ value }) => Number(value))
  @IsInt()
  @Min(1)
  page: number = 1;

  @IsOptional()
  @Transform(({ value }) => Number(value))
  @IsInt()
  @Min(1)
  @Max(50)
  limit: number = 20;

  @IsOptional()
  @IsEnum(AdvertisementStatus)
  status?: AdvertisementStatus;

  @IsOptional()
  @IsEnum(AdvertisementPlacement)
  placement?: AdvertisementPlacement;
}

export class PublicAdvertisementQueryDto {
  @IsOptional()
  @Transform(({ value }) => Number(value))
  @IsInt()
  @Min(1)
  page: number = 1;

  @IsOptional()
  @Transform(({ value }) => Number(value))
  @IsInt()
  @Min(1)
  @Max(20)
  limit: number = 5;

  @IsOptional()
  @IsEnum(AdvertisementPlacement)
  placement?: AdvertisementPlacement;
}
