#include "expanded-driving.t"
drivingVehicleType: object;
drivingControls: RpgExpandedDrivingFamiliarity owner = drivingHero skill = drivingCar equipmentType = drivingVehicleType
    kind = 'controls' penalty = -2 available = true evidence = 'Unfamiliar control system';
drivingType: RpgExpandedDrivingFamiliarity owner = drivingHero skill = drivingCar equipmentType = drivingVehicleType
    kind = 'vehicle-type' penalty = -4 available = true evidence = 'Unfamiliar race vehicle';
modify drivingHero familiarities = [drivingControls,drivingType];
drivingFamiliarContext: RpgExpandedDrivingContext skill = drivingCar controlsFamiliarity = drivingControls typeFamiliarity = drivingType;
modify ExpandedTestAction
    exec(context)
    {
        local code = expandedInput.code;
        if (code == 16700 || code == 16701)
        {
            rpgExpandedPracticeDriving(drivingHero,drivingCar,[drivingControls,drivingType],28800);
            if (code == 16701) throw new RpgError(); return nil;
        }
        if (code == 16702)
        {
            event('test.driving-familiarity'); eventValue(rpgLiteScore(drivingHero,drivingFamiliarContext));
            eventValue(drivingControls.practicedSeconds); eventValue(drivingType.practicedSeconds);
            eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 16703)
        {
            drivingFamiliarContext.unfamiliarControls = true;
            try { rpgLiteScore(drivingHero,drivingFamiliarContext); }
            catch (RpgExpandedError error) { event('test.driving-familiarity-reject'); eventValue(error.reason); }
            return nil;
        }
        return inherited(context);
    }
;
