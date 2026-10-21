#include "expanded-fishing-forage.t"
forageStock: RpgExpandedFoodStock id = 'river-fish' weight = 80;
forageSpareStock: RpgExpandedFoodStock id = 'duplicate-fish' weight = 80;
forageHarvest: RpgExpandedForageHarvest id = 'gather-fish' profile = bleedProfile source = fishingAttempt stock = forageStock
    approved = true evidence = 'The forager keeps the caught fish; the author assigns eighty hundredths of a pound per meal';
forageDuplicate: RpgExpandedForageHarvest id = 'gather-again' profile = bleedProfile source = fishingAttempt stock = forageSpareStock
    approved = true evidence = 'A second request for the same yield';
forageNeeds: RpgLiteNeeds profile = bleedProfile meals = 0;
forageMeal: RpgExpandedFoodMeal id = 'fish-supper' profile = bleedProfile needs = forageNeeds stock = forageStock
    approved = true evidence = 'One prepared meal eaten by this character';
forageSecondMeal: RpgExpandedFoodMeal id = 'fish-second-meal' profile = bleedProfile needs = forageNeeds stock = forageStock
    approved = true evidence = 'Another prepared meal eaten by this character';
forageThirdMeal: RpgExpandedFoodMeal id = 'fish-third-meal' profile = bleedProfile needs = forageNeeds stock = forageStock
    approved = true evidence = 'Attempt to consume another meal from the same supply';
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 1900 || code == 1901)
        {
            local value = forageHarvest.apply(); event('test.forage-harvest'); eventValue(value.status); eventValue(value.reason);
            if (code == 1901) throw new RpgError(); return nil;
        }
        if (code == 1902)
        { local value = forageHarvest.assess(); event('test.forage-harvest-preview'); eventValue(value.status); eventValue(value.reason); return nil; }
        if (code == 1903)
        {
            event('test.forage-food'); eventValue(forageStock.quantity); eventValue(holds(bleedProfile.equipment,forageStock) ? 1 : 0);
            eventValue(bleedProfile.forageHarvests.length()); eventValue(forageNeeds.meals); eventValue(bleedProfile.mealCredits.length());
            eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
        }
        if (code == 1904 || code == 1905 || code == 1909 || code == 1910)
        {
            local request = code == 1909 ? forageSecondMeal : code == 1910 ? forageThirdMeal : forageMeal;
            local value = request.apply(); event('test.forage-meal'); eventValue(value.status); eventValue(value.reason);
            if (code == 1905) throw new RpgError(); return nil;
        }
        if (code == 1906)
        {
            event('test.forage-harvest-duplicate');
            try { forageDuplicate.apply(); eventValue('accepted'); }
            catch (RpgExpandedError error) { eventValue(error.reason); }
            return nil;
        }
        if (code == 1907)
        { forageStock.readyToEat = true; forageStock.preparationEvidence = 'Cooking completed over the campfire before this meal'; return nil; }
        return inherited(context);
    }
;
