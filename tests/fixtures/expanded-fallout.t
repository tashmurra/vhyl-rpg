#include "expanded-radiation.t"
falloutStock: RpgExpandedFalloutMedicine id = 'basic-removal' quantity = 1;
advancedFalloutStock: RpgExpandedAdvancedFalloutMedicine id = 'advanced-removal' quantity = 1;
modify radiationProfile equipment = [falloutStock,advancedFalloutStock];
falloutBurden: RpgExpandedInternalFallout id = 'ingestion' profile = radiationProfile
    approved = true evidence = 'Confirmed internal contamination';
falloutCare: RpgExpandedFalloutTreatment id = 'removal' profile = radiationProfile medicine = falloutStock
    contamination = falloutBurden approved = true administrationEvidence = 'One removal dose administered';
falloutFirst: RpgExpandedFalloutRelease id = 'internal-first' contamination = falloutBurden
    numerator = 10 approved = true evidence = 'Instantaneous release before source reduction';
falloutLater: RpgExpandedFalloutRelease id = 'internal-later' contamination = falloutBurden
    numerator = 10 approved = true evidence = 'Later instantaneous release before source reduction';
modify RadiationTestAction
    exec(context)
    {
        local code = radiationInput.code;
        if (code == 20) { falloutBurden.apply(); return nil; }
        if (code == 21) { falloutCare.apply(); return nil; }
        if (code == 22) { falloutCare.advanced = true; falloutCare.medicine = advancedFalloutStock; return nil; }
        if (code == 23) { falloutFirst.apply(); return nil; }
        if (code == 24) { falloutLater.apply(); return nil; }
        if (code == 25) { falloutCare.assess(); return nil; }
        if (code == 26) { falloutCare.apply(); throw new RpgError(); }
        if (code == 30) { rpgSpendTime(radiationInput.days); return nil; }
        if (code == 31)
        {
            local fraction = falloutBurden.fraction(); local total = rpgExpandedRadiationTotal(radiationProfile);
            event('test.fallout'); eventValue(fraction.numerator); eventValue(fraction.denominator);
            eventValue(total.numerator); eventValue(total.denominator);
            eventValue(falloutStock.quantity); eventValue(advancedFalloutStock.quantity);
            eventValue(radiationProfile.falloutTreatments.length()); eventValue(radiationProfile.falloutReleases.length());
            eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        return inherited(context);
    }
;
