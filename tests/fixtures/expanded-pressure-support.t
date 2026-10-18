#include "expanded-pressure.t"
#include <vhyl-rpg-expanded-traits.t>
pressureSupport: RpgExpandedPressureSupport level = 1 approved = true;
modify bleedProfile traits = [pressureSupport];
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code >= 8100 && code <= 8102) { pressureSupport.level = code - 8099; return nil; }
        if (code == 8110)
        {
            local value = pressureExposure.assess();
            event('test.pressure-support'); eventValue(pressureSupport.creationCost());
            eventValue(pressureExposure.resolvedSupport()); eventValue(value.checkRequired ? 1 : 0);
            eventValue(value.modifier); eventValue(value.bendsRisk ? 1 : 0); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 8111) { pressureSupport.mitigated = true; return nil; }
        if (code == 8112) { bleedProfile.nativePressureHundredths = 200; return nil; }
        if (code == 8113)
        {
            event('test.pressure-support-error');
            try { pressureEntry.apply(); eventValue('accepted'); }
            catch (RpgExpandedError error) { eventValue(error.reason); }
            eventValue(rpgRandom.draws); return nil;
        }
        if (code == 8114)
        {
            local original = rpgExpandedTemplateTraits.plain('pressure-support',2,nil);
            local copy = rpgExpandedTemplateTraits.copy(original);
            event('test.pressure-support-copy'); eventValue(copy != original ? 1 : 0); eventValue(copy.creationCost()); return nil;
        }
        return inherited(context);
    }
;
