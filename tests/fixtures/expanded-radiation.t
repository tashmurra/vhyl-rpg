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
radiationRoom: Room 'Shielded Shelter';
modify gameMain initialRoom = radiationRoom;
startup() { rpgRandom.seed(1); return vhylStart(); }
radiationRules: RpgExpandedRules;
radiationProfile: RpgExpandedProfile rules = radiationRules;
radiationSource: object;
radiationFirst: RpgExpandedRadiationDose id = 'initial-exposure' profile = radiationProfile source = radiationSource
    rads = 200 approved = true evidence = 'Measured received dose';
radiationSecond: RpgExpandedRadiationDose id = 'later-exposure' profile = radiationProfile source = radiationSource
    rads = 100 approved = true evidence = 'A separately measured later dose';
radiationInput: object code = 0 days = 0;
class RadiationTestAction: Action
    exec(context)
    {
        local code = radiationInput.code;
        if (code == 3)
        {
            rpgInteger(radiationInput.days,0,100);
            for (local day = 0; day < radiationInput.days; day += 1) rpgSpendTime(86400);
            return nil;
        }
        local dose = code == 4 ? radiationSecond : radiationFirst;
        local value = code == 1 ? dose.assess() : dose.apply();
        event('test.radiation-dose'); eventValue(value.status); eventValue(value.reason);
        if (code == 2) throw new RpgError(); return nil;
    }
;
radiationAction: RadiationTestAction;
radiationVerb: Verb code = 2291 action = radiationAction label = 'radiation record';
act(verb,args)
{
    if (verb == 2291) { radiationInput.code = args[1]; radiationInput.days = args[2]; return vhylAct(verb,args); }
    if (verb == 2292)
    {
        event('test.radiation-state'); eventValue(radiationProfile.radiationDoses.length());
        eventValue(rpgExpandedRadiationTotalTenths(radiationProfile));
        eventValue(radiationFirst.receivedAt); eventValue(radiationSecond.receivedAt);
        eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
    }
    return vhylAct(verb,args);
}
