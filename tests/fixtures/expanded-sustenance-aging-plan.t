#include "expanded-sustenance-injury.t"
sustenanceAgeless: RpgLiteTrait id = 'unaging' points = 15;
sustenanceExtended: RpgLiteTrait id = 'extended-lifespan' points = 2;
sustenanceShort: RpgLiteTrait id = 'short-lifespan' points = -10;
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code >= 12700 && code <= 12707)
        {
            local age = 240; bleedProfile.traits = [];
            if (code == 12701) age = 588;
            if (code == 12702) age = 828;
            if (code == 12703) age = 1068;
            if (code == 12704) { age = 588; bleedProfile.traits = [sustenanceAgeless]; }
            if (code == 12705) { age = 1188; bleedProfile.traits = [sustenanceExtended]; }
            if (code == 12706) { age = 528; bleedProfile.traits = [sustenanceShort]; }
            if (code == 12707) { age = 288; bleedProfile.traits = [sustenanceShort]; }
            local value = rpgExpandedSustenanceAgingPlan(bleedProfile,age);
            event('test.sustenance-aging-plan'); eventValue(value.status); eventValue(value.reason);
            eventValue(value.oldAgeMonths); eventValue(value.newAgeMonths);
            eventValue(value.boundaryAgeMonths.length());
            foreach (local boundary in value.boundaryAgeMonths) eventValue(boundary);
            eventValue(rpgRandom.draws); eventValue(bleedProfile.ht); return nil;
        }
        return inherited(context);
    }
;
