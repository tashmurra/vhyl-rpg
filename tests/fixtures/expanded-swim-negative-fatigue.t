#include "expanded-swim-exhaustion.t"
#include <vhyl-rpg-expanded-health.t>
swimNextBalance: RpgExpandedSwimCheck id = 'second-balance' encounter = swimEncounter;
modify SwimFixtureAction
    exec(context)
    {
        local code = swimInput.code;
        if (code == 17100 || code == 17101)
        {
            rpgRandom.exhaustionRoll = 3;
            foreach (local id in ['tick-one','tick-two','tick-three','tick-four','tick-five'])
            {
                rpgSpendTime(1); local check = new RpgExpandedSwimConsciousness();
                check.id = id; check.encounter = swimEncounter; check.apply();
            }
            rpgRandom.exhaustionRoll = 16; swimNextBalance.apply();
            if (code == 17101) throw new RpgError(); return nil;
        }
        if (code == 17102)
        {
            event('test.swim-negative'); eventValue(swimPatient.fp()); eventValue(swimPatient.injury);
            eventValue(swimEncounter.willChecks.length()); eventValue(swimEncounter.checks.length());
            eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
        }
        if (code == 17103) { swimNextBalance.apply(); return nil; }
        return inherited(context);
    }
;
