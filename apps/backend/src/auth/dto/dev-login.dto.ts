import { IsString, Matches } from 'class-validator';

export class DevLoginDto {
  @IsString()
  @Matches(/^\+?[1-9]\d{6,14}$/, {
    message: 'phone must be a valid phone number (e.g. +919876543210)',
  })
  phone: string;
}
