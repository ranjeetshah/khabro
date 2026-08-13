import { IsNotEmpty, IsString, MaxLength } from 'class-validator';

export class ReopenComplaintDto {
  @IsString()
  @IsNotEmpty({ message: 'Reason for reopening is required' })
  @MaxLength(1000)
  reason: string;
}
