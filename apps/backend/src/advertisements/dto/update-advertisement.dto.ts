import {
  IsISO8601,
  IsOptional,
  IsString,
  Length,
  MaxLength,
} from 'class-validator';
import { IsSafeUrl } from '../safe-url';

export class UpdateAdvertisementDto {
  @IsOptional()
  @IsString()
  @Length(3, 120)
  title?: string;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  description?: string;

  @IsOptional()
  @IsString()
  @Length(2, 80)
  advertiserName?: string;

  @IsOptional()
  @IsString()
  @IsSafeUrl()
  creativeUrl?: string;

  @IsOptional()
  @IsString()
  @IsSafeUrl()
  destinationUrl?: string;

  @IsOptional()
  @IsString()
  @Length(1, 40)
  ctaLabel?: string;

  @IsOptional()
  @IsISO8601()
  startAt?: string;

  @IsOptional()
  @IsISO8601()
  endAt?: string;
}
