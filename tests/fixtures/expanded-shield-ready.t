#include <vhyl.h>
#include <vhyl.t>
#include <vhyl-en.t>
#include <vhyl-actions.t>
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
class ShieldReadyAction: Action
    exec(context)
    {
        local code = shieldInput.code;
        if (code == 0) { shieldFailure.apply(); return nil; }
        if (code == 4) { shieldFailure.apply(); return nil; }
        if (code == 5) { shieldProfile.fatigue = 10; return nil; }
        if (code == 6) shieldReady.healthAdapter = shieldHealth;
        if (code == 7) { shieldProfile.validateFeatures(); return nil; }
        local value = code == 3 ? shieldBattle.step(shieldOther,shieldIdle)
            : shieldBattle.step(shieldFighter,shieldReady);
        event('test.shield-ready-operation'); eventValue(value.status); eventValue(value.reason); eventValue(value.outcome);
        if (code == 2) throw new RpgError(); return nil;
    }
;
shieldAction: ShieldReadyAction;
shieldVerb: Verb code = 2040 action = shieldAction label = 'shield-ready';
modify gameMain initialRoom = shieldRoom;
startup() { shieldBattle.begin(); rpgRandom.seed(1); return vhylStart(); }
turn(tokens) { return vhylTurn(tokens); }
act(verb,args)
{
    if (verb == 2040) { shieldInput.code = args[1]; return vhylAct(verb,args); }
    if (verb == 2041)
    {
        event('test.shield-ready-state'); eventValue(shieldItem.ready ? 1 : 0);
        eventValue(shieldBattle.index); eventValue(shieldBattle.seconds); eventValue(rpgLedger.seconds);
        eventValue(rpgRandom.draws); eventValue(shieldProfile.criticalDefenseFailures.length());
        eventValue(shieldProfile.effortHistory.length()); return nil;
    }
    return vhylAct(verb,args);
}
