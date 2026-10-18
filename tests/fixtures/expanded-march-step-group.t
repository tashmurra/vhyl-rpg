#include "expanded-march-steps.t"
companionCost: RpgExpandedMarchHourCost id = 'companion-hour' profile = beggingObserver interval = trackingOccurrenceFixture
    approved = true evidence = 'Concurrent travel through the same interval' dropDestination = healthRoom;
companionProgress: RpgExpandedMarchProgress cost = companionCost;
companionFirst: RpgExpandedMarchStep id = 'companion-first' progress = companionProgress seconds = 60;
companionLast: RpgExpandedMarchStep id = 'companion-last' progress = companionProgress seconds = 3540;
firstStepGroup: RpgExpandedMarchStepGroup id = 'shared-first' steps = [firstMarchStep,companionFirst];
lastStepGroup: RpgExpandedMarchStepGroup id = 'shared-last' steps = [lastMarchStep,companionLast];
modify PhysicianFixtureAction
    exec(context)
    {
        local code = healthInput.code;
        if (code == 29500 || code == 29501)
        { firstStepGroup.apply(); if (code == 29501) throw new RpgError(); return nil; }
        if (code == 29502 || code == 29503)
        { lastStepGroup.apply(); if (code == 29503) throw new RpgError(); return nil; }
        if (code == 29504)
        { event('test.march-step-group'); eventValue(rpgLedger.seconds); eventValue(stepProgress.elapsed); eventValue(companionProgress.elapsed);
          eventValue(crossPhysician.fatigue); eventValue(beggingObserver.fatigue); eventValue(crossPhysician.marchHours.length());
          eventValue(beggingObserver.marchHours.length()); eventValue(rpgRandom.draws); return nil; }
        if (code == 29505)
        { local value = firstStepGroup.assess(); event('test.step-group-preview'); eventValue(value.status); eventValue(value.reason); return nil; }
        if (code == 29506) { companionFirst.seconds = 59; firstStepGroup.assess(); return nil; }
        if (code == 29507) { firstStepGroup.steps = [firstMarchStep,firstMarchStep]; firstStepGroup.assess(); return nil; }
        if (code == 29508) { firstStepGroup.result.seconds = 0; firstStepGroup.assess(); return nil; }
        if (code == 29509) { firstMarchStep.apply(); companionFirst.apply(); return nil; }
        return inherited(context);
    }
;
