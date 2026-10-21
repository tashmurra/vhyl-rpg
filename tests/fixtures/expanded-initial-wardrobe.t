#include "expanded-lifestyle-items.t"
initialClothesCulture: object;
initialClothes: RpgExpandedInitialWardrobe profile = lifestyleBuyer item = lifestyleWardrobe
    applicableStatus = 0 culture = initialClothesCulture approved = true
    evidence = 'Full standing in the starting culture is zero' available = true permitted = true;
secondClothes: RpgExpandedLifestyleItem id = 'second-wardrobe' lifestyle = lifestyleWardrobePrice
    exactWeight = 2000 approved = true evidence = 'Second complete wardrobe';
secondInitialClothes: RpgExpandedInitialWardrobe profile = lifestyleBuyer item = secondClothes
    applicableStatus = 0 culture = initialClothesCulture approved = true
    evidence = 'Same standing does not entitle a second wardrobe' available = true permitted = true;
modify ExpandedTestAction
    exec(context)
    {
        local code = expandedInput.code;
        if (code == 15600 || code == 15601)
        {
            local value = initialClothes.acquire(); event('test.initial-clothes-result');
            eventValue(value.status); eventValue(value.reason);
            if (code == 15601) throw new RpgError(); return nil;
        }
        if (code == 15602)
        {
            event('test.initial-clothes-state'); eventValue(lifestyleBuyer.money);
            eventValue(lifestyleBuyer.equipment.length()); eventValue(lifestyleBuyer.initialWardrobe == initialClothes);
            eventValue(rpgRandom.draws); return nil;
        }
        if (code == 15603)
        {
            local value = secondInitialClothes.acquire(); event('test.initial-clothes-second');
            eventValue(value.status); eventValue(value.reason); return nil;
        }
        if (code == 15604) { lifestyleBuyer.creationComplete = true; return nil; }
        if (code == 15605)
        {
            lifestyleBuyer.equipment = []; initialClothes.acquire(); return nil;
        }
        if (code == 15606)
        {
            initialClothes.applicableStatus = 1;
            try { initialClothes.acquire(); }
            catch (RpgExpandedError error) { event('test.initial-clothes-binding'); eventValue(error.reason); }
            return nil;
        }
        return inherited(context);
    }
;
