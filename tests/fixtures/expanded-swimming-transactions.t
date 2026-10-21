#include <vhyl.h>
#include <vhyl.t>
#include <vhyl-en.t>
#include <vhyl-actions.t>
#include <vhyl-rpg.t>
#include <vhyl-rpg-progression.t>
#include <vhyl-rpg-lite.t>
#include <vhyl-rpg-expanded.t>
#include <vhyl-rpg-expanded-exploration.t>
swimRoom: Room 'River Bank';
swimRules: RpgExpandedRules;
swimPatient: RpgExpandedProfile rules = swimRules ht = 14;
swimEncounter: RpgExpandedSwimmingEncounter id = 'river' profile = swimPatient
    defaultAvailable = true pace = 'top-speed' evidence = 'Unexpected deep water; fixed fast swimming';
swimBalance: RpgExpandedSwimCheck id = 'entry' encounter = swimEncounter;
swimEndurance: RpgExpandedSwimEndurance id = 'minute' encounter = swimEncounter;
swimInput: object code = 0;
class SwimFixtureAction: Action
    exec(context)
    {
        local code = swimInput.code; local value = nil;
        if (code == 0) value = swimEncounter.start();
        else if (code == 1 || code == 2) value = swimBalance.apply();
        else if (code == 3) { rpgSpendTime(60); return nil; }
        else if (code == 4 || code == 5) value = swimEndurance.apply();
        else if (code == 6 || code == 7) value = swimEncounter.leave('Climbed onto the river bank');
        else if (code == 8) { swimPatient.validateFeatures(); return nil; }
        else if (code == 9) { swimEncounter.pace = 'floating'; value = swimEncounter.start(); }
        else if (code == 10)
        {
            local duplicate = new RpgExpandedSwimmingEncounter(); duplicate.id = 'other'; duplicate.profile = swimPatient;
            duplicate.evidence = 'Duplicate encounter'; value = duplicate.start();
        }
        else if (code == 11) value = swimEndurance.assess();
        else if (code == 12) { rpgLiteRest(swimPatient,600,true,true,nil,true); return nil; }
        else if (code == 13) value = swimBalance.apply();
        else if (code == 14)
        {
            local breath = new RpgExpandedBreathReserve(); breath.id = 'diving'; breath.profile = swimPatient;
            breath.evidence = 'Attempt to change to diving'; value = breath.start();
        }
        event('test.swim-operation'); eventValue(value.status); eventValue(value.reason);
        if (code == 2 || code == 5 || code == 7) throw new RpgError();
        return nil;
    }
;
swimAction: SwimFixtureAction;
swimVerb: Verb code = 1910 action = swimAction label = 'swimming-fixture';
modify gameMain initialRoom = swimRoom;
startup() { rpgRandom.seed(6); return vhylStart(); }
turn(tokens) { return rpgDispatchTurn(tokens); }
act(verb,args)
{
    if (verb == 1910) { swimInput.code = args[1]; return rpgDispatchAction(verb,[]); }
    if (verb == 1911)
    {
        event('test.swim-state'); eventValue(swimPatient.fatigue); eventValue(swimEncounter.stage);
        eventValue(swimEncounter.nextCheckAt); eventValue(swimEncounter.nextEnduranceAt);
        eventValue(swimEncounter.checks.length()); eventValue(swimEncounter.enduranceChecks.length());
        eventValue(swimPatient.swimmingEncounter == nil ? 0 : 1); eventValue(swimEncounter.endedAt == nil ? 0 : 1);
        eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); eventValue(swimEncounter.pace); return nil;
    }
    return rpgDispatchAction(verb,args);
}
