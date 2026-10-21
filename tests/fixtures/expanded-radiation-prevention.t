#include "expanded-radiation.t"
preventiveStock: RpgExpandedRadiationPreventive id = 'preventive-stock' quantity = 2;
modify radiationProfile equipment = [preventiveStock];
preventiveCare: RpgExpandedRadiationPrevention id = 'first-administration' profile = radiationProfile
    medicine = preventiveStock approved = true administrationEvidence = 'The patient swallowed one measured dose';
preventiveRepeat: RpgExpandedRadiationPrevention id = 'second-administration' profile = radiationProfile
    medicine = preventiveStock approved = true administrationEvidence = 'The patient swallowed the next measured dose';
modify RadiationTestAction
    exec(context)
    {
        local code = radiationInput.code;
        if (code == 30) { rpgSpendTime(radiationInput.days); return nil; }
        if (code == 31)
        {
            event('test.radiation-prevention'); eventValue(preventiveStock.quantity);
            eventValue(radiationProfile.radiationPreventions.length());
            eventValue(radiationProfile.radiationPreventiveDivisor());
            eventValue(radiationProfile.equipment.length()); eventValue(rpgLedger.seconds);
            eventValue(rpgRandom.draws); return nil;
        }
        if (code >= 20 && code <= 24)
        {
            local care = code == 24 ? preventiveRepeat : preventiveCare;
            local value = code == 21 ? care.assess() : care.apply();
            event('test.radiation-prevention-result'); eventValue(value.status); eventValue(value.reason);
            if (code == 22) throw new RpgError(); return nil;
        }
        return inherited(context);
    }
;
