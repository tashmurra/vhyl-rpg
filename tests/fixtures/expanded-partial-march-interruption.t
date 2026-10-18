#include "expanded-march-steps.t"
partialMarchInterruption: RpgExpandedPartialMarchInterruption id = 'combat-arrives' progress = stepProgress
    combat = true assumeFullHour = true approved = true evidence = 'Combat interrupts this marching interval; the full-hour assumption applies';
modify PhysicianFixtureAction
    exec(context)
    {
        local code = healthInput.code;
        if (code == 28900 || code == 28901)
        { partialMarchInterruption.apply(); if (code == 28901) throw new RpgError(); return nil; }
        if (code == 28902)
        { local value = partialMarchInterruption.assess(); event('test.partial-interruption'); eventValue(value.status); eventValue(value.reason); return nil; }
        if (code == 28903) { partialMarchInterruption.assumeFullHour = nil; return nil; }
        if (code == 28904) { partialMarchInterruption.combat = nil; return nil; }
        if (code == 28905) { partialMarchInterruption.completedAt += 1; partialMarchInterruption.assess(); return nil; }
        if (code == 28906) { stepProgress.interruption = nil; stepProgress.validate(); return nil; }
        return inherited(context);
    }
;
