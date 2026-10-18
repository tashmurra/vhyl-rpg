#include "expanded-acceleration.t"
accelerationInjury: RpgExpandedFallInjury id = 'bulkhead-impact' profile = bleedProfile fall = accelerationEvent
    damageVelocity = 250 approved = true evidence = 'The acceleration throws the subject against a rigid bulkhead';
accelerationImpact: RpgExpandedAccelerationImpact accelerationEvent = accelerationEvent injury = accelerationInjury hard = true;
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 9000) { accelerationEvent.acceleration = 250; accelerationEvent.apply(); return nil; }
        if (code == 9001 || code == 9002 || code == 9003)
        {
            local value = code == 9002 ? accelerationImpact.assess() : accelerationImpact.apply();
            event('test.acceleration-impact-result'); eventValue(value.status); eventValue(value.reason);
            if (code == 9003) throw new RpgError(); return nil;
        }
        if (code == 9004)
        {
            event('test.acceleration-impact'); eventValue(bleedProfile.injury); eventValue(bleedProfile.fatigue);
            eventValue(bleedProfile.fallImpacts.length()); eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 9005)
        {
            event('test.acceleration-impact-table');
            foreach (local speed in [125,126,250,500,750])
            {
                local value = rpgExpandedAssessScaledCollision(10,speed,100,true);
                eventValue(value.damageDice); eventValue(value.damageAdds);
            }
            local whole = rpgExpandedAssessCollision(10,50,true);
            local scaled = rpgExpandedAssessScaledCollision(10,5000,100,true);
            eventValue(whole.damageDice); eventValue(scaled.damageDice); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 9006) { accelerationInjury.damageVelocity = 251; return nil; }
        return inherited(context);
    }
;
