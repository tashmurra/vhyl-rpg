#include "expanded-diagnosis-equipment.t"
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code >= 19300 && code <= 19305)
        {
            local level = code - 19300 + 7; diagnosticKit.techLevel = level; diagnosticEquipment.techLevel = level;
            local value = diagnosisCase.assess(); event('test.diagnostic-technology'); eventValue(value.status);
            eventValue(value.reason); eventValue(value.score); eventValue(rpgRandom.draws); return nil;
        }
        return inherited(context);
    }
;
