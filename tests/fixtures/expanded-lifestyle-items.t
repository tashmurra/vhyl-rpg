#include "expanded.t"
lifestyleBuyer: RpgExpandedProfile rules = expandedRules money = 1000;
lifestyleRationsPrice: RpgExpandedLifestyle kind = 'rations-week';
lifestyleWardrobePrice: RpgExpandedLifestyle kind = 'wardrobe';
lifestyleRations: RpgExpandedLifestyleItem id = 'trail-food' lifestyle = lifestyleRationsPrice
    approved = true evidence = 'One sealed week of ordinary travel rations';
lifestyleWardrobe: RpgExpandedLifestyleItem id = 'replacement-clothes' lifestyle = lifestyleWardrobePrice
    exactWeight = 2300 approved = true evidence = 'Complete replacement wardrobe weighed at twenty-three pounds';
lifestyleRationsSale: RpgExpandedAcquisition profile = lifestyleBuyer item = lifestyleRations available = true permitted = true;
lifestyleWardrobeSale: RpgExpandedAcquisition profile = lifestyleBuyer item = lifestyleWardrobe available = true permitted = true;
modify ExpandedTestAction
    exec(context)
    {
        local code = expandedInput.code;
        if (code == 15500 || code == 15501)
        {
            lifestyleRationsSale.acquire(); lifestyleWardrobeSale.acquire();
            if (code == 15501) throw new RpgError(); return nil;
        }
        if (code == 15502)
        {
            event('test.lifestyle-items'); eventValue(lifestyleBuyer.money); eventValue(lifestyleBuyer.equipment.length());
            eventValue(lifestyleRations.cost); eventValue(lifestyleRations.weight);
            eventValue(lifestyleWardrobe.cost); eventValue(lifestyleWardrobe.weight); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 15503 || code == 15504 || code == 15505)
        {
            if (code == 15503) lifestyleWardrobe.exactWeight = nil;
            if (code == 15504) lifestyleWardrobe.exactWeight = 1900;
            if (code == 15505) lifestyleRationsPrice.kind = 'lodging-day';
            event('test.lifestyle-item-rejected');
            try { lifestyleRationsSale.assess(); lifestyleWardrobeSale.assess(); eventValue(nil); }
            catch (RpgError error) { eventValue(true); }
            eventValue(lifestyleBuyer.money); eventValue(lifestyleBuyer.equipment.length()); eventValue(rpgRandom.draws); return nil;
        }
        return inherited(context);
    }
;
