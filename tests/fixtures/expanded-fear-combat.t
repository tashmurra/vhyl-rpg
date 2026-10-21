#include <vhyl.h>
#include <vhyl.t>
#include <vhyl-en.t>
#include <vhyl-actions.t>
#include <vhyl-rpg.t>
#include <vhyl-rpg-progression.t>
#include <vhyl-rpg-lite.t>
#include <vhyl-rpg-expanded.t>
#include <vhyl-rpg-expanded-health.t>
fearCombatRoom: Room 'Unlit Courtyard';
fearCombatRules: RpgExpandedRules;
fearCombatProfile: RpgExpandedProfile rules = fearCombatRules dx = 12 willAdjustment = 10;
fearCombatOtherProfile: RpgLiteProfile;
fearCombatActor: RpgLiteFighter profile = fearCombatProfile;
fearCombatOther: RpgLiteFighter profile = fearCombatOtherProfile;
fearCombatBattle: RpgLiteBattle fighters = [fearCombatActor,fearCombatOther];
fearCombatContext: RpgExpandedFearContext profile = fearCombatProfile approved = true evidence = 'An extraordinary apparition';
fearCombatEpisode: RpgExpandedFearStun id = 'apparition' context = fearCombatContext tableTotal = 6 approved = true evidence = 'Recorded table outcome';
fearCombatRecovery: RpgExpandedFearStunRecovery id = 'first' episode = fearCombatEpisode;
fearCombatSecondRecovery: RpgExpandedFearStunRecovery id = 'second' episode = fearCombatEpisode;
fearCombatGate: RpgExpandedActionGate id = 'first-turn' profile = fearCombatProfile purpose = 'do-nothing' evidence = 'Recover from fear';
fearCombatRequest: RpgExpandedFearRecoveryManeuver battle = fearCombatBattle recovery = fearCombatRecovery healthGate = fearCombatGate;
fearCombatIdle: RpgLiteManeuver;
fearCombatInput: object code = 0;
class FearCombatTestAction: Action
    exec(context)
    {
        local code = fearCombatInput.code;
        if (code == 0) { fearCombatEpisode.apply(); return nil; }
        if (code == 4) { fearCombatRequest.available(fearCombatActor); return nil; }
        if (code == 7) { fearCombatProfile.willAdjustment = -7; return nil; }
        if (code == 8)
        {
            local extra = fearCombatSecondRecovery.apply();
            event('test.fear-extra'); eventValue(extra.status); eventValue(extra.reason); return nil;
        }
        local value = code == 1 ? fearCombatBattle.step(fearCombatActor,fearCombatIdle)
            : code == 2 ? fearCombatBattle.step(fearCombatOther,fearCombatIdle)
            : fearCombatBattle.step(fearCombatActor,fearCombatRequest);
        event('test.fear-combat'); eventValue(value.status); eventValue(value.reason);
        if (code == 5) throw new RpgError(); return nil;
    }
;
fearCombatAction: FearCombatTestAction;
fearCombatVerb: Verb code = 2252 action = fearCombatAction label = 'fear combat';
modify gameMain initialRoom = fearCombatRoom;
startup() { vhylStart(); rpgRandom.seed(1); fearCombatBattle.begin(); rpgRandom.seed(1); return nil; }
turn(tokens) { return rpgDispatchTurn(tokens); }
act(verb,args)
{
    if (verb == 2252) { fearCombatInput.code = args[1]; return rpgDispatchAction(verb,[]); }
    if (verb == 2253)
    {
        event('test.fear-combat-state'); eventValue(fearCombatProfile.mentalStun ? 1 : 0);
        eventValue(fearCombatEpisode.recoveries.length()); eventValue(fearCombatBattle.index);
        eventValue(fearCombatBattle.seconds); eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws);
        return nil;
    }
    return nil;
}
