#include "expanded-sustenance-aging.t"
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 12900) { bleedProfile.hpAdjustment = -1; return nil; }
        if (code == 12901) { bleedProfile.hpAdjustment = -7; return nil; }
        if (code == 12902)
        {
            local value = sustenanceAging.assess(); event('test.sustenance-aging-adjustment-preview');
            eventValue(value.status); eventValue(value.reason); eventValue(rpgRandom.draws);
            eventValue(bleedProfile.st); eventValue(bleedProfile.ht); return nil;
        }
        if (code == 12903) { bleedInput.forcedRoll = 11; return nil; }
        if (code == 12904)
        {
            event('test.sustenance-aging-adjustments'); eventValue(bleedProfile.st); eventValue(bleedProfile.dx);
            eventValue(bleedProfile.iq); eventValue(bleedProfile.ht); eventValue(bleedProfile.maxHP);
            eventValue(bleedProfile.injury); eventValue(rpgRandom.draws); return nil;
        }
        return inherited(context);
    }
;
