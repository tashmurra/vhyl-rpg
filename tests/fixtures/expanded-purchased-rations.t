#include "expanded-lifestyle-items.t"
purchasedFood: RpgExpandedRationStock id = 'opened-rations';
purchasedUnpacking: RpgExpandedRationUnpacking id = 'open-package' profile = lifestyleBuyer
    package = lifestyleRations stock = purchasedFood ordinaryHumanDiet = true approved = true
    evidence = 'Ready-to-eat food divided for an ordinary human diet';
purchasedNeeds: RpgLiteNeeds profile = lifestyleBuyer meals = 0;
purchasedMeal: RpgExpandedFoodMeal id = 'lunch' profile = lifestyleBuyer needs = purchasedNeeds
    stock = purchasedFood approved = true evidence = 'One portion eaten';
modify ExpandedTestAction
    exec(context)
    {
        local code = expandedInput.code;
        if (code == 15800) { lifestyleRationsSale.acquire(); return nil; }
        if (code == 15801 || code == 15802)
        { purchasedUnpacking.apply(); if (code == 15802) throw new RpgError(); return nil; }
        if (code == 15803) { purchasedMeal.apply(); return nil; }
        if (code == 15804)
        {
            event('test.purchased-rations'); eventValue(lifestyleBuyer.money); eventValue(lifestyleBuyer.equipment.length());
            eventValue(lifestyleRations.quantity); eventValue(purchasedFood.quantity); eventValue(purchasedFood.weightHundredths());
            eventValue(purchasedNeeds.meals); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 15805)
        {
            local value = purchasedUnpacking.assess(); event('test.ration-preview'); eventValue(value.status);
            eventValue(value.reason); eventValue(purchasedFood.quantity); return nil;
        }
        if (code == 15806) { purchasedUnpacking.ordinaryHumanDiet = nil; return nil; }
        return inherited(context);
    }
;
