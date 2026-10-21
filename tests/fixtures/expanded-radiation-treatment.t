#include "expanded-radiation.t"
repairStock: RpgExpandedRadiationRepairMedicine id = 'repair-stock' quantity = 2;
modify radiationProfile equipment = [repairStock];
repairCare: RpgExpandedRadiationResistanceTreatment id = 'first-course' profile = radiationProfile
    medicine = repairStock approved = true administrationEvidence = 'One advanced dose administered';
repairRepeat: RpgExpandedRadiationResistanceTreatment id = 'second-course' profile = radiationProfile
    medicine = repairStock approved = true administrationEvidence = 'A new advanced dose administered';
modify RadiationTestAction
    exec(context)
    {
        local code = radiationInput.code;
        if (code == 30) { rpgSpendTime(radiationInput.days); return nil; }
        if (code == 32) { repairStock.techLevel = 8; return nil; }
        if (code == 33) { repairCare.administrationEvidence = ''; return nil; }
        if (code == 31)
        {
            local radiation = new RpgExpandedRadiationContext();
            local ordinary = new RpgLiteContext(); ordinary.attribute = rpgHT;
            event('test.radiation-treatment'); eventValue(repairStock.quantity);
            eventValue(radiationProfile.radiationResistanceTreatments.length());
            eventValue(rpgLiteScore(radiationProfile,radiation)); eventValue(rpgLiteScore(radiationProfile,ordinary));
            eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code >= 20 && code <= 24)
        {
            local care = code == 24 ? repairRepeat : repairCare;
            local value = code == 21 ? care.assess() : care.apply();
            event('test.radiation-treatment-result'); eventValue(value.status); eventValue(value.reason);
            if (code == 22) throw new RpgError(); return nil;
        }
        return inherited(context);
    }
;
