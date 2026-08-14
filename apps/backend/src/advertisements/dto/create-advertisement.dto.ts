import {
  IsEnum,
  IsISO8601,
  IsOptional,
  IsString,
  Length,
  MaxLength,
} from 'class-validator';
import { AdvertisementPlacement } from '../../generated/prisma/enums';
import { IsSafeUrl } from '../safe-url';

export class CreateAdvertisementDto {
  @IsString()
  @Length(3, 120)
  title!: string;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  description?: string;

  @IsString()
  @Length(2, 80)
  advertiserName!: string;

  @IsString()
  @IsSafeUrl()
  creativeUrl!: string;

  @IsString()
  @IsSafeUrl()
  destinationUrl!: string;

  @IsOptional()
  @IsString()
  @Length(1, 40)
  ctaLabel?: string;

  @IsEnum(AdvertisementPlacement)
  placement!: AdvertisementPlacement;

  @IsOptional()
  @IsISO8601()
  startAt?: string;

  @IsOptional()
  @IsISO8601()
  endAt?: string;
}
