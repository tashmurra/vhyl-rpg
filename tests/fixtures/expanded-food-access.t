#include "expanded-purchased-rations.t"
foodAccessMarker: object;
modify ExpandedTestAction
    exec(context)
    {
        local code = expandedInput.code;
        if (code == 15900) { purchasedFood.storageLocation = foodAccessMarker; return nil; }
        if (code == 15901) { purchasedFood.thrownFlight = foodAccessMarker; return nil; }
        if (code == 15902) { purchasedFood.sharedCarry = foodAccessMarker; return nil; }
        if (code == 15903) { lifestyleBuyer.equipment = [purchasedFood,purchasedFood]; return nil; }
        if (code == 15904) { purchasedFood.unpackedFrom = nil; return nil; }
        if (code == 15905)
        {
            event('test.food-access');
            try { local value = purchasedMeal.apply(); eventValue(value.status); eventValue(value.reason); }
            catch (RpgExpandedError error) { eventValue('rejected'); eventValue(error.reason); }
            eventValue(purchasedFood.quantity); eventValue(purchasedNeeds.meals); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 15906)
        { purchasedMeal.apply(); throw new RpgError(); }
        return inherited(context);
    }
;
