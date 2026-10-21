#include "expanded-swim-negative-fatigue.t"
swimInitialWill: RpgExpandedSwimConsciousness id = 'initial-will' encounter = swimEncounter;
modify SwimFixtureAction
    exec(context)
    {
        local code = swimInput.code;
        if (code == 17200) { swimPatient.fatigue = swimPatient.maxEnergy; swimEncounter.start(); return nil; }
        if (code == 17201 || code == 17202)
        {
            rpgRandom.exhaustionRoll = 3; swimInitialWill.apply();
            rpgRandom.exhaustionRoll = 16; swimBalance.apply();
            if (code == 17202) throw new RpgError(); return nil;
        }
        if (code == 17203)
        { event('test.swim-initial-block'); eventValue(swimBalance.assess().reason); return nil; }
        if (code == 17204)
        {
            swimInitialWill.completedAt = 1;
            try { swimPatient.validateFeatures(); }
            catch (RpgExpandedError error) { event('test.swim-will-history'); eventValue(error.reason); }
            return nil;
        }
        return inherited(context);
    }
;
