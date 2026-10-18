#include "expanded-pressure.t"
accelerationEvent: RpgExpandedAcceleration id = 'launch' profile = bleedProfile acceleration = 5000 homeGravity = 1000
    approved = true evidence = 'Author confirms sudden acceleration, home gravity and body orientation';
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 8900 || code == 8901 || code == 8903)
        {
            local value = code == 8901 ? accelerationEvent.assess() : accelerationEvent.apply();
            event('test.acceleration-result'); eventValue(value.status); eventValue(value.reason);
            if (code == 8903) throw new RpgError(); return nil;
        }
        if (code == 8902)
        {
            event('test.acceleration'); eventValue(bleedProfile.fatigue); eventValue(bleedProfile.unconscious ? 1 : 0);
            eventValue(accelerationEvent.result == nil ? 0 : accelerationEvent.result.blackoutSeconds);
            eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 8904) { rpgSpendTime(99); return nil; }
        if (code == 8905) { rpgSpendTime(1); return nil; }
        if (code == 8906)
        { local value = accelerationEvent.recover(); event('test.acceleration-recovery'); eventValue(value.status); eventValue(value.reason); return nil; }
        if (code == 8907) { bleedInput.forcedRoll = 18; bleedProfile.fpAdjustment = 100; return nil; }
        if (code == 8908)
        {
            event('test.acceleration-table');
            foreach (local row in [[2499,1000,'upright'],[2500,1000,'upright'],[5000,1000,'upright'],[10000,1000,'upright'],
                [5000,1000,'seated'],[5000,1000,'inverted'],[249,0,'upright'],[250,0,'upright']])
            {
                local value = rpgExpandedAssessAcceleration(row[1],row[2],row[3]);
                eventValue(value.checkRequired ? 1 : 0); eventValue(value.modifier);
            }
            eventValue(rpgRandom.draws); return nil;
        }
        if (code == 8909) { accelerationEvent.acceleration = 2499; return nil; }
        if (code == 8910)
        {
            event('test.acceleration-boundary');
            try { rpgSpendTime(101); eventValue('accepted'); }
            catch (RpgExpandedError error) { eventValue(error.reason); }
            eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        return inherited(context);
    }
;
