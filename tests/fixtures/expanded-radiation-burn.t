#include "expanded-radiation-check.t"
modify radiationRules scaledInjuryShock = true;
modify rpgRandom
    roll() { self.draws += 3; return 11; }
;
radiationBurn: RpgExpandedRadiationBurn id = 'initial-burn' radiationCheck = firstRadiationCheck;
laterBurnWound: RpgExpandedWound id = 'later-wound' profile = radiationProfile amount = 2;
modify RadiationTestAction
    exec(context)
    {
        local code = radiationInput.code;
        if (code == 60) { radiationBurn.schedule(); return nil; }
        if (code == 61) { radiationBurn.assessSchedule(); return nil; }
        if (code == 65) { radiationProfile.traits = [rpgLiteMakeTrait('high-pain-threshold',1,nil)]; return nil; }
        if (code == 67) { laterBurnWound.apply(); return nil; }
        if (code >= 62 && code <= 64)
        {
            local value = code == 63 ? radiationBurn.assess() : radiationBurn.apply();
            event('test.radiation-burn-result'); eventValue(value.status); eventValue(value.reason);
            if (code == 64) throw new RpgError(); return nil;
        }
        if (code == 68)
        {
            event('test.radiation-burn'); eventValue(radiationProfile.injury); eventValue(radiationProfile.shock);
            eventValue(radiationProfile.level('low-pain-threshold')); eventValue(radiationProfile.level('high-pain-threshold'));
            eventValue(radiationProfile.radiationBurns.length()); eventValue(radiationBurn.onsetAt);
            eventValue(radiationBurn.onsetDue); eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
        }
        return inherited(context);
    }
;
