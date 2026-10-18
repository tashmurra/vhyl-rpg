#include <vhyl.h>
#include <vhyl.t>
#include <vhyl-en.t>
#include <vhyl-actions.t>
#include <vhyl-dialogue.t>
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
maneuverDo(code, seedValue)
{
    local value = nil;
    if (code == 0 || code == 1)
    {
        if (maneuverGate.result == nil) rpgRandom.seed(seedValue);
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
class ManeuverFixtureAction: Action
    exec(context) { return maneuverDo(maneuverInput.code,maneuverInput.seedValue); }
;
class ManeuverRouteAction: Action
    code = 0
    exec(context) { return maneuverDo(self.code,maneuverInput.seedValue); }
;
maneuverFirstAction: ManeuverRouteAction code = 0;
maneuverFirstFailureAction: ManeuverRouteAction code = 1;
maneuverSecondAction: ManeuverRouteAction code = 2;
maneuverSecondFailureAction: ManeuverRouteAction code = 3;
maneuverFirstVerb: Verb code = 1983 action = maneuverFirstAction label = 'first-turn';
maneuverSecondVerb: Verb code = 1984 action = maneuverSecondAction label = 'second-turn';
maneuverFirstFailureVerb: Verb code = 1985 action = maneuverFirstFailureAction label = 'first-rollback';
maneuverSecondFailureVerb: Verb code = 1986 action = maneuverSecondFailureAction label = 'second-rollback';
grammar command(maneuverFirstCmd): 'first' 'turn' : Command action = maneuverFirstAction;
grammar command(maneuverSecondCmd): 'second' 'turn' : Command action = maneuverSecondAction;
grammar command(maneuverFirstFailureCmd): 'first' 'rollback' : Command action = maneuverFirstFailureAction;
grammar command(maneuverSecondFailureCmd): 'second' 'rollback' : Command action = maneuverSecondFailureAction;
maneuverInstructor: Actor 'instructor' location(maneuverRoom) vocab = 'instructor';
maneuverPlan: Conversation id = 'maneuver-plan' target = maneuverInstructor
    choices = [maneuverFirstChoice,maneuverSecondChoice,maneuverFirstFailureChoice,maneuverSecondFailureChoice];
class ManeuverRouteChoice: DialogueChoice
    code = 0
    selected(context) { return maneuverDo(self.code,maneuverInput.seedValue); }
;
maneuverFirstChoice: ManeuverRouteChoice id = 'first' labelId = 'maneuver.first' code = 0;
maneuverSecondChoice: ManeuverRouteChoice id = 'second' labelId = 'maneuver.second' code = 2;
maneuverFirstFailureChoice: ManeuverRouteChoice id = 'first-rollback' labelId = 'maneuver.first-rollback' code = 1;
maneuverSecondFailureChoice: ManeuverRouteChoice id = 'second-rollback' labelId = 'maneuver.second-rollback' code = 3;
maneuverFirstLabel: Message id = 'maneuver.first' text = 'Take the first turn';
maneuverSecondLabel: Message id = 'maneuver.second' text = 'Take the second turn';
maneuverFirstFailureLabel: Message id = 'maneuver.first-rollback' text = 'Roll back the first turn';
maneuverSecondFailureLabel: Message id = 'maneuver.second-rollback' text = 'Roll back the second turn';
maneuverAction: ManeuverFixtureAction;
maneuverVerb: Verb code = 1980 action = maneuverAction label = 'maneuver-fixture';
modify gameMain initialRoom = maneuverRoom;
startup() { maneuverBattle.begin(); rpgRandom.seed(1); return vhylStart(); }
turn(tokens) { return vhylTurn(tokens); }
act(verb,args)
{
    if (verb == 1982)
    {
        maneuverInput.seedValue = args[1];
        if (args.length() > 1) maneuverPatient.injury = args[2];
        return nil;
    }
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
