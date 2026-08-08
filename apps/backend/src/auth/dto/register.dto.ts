import { IsString, IsOptional, Matches, MaxLength } from 'class-validator';

export class RegisterDto {
  @IsString()
  @Matches(/^\+?[1-9]\d{6,14}$/, {
    message: 'phone must be a valid phone number (e.g. +919876543210)',
  })
  phone: string;

  @IsOptional()
  @IsString()
  @MaxLength(100)
  name?: string;
}
