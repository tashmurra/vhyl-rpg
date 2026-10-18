#include <vhyl.h>
#include <vhyl.t>
#include <vhyl-en.t>
#include <vhyl-actions.t>
#include <vhyl-rpg.t>
#include <vhyl-rpg-progression.t>
#include <vhyl-rpg-lite.t>
#include <vhyl-rpg-expanded.t>
#include <vhyl-rpg-expanded-health.t>
maneuverRoom: Room 'Training Floor';
maneuverRules: RpgExpandedRules;
maneuverPatient: RpgExpandedProfile rules = maneuverRules dx = 11 fatigue = 10 injury = 10;
maneuverOtherProfile: RpgLiteProfile;
maneuverFighter: RpgLiteFighter profile = maneuverPatient;
maneuverOther: RpgLiteFighter profile = maneuverOtherProfile;
maneuverBattle: RpgLiteBattle fighters = [maneuverFighter,maneuverOther];
maneuverGate: RpgExpandedActionGate id = 'first-turn' profile = maneuverPatient evidence = 'Attempt a move';
maneuverRequest: RpgExpandedHealthManeuver kind = 'move' healthGate = maneuverGate;
maneuverIdle: RpgLiteManeuver;
maneuverInput: object code = 0 seedValue = 1;
class ManeuverFixtureAction: Action
    exec(context)
    {
        local code = maneuverInput.code; local value = nil;
        if (code == 0 || code == 1)
        {
            if (maneuverGate.result == nil) rpgRandom.seed(maneuverInput.seedValue);
            value = maneuverBattle.step(maneuverFighter,maneuverRequest);
        }
        else if (code == 2 || code == 3) value = maneuverBattle.step(maneuverOther,maneuverIdle);
        else if (code == 4) { maneuverPatient.validateFeatures(); return nil; }
        else if (code == 5) { maneuverRequest.healthAvailable(maneuverFighter); return nil; }
        else if (code == 6) { maneuverGate.evidence = 'Changed action'; maneuverPatient.validateFeatures(); return nil; }
        event('test.maneuver-operation'); eventValue(value.status); eventValue(value.reason); eventValue(value.outcome);
        if (code == 1 || code == 3) throw new RpgError();
        return nil;
    }
;
maneuverAction: ManeuverFixtureAction;
maneuverVerb: Verb code = 1980 action = maneuverAction label = 'maneuver-fixture';
modify gameMain initialRoom = maneuverRoom;
startup() { maneuverBattle.begin(); rpgRandom.seed(1); return vhylStart(); }
turn(tokens) { return vhylTurn(tokens); }
act(verb,args)
{
    if (verb == 1980)
    { maneuverInput.code = args[1]; maneuverInput.seedValue = args[2]; return vhylAct(verb,args); }
    if (verb == 1981)
    {
        event('test.maneuver-state'); eventValue(maneuverBattle.index); eventValue(maneuverBattle.seconds);
        eventValue(rpgLedger.seconds); eventValue(maneuverPatient.fatigue); eventValue(maneuverPatient.injury);
        eventValue(maneuverPatient.unconscious ? 1 : 0); eventValue(maneuverPatient.exhaustionCollapsed ? 1 : 0);
        eventValue(maneuverPatient.effortHistory.length()); eventValue(maneuverPatient.cardiacHistory.length());
        eventValue(rpgRandom.draws); eventValue(maneuverGate.result == nil ? 0 : 1); return nil;
    }
    return vhylAct(verb,args);
}
