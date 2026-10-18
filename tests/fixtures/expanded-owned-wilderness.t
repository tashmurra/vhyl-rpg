#include "expanded-wilderness-day.t"
wildernessOwnedKit: RpgLiteItem id = 'survival-kit' quantity = 1;
wildernessOwnedAssessment: RpgExpandedOwnedEquipmentAssessment
    profile = wildernessDependent skill = survivalTarget items = [wildernessOwnedKit]
    approved = true evidence = 'The dependent owns the survival kit';
modify wildernessTools equipmentAssessment = wildernessOwnedAssessment;
modify BleedTestAction
    exec(context)
    {
        if (bleedInput.code == 15410)
        {
            wildernessDependent.equipment = [wildernessOwnedKit];
            event('test.wilderness-owner');
            try { wildernessDay.assess(); eventValue('accepted'); }
            catch (RpgExpandedError error) { eventValue(error.reason); }
            eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
        }
        return inherited(context);
    }
;
