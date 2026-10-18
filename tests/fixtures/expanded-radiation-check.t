#include "expanded-radiation-treatment.t"
modify radiationFirst rads = 1;
firstRadiationCheck: RpgExpandedRadiationCheck id = 'first-check' triggerDose = radiationFirst
    approved = true exposureEvidence = 'Living mammal currently irradiated by this source';
laterRadiationCheck: RpgExpandedRadiationCheck id = 'later-check' triggerDose = radiationFirst continued = true
    approved = true exposureEvidence = 'The same source continues irradiating this living patient';
modify RadiationTestAction
    exec(context)
    {
        local code = radiationInput.code;
        if (code == 40) { radiationFirst.rads = 800; return nil; }
        if (code == 41) { radiationFirst.radDenominator = 2; return nil; }
        if (code == 42) { radiationFirst.rads = 3; radiationFirst.radDenominator = 2; return nil; }
        if (code >= 50 && code <= 54)
        {
            local operation = code == 54 ? laterRadiationCheck : firstRadiationCheck;
            local value = code == 51 ? operation.assess() : operation.apply();
            event('test.radiation-check-result'); eventValue(value.status); eventValue(value.reason);
            eventValue(value.effect); eventValue(value.consequencesPending);
            if (code == 52) throw new RpgError(); return nil;
        }
        if (code == 55)
        {
            event('test.radiation-check-state'); eventValue(radiationProfile.radiationChecks.length());
            eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds);
            eventValue(firstRadiationCheck.checkedAt); eventValue(laterRadiationCheck.checkedAt); return nil;
        }
        return inherited(context);
    }
;
