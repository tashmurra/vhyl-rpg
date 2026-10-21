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
turn(tokens) { return rpgDispatchTurn(tokens); }
radiationRules: RpgExpandedRules;
radiationProfile: RpgExpandedProfile rules = radiationRules;
radiationSource: object;
radiationFirst: RpgExpandedRadiationDose id = 'initial-exposure' profile = radiationProfile source = radiationSource
    rads = 200 approved = true evidence = 'Measured received dose';
radiationSecond: RpgExpandedRadiationDose id = 'later-exposure' profile = radiationProfile source = radiationSource
    rads = 100 approved = true evidence = 'A separately measured later dose';
radiationExposure: RpgExpandedRadiationExposure id = 'shielded' profile = radiationProfile source = radiationSource
    incidentRads = 200 protection = 2 approved = true evidence = 'A half-inch lead shield covers the source';
radiationFractional: RpgExpandedRadiationExposure id = 'third-rad' profile = radiationProfile source = radiationSource
    incidentRads = 1 protection = 3 approved = true evidence = 'Verified protection factor';
radiationInput: object code = 0 days = 0;
class RadiationTestAction: Action
    exec(context)
    {
        local code = radiationInput.code;
        if (code >= 10)
        {
            if (code == 17) { radiationFractional.apply(); return nil; }
            if (code == 13) { radiationExposure.incidentRads = 1; return nil; }
            if (code == 14) { radiationExposure.spectrum = 'solar-belt'; return nil; }
            if (code == 15) { radiationExposure.spectrum = 'cosmic'; return nil; }
            local value = code == 11 ? radiationExposure.assess() : radiationExposure.apply();
            event('test.radiation-exposure'); eventValue(value.status); eventValue(value.reason);
            if (code == 12) throw new RpgError(); return nil;
        }
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
    if (verb == 2291) { radiationInput.code = args[1]; radiationInput.days = args[2]; return rpgDispatchAction(verb,[]); }
    if (verb == 2292)
    {
        event('test.radiation-state'); eventValue(radiationProfile.radiationDoses.length());
        eventValue(rpgExpandedRadiationTotalTenths(radiationProfile));
        eventValue(radiationFirst.receivedAt); eventValue(radiationSecond.receivedAt);
        eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
    }
    if (verb == 2295)
    {
        local quantity = rpgExpandedRadiationTotal(radiationProfile);
        event('test.radiation-ratio'); eventValue(quantity.numerator); eventValue(quantity.denominator);
        eventValue(radiationProfile.radiationDoses.length()); eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws);
        return nil;
    }
    return rpgDispatchAction(verb,args);
}
