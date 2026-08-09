import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { LocationController } from './location.controller';
import { LocationService } from './location.service';
import { DevelopmentLocalityResolver } from './locality/development-locality.resolver';
import { LOCALITY_RESOLVER } from './locality/locality-resolver';

@Module({
  imports: [AuthModule],
  controllers: [LocationController],
  providers: [
    DevelopmentLocalityResolver,
    {
      provide: LOCALITY_RESOLVER,
      useExisting: DevelopmentLocalityResolver,
    },
    LocationService,
  ],
  exports: [LocationService],
})
export class LocationModule {}
