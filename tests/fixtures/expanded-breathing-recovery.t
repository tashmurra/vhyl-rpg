#include "expanded-breath-preparation.t"
modify airPatient fatigue = 5;
breathingRest: RpgExpandedBreathingRecovery id = 'quiet-breathing' profile = airPatient skill = breathControlSkill
    approved = true evidence = 'Quiet uninterrupted rest without restorative magic';
modify AirFixtureAction
    exec(context)
    {
        local code = airInput.code; local value = nil;
        if (code == 18000 || code == 18001)
        { value = breathingRest.apply(); if (code == 18001) throw new RpgError(); }
        else if (code == 18002) { airPatient.restClock = 590; return nil; }
        else if (code == 18003) { breathingRest.restorativeMagic = true; return nil; }
        else if (code == 18004) { airPatient.fatigue = 0; return nil; }
        else if (code == 18005)
        {
            event('test.breathing-recovery-state'); eventValue(airPatient.fatigue); eventValue(airPatient.restClock);
            eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); eventValue(airPatient.breathingRecoveries.length()); return nil;
        }
        else if (code == 18006) value = breathingRest.assess();
        else return inherited(context);
        event('test.breathing-recovery-result'); eventValue(value.status); eventValue(value.reason); return nil;
    }
;
