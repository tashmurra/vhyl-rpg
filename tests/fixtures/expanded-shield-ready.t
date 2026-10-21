#include <vhyl.h>
#include <vhyl.t>
#include <vhyl-en.t>
#include <vhyl-actions.t>
#include <vhyl-dialogue.t>
#include <vhyl-rpg.t>
#include <vhyl-rpg-progression.t>
#include <vhyl-rpg-lite.t>
#include <vhyl-rpg-expanded.t>
#include <vhyl-rpg-expanded-combat.t>
#include <vhyl-rpg-expanded-health.t>
shieldRoom: Room 'Practice Hall';
shieldRules: RpgExpandedRules;
shieldProfile: RpgExpandedProfile rules = shieldRules dx = 11 equipment = [shieldItem];
shieldItem: RpgLiteItem id = 'shield' db = 1 ready = true worn = true;
shieldFighter: RpgLiteFighter profile = shieldProfile shield = shieldItem;
shieldOtherProfile: RpgLiteProfile;
shieldOther: RpgLiteFighter profile = shieldOtherProfile;
shieldBattle: RpgLiteBattle fighters = [shieldFighter,shieldOther];
shieldFailure: RpgExpandedDefenseFailure id = 'lost-grip' fighter = shieldFighter kind = 'block'
    evidence = 'Recorded critical block in this encounter';
shieldReady: RpgExpandedShieldReadyManeuver failure = shieldFailure;
shieldIdle: RpgLiteManeuver;
shieldGate: RpgExpandedActionGate id = 'recover-grip' profile = shieldProfile evidence = 'Ready shield';
shieldHealth: RpgExpandedHealthManeuver kind = 'ready' healthGate = shieldGate;
shieldInput: object code = 0;
shieldDo(code)
{
        if (code == 0) { shieldFailure.apply(); return nil; }
        if (code == 4) { shieldFailure.apply(); return nil; }
        if (code == 5) { shieldProfile.fatigue = 10; return nil; }
        if (code == 6) shieldReady.healthAdapter = shieldHealth;
        if (code == 7) { shieldProfile.validateFeatures(); return nil; }
        if (code == 8) { shieldReady.healthAdapter = shieldHealth; return nil; }
        local value = code == 3 ? shieldBattle.step(shieldOther,shieldIdle)
            : shieldBattle.step(shieldFighter,shieldReady);
        event('test.shield-ready-operation'); eventValue(value.status); eventValue(value.reason); eventValue(value.outcome);
        if (code == 2) throw new RpgError(); return nil;
}
class ShieldReadyAction: Action
    exec(context) { return shieldDo(shieldInput.code); }
;
class ShieldRouteAction: Action
    operation = 1
    exec(context) { return shieldDo(self.operation); }
;
shieldRestoreAction: ShieldRouteAction;
shieldRollbackAction: ShieldRouteAction operation = 2;
shieldWaitAction: ShieldRouteAction operation = 3;
shieldRestoreVerb: Verb code = 2042 action = shieldRestoreAction label = 'restore-grip';
shieldRollbackVerb: Verb code = 2043 action = shieldRollbackAction label = 'rollback-grip';
shieldWaitVerb: Verb code = 2044 action = shieldWaitAction label = 'wait-opponent';
grammar command(shieldRestoreCmd): 'restore' 'grip' : Command action = shieldRestoreAction;
grammar command(shieldRollbackCmd): 'rollback' 'grip' : Command action = shieldRollbackAction;
grammar command(shieldWaitCmd): 'wait' 'opponent' : Command action = shieldWaitAction;
shieldCoach: Actor 'coach' location(shieldRoom) vocab = 'coach';
shieldPlan: Conversation id = 'shield-plan' target = shieldCoach
    choices = [shieldRestoreChoice,shieldRollbackChoice,shieldWaitChoice];
class ShieldRouteChoice: DialogueChoice
    operation = 1
    selected(context) { return shieldDo(self.operation); }
;
shieldRestoreChoice: ShieldRouteChoice id = 'restore' labelId = 'shield.restore';
shieldRollbackChoice: ShieldRouteChoice id = 'rollback' labelId = 'shield.rollback' operation = 2;
shieldWaitChoice: ShieldRouteChoice id = 'wait' labelId = 'shield.wait' operation = 3;
shieldRestoreLabel: Message id = 'shield.restore' text = 'Restore shield grip';
shieldRollbackLabel: Message id = 'shield.rollback' text = 'Roll back shield recovery';
shieldWaitLabel: Message id = 'shield.wait' text = 'Take the other turn';
shieldAction: ShieldReadyAction;
shieldVerb: Verb code = 2040 action = shieldAction label = 'shield-ready';
modify gameMain initialRoom = shieldRoom;
startup() { shieldBattle.begin(); rpgRandom.seed(1); return vhylStart(); }
turn(tokens) { return rpgDispatchTurn(tokens); }
act(verb,args)
{
    if (verb == 2040) { shieldInput.code = args[1]; return rpgDispatchAction(verb,[]); }
    if (verb == 2041)
    {
        event('test.shield-ready-state'); eventValue(shieldItem.ready ? 1 : 0);
        eventValue(shieldBattle.index); eventValue(shieldBattle.seconds); eventValue(rpgLedger.seconds);
        eventValue(rpgRandom.draws); eventValue(shieldProfile.criticalDefenseFailures.length());
        eventValue(shieldProfile.effortHistory.length()); return nil;
    }
    return rpgDispatchAction(verb,args);
}
