#include <vhyl.h>
#include <vhyl.t>
#include <vhyl-en.t>
#include <vhyl-actions.t>
#include <vhyl-rpg.t>
#include <vhyl-rpg-progression.t>
#include <vhyl-rpg-lite.t>
#include <vhyl-rpg-expanded.t>
#include <vhyl-rpg-expanded-health.t>
effortRoom: Room 'Rest Station';
effortRules: RpgExpandedRules;
effortPatient: RpgExpandedProfile rules = effortRules fatigue = 10;
effortRequest: RpgExpandedEffort id = 'open-door' profile = effortPatient evidence = 'Attempt to open the door';
effortNext: RpgExpandedEffort id = 'lift-pack' profile = effortPatient evidence = 'Attempt to lift the pack';
effortInput: object code = 0 seedValue = 1;
class EffortFixtureAction: Action
    exec(context)
    {
        local code = effortInput.code; local value = nil;
        if (code == 0 || code == 1)
        {
            if (effortRequest.result == nil) rpgRandom.seed(effortInput.seedValue);
            value = effortRequest.apply();
        }
        else if (code == 2) value = effortRequest.assess();
        else if (code == 3) { effortPatient.validateFeatures(); return nil; }
        else if (code == 4) { effortRequest.evidence = 'Changed action'; value = effortRequest.assess(); }
        else if (code == 5 || code == 6)
        { rpgLiteRest(effortPatient,600,true,true,nil,true); if (code == 6) throw new RpgError(); return nil; }
        else if (code == 7) value = effortNext.apply();
        event('test.effort-operation'); eventValue(value.status); eventValue(value.reason);
        if (code == 1) throw new RpgError();
        return nil;
    }
;
effortAction: EffortFixtureAction;
effortVerb: Verb code = 1960 action = effortAction label = 'effort-fixture';
modify gameMain initialRoom = effortRoom;
startup() { rpgRandom.seed(1); return vhylStart(); }
turn(tokens) { return rpgDispatchTurn(tokens); }
act(verb,args)
{
    if (verb == 1960)
    { effortInput.code = args[1]; effortInput.seedValue = args[2]; return rpgDispatchAction(verb,[]); }
    if (verb == 1961)
    {
        event('test.effort-state'); eventValue(effortPatient.fatigue);
        eventValue(effortPatient.exhaustionCollapsed ? 1 : 0); eventValue(effortPatient.unconscious ? 1 : 0);
        eventValue(effortPatient.effortHistory.length()); eventValue(effortPatient.cardiacHistory.length());
        eventValue(effortPatient.cardiacArrest == nil ? 0 : 1);
        eventValue(effortRequest.result == nil ? 0 : 1); eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds);
        return nil;
    }
    return rpgDispatchAction(verb,args);
}
