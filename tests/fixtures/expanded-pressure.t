#include "expanded-bleeding.t"
#include <vhyl-rpg-expanded-skills.t>
#include <vhyl-rpg-expanded-hazards.t>
pressureExposure: RpgExpandedPressureExposure id = 'deep-exposure' profile = bleedProfile pressure = 4000
    approved = true evidence = 'Author confirms constant forty-atmosphere exposure and baseline native pressure';
pressureEntry: RpgExpandedPressureCheck exposure = pressureExposure;
pressureMinute: RpgExpandedPressureCheck exposure = pressureExposure;
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 8000) { pressureExposure.begin(); return nil; }
        if (code == 8001 || code == 8002)
        {
            local value = code == 8001 ? pressureEntry.apply() : pressureMinute.apply();
            event('test.pressure'); eventValue(value.status); eventValue(value.reason); eventValue(value.injury); return nil;
        }
        if (code == 8003)
        {
            event('test.pressure-state'); eventValue(bleedProfile.injury); eventValue(pressureExposure.checks.length());
            eventValue(pressureExposure.dueAt); eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 8004) { rpgSpendTime(60); return nil; }
        if (code == 8005) { pressureExposure.sizeModifier = 2; return nil; }
        if (code == 8006) { pressureEntry.apply(); throw new RpgError(); }
        if (code == 8007) { rpgSpendTime(61); return nil; }
        if (code == 8009) { rpgLedger.seconds = 61; return nil; }
        if (code == 8010)
        {
            event('test.pressure-clock');
            try { rpgSpendTime(61); eventValue('accepted'); }
            catch (RpgExpandedError error) { eventValue(error.reason); }
            eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 8011) { pressureExposure.support = 3; return nil; }
        if (code == 8012) { pressureExposure.dueAt += 60; return nil; }
        if (code == 8013) { pressureExposure.end(); return nil; }
        if (code == 8008)
        {
            event('test.pressure-table');
            foreach (local row in [[1000,0],[1001,0],[2000,0],[10000,2],[10001,2],[1000000,3]])
            {
                local value = rpgExpandedAssessPressure(row[1],100,row[2],0);
                eventValue(value.checkRequired ? 1 : 0); eventValue(value.modifier);
            }
            return nil;
        }
        return inherited(context);
    }
;
