#include "expanded-airless-transactions.t"
modify airPatient fatigue = 0 skills = [breathControlTraining];
breathControlSkill: RpgExpandedBreathControlSkill;
breathControlTraining: RpgTraining skill = breathControlSkill points = 8;
breathPreparation: RpgExpandedBreathPreparation id = 'deep-breath' profile = airPatient
    controlSkill = breathControlSkill approved = true evidence = 'Safe air and a second to prepare outside combat';
modify airReserve preparation = breathPreparation;
modify rpgRandom
    preparationRoll = 3
    roll() { self.draws += 3; return self.preparationRoll; }
;
modify AirFixtureAction
    exec(context)
    {
        local code = airInput.code; local value = nil;
        if (code == 17900 || code == 17901)
        { value = breathPreparation.apply(); if (code == 17901) throw new RpgError(); }
        else if (code == 17902) { rpgRandom.preparationRoll = 16; return nil; }
        else if (code == 17903) { breathPreparation.controlSkill = nil; return nil; }
        else if (code == 17904) { breathControlTraining.points = 0; return nil; }
        else if (code == 17905) { breathPreparation.combat = true; return nil; }
        else if (code == 17906)
        {
            event('test.breath-preparation-state'); eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws);
            eventValue(airReserve.durationSeconds); eventValue(airReserve.controlSucceeded);
            eventValue(breathPreparation.usedBy == airReserve); return nil;
        }
        else if (code == 17907) value = breathPreparation.assess();
        else return inherited(context);
        event('test.breath-preparation-result'); eventValue(value.status); eventValue(value.reason); return nil;
    }
;
