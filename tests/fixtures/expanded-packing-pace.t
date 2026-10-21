#include "expanded-packing-skill.t"
packRoute: RpgExpandedHikingConditions packTrain = packingCaravan;
packPace: object move = 5 enhancement = 100 success = nil;
packWalkSkill: RpgLiteSkill id = 'hiking' attribute = rpgHT difficulty = 1 defaultPenalty = -5;
packWalkTraining: RpgTraining skill = packWalkSkill points = 4;
packWalk: RpgExpandedHikingAttempt id = 'caravan-day' members = [[crossPhysician,packWalkSkill,0,nil]]
    approved = true evidence = 'Ordinary route shared by the caravan';
modify PhysicianFixtureAction
    exec(context)
    {
        local code = healthInput.code;
        if (code == 23400)
        { local value = rpgExpandedAssessHiking(packPace.move,packPace.enhancement,packPace.success,packRoute);
          event('test.pack-pace'); eventValue(value.status); eventValue(value.reason); eventValue(value.packingPercent);
          eventValue(value.milesHundredths); eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil; }
        if (code == 23401) { packRoute.packTrain = nil; return nil; }
        if (code == 23402) { packPace.success = true; return nil; }
        if (code == 23403)
        { packPace.move = 1; packPace.enhancement = 101; packRoute.terrain = 'very-bad'; packRoute.weather = 'deep-snow';
          packRoute.deepSnowDivisor = 7; packRoute.deepSnowEvidence = 'Exceptionally deep snow'; return nil; }
        if (code == 23404) { packingCaravan.approved = nil; return nil; }
        if (code == 23405) { crossPhysician.skills = [packWalkTraining]; packWalk.resolve(); return nil; }
        if (code == 23406)
        { local value = packWalk.assessPace(packRoute,[100]); event('test.pack-daily'); eventValue(value.packingPercent);
          eventValue(value.milesHundredths); eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil; }
        return inherited(context);
    }
;
