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
immersionRoom: Room 'Rescue Platform';
immersionRules: RpgExpandedRules scaledInjuryShock = true;
immersionPatient: RpgExpandedProfile rules = immersionRules fatigue = 10 temperatureFatigue = 2 injury = 2 temperatureInjury = 2;
immersionExposure: RpgExpandedImmersion id = 'rescue' profile = immersionPatient evidence = 'Icy immersion without dry suit';
immersionInterval: RpgExpandedImmersionInterval id = 'first-minute' exposure = immersionExposure;
immersionInput: object code = 0;
class ImmersionFixtureAction: Action
    exec(context)
    {
        local code = immersionInput.code; local value = nil;
        if (code == 0) value = immersionExposure.start();
        else if (code == 1) { rpgSpendTime(60); return nil; }
        else if (code == 2 || code == 3)
        {
            if (immersionInterval.result == nil) rpgRandom.seed(5);
            value = immersionInterval.apply();
        }
        else if (code == 4 || code == 5) value = immersionExposure.leave('Lifted onto the platform');
        else if (code == 6 || code == 7) value = immersionExposure.warm(true,true,'Shelter and heated blanket');
        else if (code == 8) { immersionPatient.validateFeatures(); return nil; }
        else if (code == 9) value = immersionInterval.assess();
        event('test.immersion-operation'); eventValue(value.status); eventValue(value.reason);
        if (code == 3 || code == 5 || code == 7) throw new RpgError();
        return nil;
    }
;
immersionAction: ImmersionFixtureAction;
immersionVerb: Verb code = 1860 action = immersionAction label = 'immersion-fixture';
modify gameMain initialRoom = immersionRoom;
startup() { rpgRandom.seed(1); return vhylStart(); }
turn(tokens) { return vhylTurn(tokens); }
act(verb,args)
{
    if (verb == 1860) { immersionInput.code = args[1]; return vhylAct(verb,args); }
    if (verb == 1861)
    {
        event('test.immersion-state'); eventValue(immersionPatient.fatigue); eventValue(immersionPatient.temperatureFatigue);
        eventValue(immersionPatient.immersion == immersionExposure ? 1 : 0);
        eventValue(immersionExposure.intervals.length()); eventValue(immersionExposure.exitedAt == nil ? 0 : 1);
        eventValue(immersionExposure.warmedAt == nil ? 0 : 1); eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds);
        eventValue(immersionPatient.injury); eventValue(immersionPatient.temperatureInjury);
        return nil;
    }
    return vhylAct(verb,args);
}
