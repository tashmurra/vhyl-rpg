#include "expanded-drowning-care.t"
drowningRetry: RpgExpandedDrowningResuscitation id = 'second-rescue' exposure = swimSubmersion healer = drowningHealer
    skill = drowningAidSkill modernTechnique = true approved = true evidence = 'Rescuer resumes access';
modify SwimFixtureAction
    exec(context)
    {
        local code = swimInput.code;
        if (code == 17500 || code == 17501)
        {
            local value = drowningCare.cancel('Rescuer interrupted');
            event('test.care-cancel'); eventValue(value.status); eventValue(value.reason);
            if (code == 17501) throw new RpgError(); return nil;
        }
        if (code == 17502) { drowningRetry.start(); return nil; }
        if (code == 17503)
        {
            event('test.care-interruption'); eventValue(drowningCare.cancelledAt != nil);
            eventValue(drowningRetry.startedAt != nil); eventValue(swimSubmersion.resuscitations.length());
            eventValue(swimPatient.airClock); eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 17504) { rpgSpendTime(1); return nil; }
        return inherited(context);
    }
;
