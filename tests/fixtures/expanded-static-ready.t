#include <vhyl.h>
#include <vhyl.t>
#include <vhyl-en.t>
#include <vhyl-actions.t>
#include <vhyl-rpg.t>
#include <vhyl-rpg-progression.t>
#include <vhyl-rpg-lite.t>
#include <vhyl-rpg-expanded.t>
#include <vhyl-rpg-expanded-psionics.t>
staticRoom: Room 'Shielded Gallery';
staticField: RpgExpandedPsionicStatic switchable = true approved = true evidence = 'Paid switchable protection';
staticOwner: RpgExpandedProfile dx = 12 traits = [staticField];
staticFighter: RpgLiteFighter profile = staticOwner;
staticOtherProfile: RpgLiteProfile;
staticOther: RpgLiteFighter profile = staticOtherProfile;
staticBattle: RpgLiteBattle fighters = [staticFighter,staticOther];
staticReady: RpgExpandedStaticReadyManeuver field = staticField enable = nil;
staticIdle: RpgLiteManeuver;
staticInput: object code = 0;
class StaticReadyTestAction: Action
    exec(context)
    {
        local code = staticInput.code;
        if (code >= 7)
        {
            if (code == 7 || code == 9) { staticOwner.fatigue = 20; rpgLiteFatigue(staticOwner,0,'exertion'); }
            if (code == 8) { staticBattle.finish(); rpgLiteRest(staticOwner,1,true,true,true,nil); }
            if (code == 10) staticOwner.unconscious = nil;
            if (code == 9) throw new RpgError(); return nil;
        }
        if (code == 4) staticReady.enable = true;
        if (code == 5) staticField.switchable = nil;
        if (code == 6) staticOwner.stunned = true;
        local value = code == 3 ? staticBattle.step(staticOther,staticIdle) : staticBattle.step(staticFighter,staticReady);
        event('test.static-ready'); eventValue(value.status); eventValue(value.reason);
        if (code == 2) throw new RpgError(); return nil;
    }
;
staticAction: StaticReadyTestAction;
staticVerb: Verb code = 2235 action = staticAction label = 'switch static';
modify gameMain initialRoom = staticRoom;
startup() { rpgRandom.seed(1); vhylStart(); staticBattle.begin(); return nil; }
turn(tokens) { return rpgDispatchTurn(tokens); }
act(verb,args)
{
    if (verb == 2235) { staticInput.code = args[1]; return rpgDispatchAction(verb,[]); }
    if (verb == 2237)
    {
        event('test.static-health'); eventValue(staticField.active ? 1 : 0); eventValue(staticOwner.unconscious ? 1 : 0);
        eventValue(staticOwner.fatigue); eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
    }
    if (verb == 2236)
    {
        event('test.static-ready-state'); eventValue(staticField.active ? 1 : 0);
        eventValue(staticBattle.index); eventValue(staticBattle.seconds); eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
    }
    return nil;
}
