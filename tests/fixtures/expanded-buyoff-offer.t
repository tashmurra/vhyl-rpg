#include "expanded-buyoff.t"
buyoffOffer: RpgDevelopment
    id = 'aid-buyoff' profile = bleedProfile kind = 'remove-trait' trait = aidTrait cost = 30 unlocked = true
    available(profile) { return nil; }
;
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 5300 || code == 5301 || code == 5304)
        {
            local value = code == 5300 ? rpgAssessDevelopment(buyoffOffer) : rpgDevelop(buyoffOffer);
            event('test.buyoff-offer'); eventValue(value.status); eventValue(value.reason); eventValue(value.points);
            if (code == 5304) throw new RpgError(); return nil;
        }
        if (code == 5302) { buyoffOffer.cost = 15; return nil; }
        if (code == 5303) { buyoffOffer.cost = 35; return nil; }
        return inherited(context);
    }
;
