#include "expanded-swimming-transactions.t"
swimWillOne: RpgExpandedSwimConsciousness id = 'one' encounter = swimEncounter;
swimWillTwo: RpgExpandedSwimConsciousness id = 'two' encounter = swimEncounter;
modify rpgRandom
    exhaustionRoll = 16
    roll() { self.draws += 3; return self.exhaustionRoll; }
;
modify SwimFixtureAction
    exec(context)
    {
        local code = swimInput.code;
        if (code == 17000) { swimPatient.fatigue = swimPatient.maxEnergy - 1; swimEncounter.start(); swimBalance.apply(); return nil; }
        if (code == 17001 || code == 17002)
        {
            rpgSpendTime(1); rpgRandom.exhaustionRoll = 3; swimWillOne.apply();
            if (code == 17002) throw new RpgError(); return nil;
        }
        if (code == 17003) { rpgSpendTime(1); rpgRandom.exhaustionRoll = 16; swimWillTwo.apply(); return nil; }
        if (code == 17004)
        {
            event('test.swim-exhaustion'); eventValue(swimPatient.fp()); eventValue(swimPatient.unconscious);
            eventValue(swimEncounter.willChecks.length()); eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
        }
        if (code == 17005) { swimWillOne.apply(); return nil; }
        return inherited(context);
    }
;
