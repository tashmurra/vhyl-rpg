#include "expanded-tracking-acquisition.t"
stepHourCost: RpgExpandedMarchHourCost id = 'incremental-hour' profile = crossPhysician interval = trackingOccurrenceFixture
    approved = true evidence = 'Continuous walking in fixed conditions' dropDestination = healthRoom;
stepProgress: RpgExpandedMarchProgress cost = stepHourCost;
firstMarchStep: RpgExpandedMarchStep id = 'first-minute' progress = stepProgress seconds = 60;
lastMarchStep: RpgExpandedMarchStep id = 'remaining-hour' progress = stepProgress seconds = 3540;
extraMarchStep: RpgExpandedMarchStep id = 'too-far' progress = stepProgress seconds = 3600;
otherMarchInterval: object;
otherStepCost: RpgExpandedMarchHourCost id = 'other-hour' profile = crossPhysician interval = otherMarchInterval
    approved = true evidence = 'Another marching interval' dropDestination = healthRoom;
otherStepProgress: RpgExpandedMarchProgress cost = otherStepCost;
otherMarchStep: RpgExpandedMarchStep id = 'other-minute' progress = otherStepProgress seconds = 60;
otherWholeHour: RpgExpandedMarchHour id = 'other-whole-hour' profile = crossPhysician interval = otherMarchInterval
    approved = true evidence = 'A whole marching hour' dropDestination = healthRoom;
modify PhysicianFixtureAction
    exec(context)
    {
        local code = healthInput.code;
        if (code == 28700 || code == 28701)
        { firstMarchStep.apply(); if (code == 28701) throw new RpgError(); return nil; }
        if (code == 28702) { lastMarchStep.apply(); return nil; }
        if (code == 28703)
        { event('test.march-steps'); eventValue(stepProgress.elapsed); eventValue(stepProgress.steps.length());
          eventValue(rpgLedger.seconds); eventValue(crossPhysician.fatigue); eventValue(crossPhysician.marchHours.length()); eventValue(rpgRandom.draws); return nil; }
        if (code == 28704) { extraMarchStep.apply(); return nil; }
        if (code == 28705) { stepHourCost.apply(); return nil; }
        if (code == 28706) { stepProgress.elapsed += 1; stepProgress.validate(); return nil; }
        if (code == 28707) { rpgSpendTime(1); return nil; }
        if (code == 28708)
        { local value = firstMarchStep.assess(); event('test.march-step-preview'); eventValue(value.status); eventValue(value.reason); return nil; }
        if (code == 28709 || code == 28710 || code == 28711)
        {
            local value = code == 28709 ? otherMarchStep.apply() : code == 28710 ? otherWholeHour.apply() : otherStepCost.apply();
            event('test.march-competing'); eventValue(value.status); eventValue(value.reason); return nil;
        }
        return inherited(context);
    }
;
