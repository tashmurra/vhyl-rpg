#include "expanded-swim-submersion.t"
modify swimPatient maxHP = 1000;
drowningAidSkill: RpgLiteSkill id = 'first-aid' attribute = rpgIQ difficulty = 0 techLevel = 7;
drowningAidTraining: RpgTraining skill = drowningAidSkill points = 1;
drowningHealer: RpgExpandedProfile rules = swimRules iq = 14 techLevel = 7 skills = [drowningAidTraining];
drowningCare: RpgExpandedDrowningResuscitation id = 'rescue-breathing' exposure = swimSubmersion healer = drowningHealer
    skill = drowningAidSkill modernTechnique = true approved = true evidence = 'Rescuer has retrieved and can treat the patient';
modify SwimFixtureAction
    exec(context)
    {
        local code = swimInput.code;
        if (code == 17400) { drowningCare.start(); return nil; }
        if (code == 17401)
        {
            foreach (local id in ['air-1','air-2','air-3','air-4','air-5','air-6','air-7','air-8','air-9','air-10','air-11','air-12','air-13','air-14','air-15','air-16','air-17','air-18','air-19','air-20','air-21','air-22','air-23','air-24','air-25','air-26','air-27','air-28','air-29','air-30','air-31','air-32','air-33','air-34','air-35','air-36','air-37','air-38','air-39','air-40','air-41','air-42','air-43','air-44','air-45','air-46','air-47','air-48','air-49','air-50','air-51','air-52','air-53','air-54','air-55','air-56','air-57','air-58','air-59','air-60'])
            {
                rpgSpendTime(1); local second = new RpgExpandedAirlessSecond();
                second.id = id; second.exposure = swimSubmersion; second.apply();
            }
            return nil;
        }
        if (code == 17402 || code == 17403)
        {
            rpgRandom.exhaustionRoll = 3; local value = drowningCare.finish();
            event('test.drowning-care-result'); eventValue(value.status); eventValue(value.reason);
            if (code == 17403) throw new RpgError(); return nil;
        }
        if (code == 17404)
        {
            event('test.drowning-care'); eventValue(swimPatient.airlessExposure == nil); eventValue(swimPatient.airClock);
            eventValue(swimPatient.fp()); eventValue(swimPatient.injury); eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        return inherited(context);
    }
;
