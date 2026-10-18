#include "expanded-tactical-posture.t"
#include <vhyl-rpg-expanded-health.t>
postureHealthGate: RpgExpandedActionGate id = 'posture-down' profile = positionHero purpose = 'action'
    evidence = 'One permission decision for the posture turn';
postureHealthAdapter: RpgExpandedHealthManeuver kind = 'posture' healthGate = postureHealthGate;
modify postureDown healthPermission = postureHealthAdapter;
modify PositionTestAction
    exec(context)
    {
        local code = positionInput.code;
        if (code == 60) { positionHero.injury = 10; return nil; }
        if (code == 61) { positionHero.willAdjustment = 10; positionHero.ht = 20; positionHero.fpAdjustment = -10; return nil; }
        if (code == 62) { rpgRandom.seed(5); return nil; }
        if (code == 63) { postureHealthGate.profile = positionOther; return nil; }
        if (code == 64) { positionHero.ht = 3; return nil; }
        if (code == 65)
        {
            event('test.posture-health-preview'); eventValue(postureDown.healthAvailable(postureActor)); return nil;
        }
        return inherited(context);
    }
;
modify positionInput
    reportHealth()
    {
        event('test.posture-health-state'); eventValue(positionHero.effortHistory.length());
        eventValue(postureHealthGate.result == nil ? nil : postureHealthGate.result.allowed);
        eventValue(positionHero.unconscious ? 1 : 0); eventValue(positionHero.fatigue);
        eventValue(postureBattle.index); eventValue(postureBattle.seconds);
        eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws);
        return nil;
    }
;
