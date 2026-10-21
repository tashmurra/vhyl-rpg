#include <vhyl.h>
#include <vhyl.t>
#include <vhyl-en.t>
#include <vhyl-actions.t>
#include <vhyl-rpg.t>
#include <vhyl-rpg-progression.t>
#include <vhyl-rpg-lite.t>
#include <vhyl-rpg-expanded.t>
#include <vhyl-rpg-expanded-skills.t>
#include <vhyl-rpg-expanded-health.t>
#include <vhyl-rpg-expanded-hazards.t>
coldRoom: Room 'Winter Shelter';
coldRules: RpgExpandedRules scaledInjuryShock = true;
coldPatient: RpgExpandedProfile rules = coldRules fatigue = 10 injury = 2 temperatureFatigue = 2 temperatureInjury = 2;
coldExposure: RpgExpandedColdExposure id = 'winter-watch' profile = coldPatient
    temperatureEvidence = 'Observed still freezing weather';
coldInterval: RpgExpandedColdInterval id = 'first-interval' exposure = coldExposure;
coldInput: object code = 0;
class ColdFixtureAction: Action
    exec(context)
    {
        local code = coldInput.code; local value = nil;
        if (code == 0) value = coldExposure.start();
        else if (code == 1) { rpgSpendTime(1799); return nil; }
        else if (code == 2) { rpgSpendTime(1); return nil; }
        else if (code == 3 || code == 4)
        {
            if (coldInterval.result == nil) rpgRandom.seed(5);
            value = coldInterval.apply();
        }
        else if (code == 5 || code == 6 || code == 7)
            value = coldExposure.finish(true,code != 7,'Shelter and available warmth');
        else if (code == 8) { coldExposure.windMph = 30; value = coldExposure.start(); }
        else if (code == 9) { coldPatient.validateFeatures(); return nil; }
        else if (code == 10)
        {
            local duplicate = new RpgExpandedColdExposure(); duplicate.id = 'duplicate-watch';
            duplicate.profile = coldPatient; duplicate.temperatureEvidence = coldExposure.temperatureEvidence;
            value = duplicate.start();
        }
        else if (code == 11) value = coldInterval.assess();
        event('test.cold-operation'); eventValue(value.status); eventValue(value.reason);
        if (code == 4 || code == 6) throw new RpgError();
        return nil;
    }
;
coldAction: ColdFixtureAction;
coldVerb: Verb code = 1840 action = coldAction label = 'cold-fixture';
modify gameMain initialRoom = coldRoom;
startup() { rpgRandom.seed(1); return vhylStart(); }
turn(tokens) { return rpgDispatchTurn(tokens); }
act(verb,args)
{
    if (verb == 1840) { coldInput.code = args[1]; return rpgDispatchAction(verb,[]); }
    if (verb == 1841)
    {
        event('test.cold-state'); eventValue(coldPatient.fatigue); eventValue(coldPatient.injury);
        eventValue(coldPatient.temperatureFatigue); eventValue(coldPatient.temperatureInjury);
        eventValue(coldPatient.coldExposure == coldExposure ? 1 : 0); eventValue(coldExposure.intervals.length());
        eventValue(coldExposure.ended ? 1 : 0); eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds);
        eventValue(coldExposure.windMph); return nil;
    }
    return rpgDispatchAction(verb,args);
}
