#include "expanded.t"
drivingHero: RpgExpandedProfile rules = expandedRules dx = 12 iq = 14 skills = [drivingTraining];
drivingCar: RpgExpandedDrivingSkill techLevel = 8 specialty = 'automobile';
drivingTruck: RpgExpandedDrivingSkill techLevel = 8 specialty = 'heavy-wheeled';
drivingTrack: RpgExpandedDrivingSkill techLevel = 8 specialty = 'tracked';
drivingCrane: RpgExpandedDrivingSkill techLevel = 8 specialty = 'construction-equipment';
drivingMotorcycle: RpgExpandedDrivingSkill techLevel = 8 specialty = 'motorcycle';
drivingTraining: RpgExpandedTraining skill = drivingCar points = 8;
modify ExpandedTestAction
    exec(context)
    {
        local code = expandedInput.code;
        if (code == 16500)
        {
            event('test.driving-defaults');
            foreach (local skill in [drivingCar,drivingTruck,drivingTrack,drivingCrane,drivingMotorcycle])
                eventValue(drivingHero.skillScore(skill));
            return nil;
        }
        if (code == 16501 || code == 16502)
        {
            local c = new RpgExpandedDrivingContext(); c.skill = drivingCar;
            event('test.driving-context'); eventValue(rpgLiteScore(drivingHero,c));
            c.task = 'map-reading'; eventValue(rpgLiteScore(drivingHero,c));
            c.task = 'operation'; c.unfamiliarControls = true; c.unfamiliarTypePenalty = -4;
            c.conditionsPenalty = -2; c.repairPenalty = -2; c.evidence = 'Bad weather, damaged unfamiliar vehicle';
            if (code == 16502) c.repairPenalty = -1;
            try { eventValue(rpgLiteScore(drivingHero,c)); }
            catch (RpgExpandedError error) { eventValue(error.reason); }
            eventValue(rpgRandom.draws); return nil;
        }
        return inherited(context);
    }
;
