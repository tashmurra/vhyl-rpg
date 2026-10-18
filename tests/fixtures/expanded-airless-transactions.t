#include <vhyl.h>
#include <vhyl.t>
#include <vhyl-en.t>
#include <vhyl-actions.t>
#include <vhyl-rpg.t>
#include <vhyl-rpg-progression.t>
#include <vhyl-rpg-lite.t>
#include <vhyl-rpg-expanded.t>
#include <vhyl-rpg-expanded-skills.t>
#include <vhyl-rpg-expanded-exploration.t>
#include <vhyl-rpg-expanded-health.t>
#include <vhyl-rpg-expanded-hazards.t>
airRoom: Room 'Pressure Chamber';
airRules: RpgExpandedRules scaledInjuryShock = true;
airPatient: RpgExpandedProfile rules = airRules fatigue = 9 injury = 2;
airExposure: RpgExpandedAirlessExposure id = 'airless' profile = airPatient
    evidence = 'Complete deprivation without a breath reserve';
airSecond: RpgExpandedAirlessSecond id = 'first' exposure = airExposure;
airReserve: RpgExpandedBreathReserve id = 'breath' profile = airPatient evidence = 'Prepared fresh breath';
airInput: object code = 0;
class AirFixtureAction: Action
    exec(context)
    {
        local code = airInput.code; local value = nil;
        if (code == 0 || code == 1) value = airExposure.start();
        else if (code == 2) { rpgSpendTime(1); return nil; }
        else if (code == 3 || code == 4)
        {
            if (airSecond.result == nil) rpgRandom.seed(5);
            value = airSecond.apply();
        }
        else if (code == 5 || code == 6)
        {
            if (airExposure.result == nil && airPatient.airClock > 120) rpgRandom.seed(5);
            value = airExposure.resumeAir('Fresh air restored');
        }
        else if (code == 7) { airPatient.validateFeatures(); return nil; }
        else if (code == 8) value = airExposure.assessAir('Fresh air restored');
        else if (code == 9) { airExposure.evidence = 'Changed facts'; value = airExposure.start(); }
        else if (code == 10) value = airReserve.start();
        else if (code == 11) { airPatient.fpAdjustment = 990; airPatient.fatigue = 0; return nil; }
        else if (code == 12)
        {
            local key = '';
            for (local count = 0; count < 121; count += 1)
            {
                key += 's'; rpgSpendTime(1); local second = new RpgExpandedAirlessSecond();
                second.id = key; second.exposure = airExposure; value = second.apply();
                if (value.status != 'resolved') throw new RpgError();
            }
        }
        else if (code == 13) { rpgLiteRest(airPatient,600,true,true,nil,true); return nil; }
        event('test.air-operation'); eventValue(value.status); eventValue(value.reason);
        if (code == 1 || code == 4 || code == 6) throw new RpgError();
        return nil;
    }
;
airAction: AirFixtureAction;
airVerb: Verb code = 1900 action = airAction label = 'air-fixture';
modify gameMain initialRoom = airRoom;
startup() { rpgRandom.seed(1); return vhylStart(); }
turn(tokens) { return vhylTurn(tokens); }
act(verb,args)
{
    if (verb == 1900) { airInput.code = args[1]; return vhylAct(verb,args); }
    if (verb == 1901)
    {
        event('test.air-state'); eventValue(airPatient.fatigue); eventValue(airPatient.injury); eventValue(airPatient.iq);
        eventValue(airPatient.airClock); eventValue(airPatient.airlessExposure == nil ? 0 : 1);
        eventValue(airExposure.seconds.length()); eventValue(airExposure.endedAt == nil ? 0 : 1);
        eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); eventValue(airPatient.unconscious ? 1 : 0);
        eventValue(airPatient.breathReserve == nil ? 0 : 1); return nil;
    }
    return vhylAct(verb,args);
}
