import { IsBoolean, IsOptional, IsString, MaxLength, MinLength } from 'class-validator';

export class UpdateMeDto {
  @IsOptional()
  @IsString()
  @MinLength(1, { message: 'name must not be empty' })
  @MaxLength(100)
  name?: string;

  @IsOptional()
  @IsBoolean()
  allowCivicComplaintContactSharing?: boolean;
}
