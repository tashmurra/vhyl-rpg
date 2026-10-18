#include "expanded-jump-preparation.t"
launchOccurrence: object;
jumpLaunch: RpgExpandedJumpLaunch id = 'jump-launch' occurrence = launchOccurrence fighter = prepFighter
    battle = prepBattle jumping = prepDistance direction = 'vertical' requiredInchTenths = 180
    approved = true evidence = 'A reachable vertical ledge with a clear approach and a required accuracy check';
launchGate: RpgExpandedActionGate id = 'launch-permission' profile = bleedProfile evidence = 'Move maneuver to jump';
launchManeuver: RpgExpandedJumpLaunchManeuver launch = jumpLaunch healthGate = launchGate;
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 1350 || code == 1351)
        { prepBattle.step(prepFighter,launchManeuver); if (code == 1351) throw new RpgError(); return nil; }
        if (code == 1352)
        {
            event('test.jump-launch'); eventValue(bleedProfile.jumpLaunches.length()); eventValue(rpgRandom.draws);
            eventValue(rpgLedger.seconds); eventValue(bleedProfile.posture); eventValue(prepFighter.concentration);
            if (jumpLaunch.result != nil)
            { eventValue(jumpLaunch.result.succeeded ? 1 : 0); eventValue(jumpLaunch.result.fallRequired ? 1 : 0); }
            return nil;
        }
        if (code == 1353) { jumpLaunch.difficult = true; jumpLaunch.penalty = -1; return nil; }
        if (code == 1354) { bleedInput.forcedRoll = 18; return nil; }
        if (code == 1355)
        { local value = jumpLaunch.assess(); event('test.jump-launch-preview'); eventValue(value.status); eventValue(value.reason); return nil; }
        return inherited(context);
    }
;
