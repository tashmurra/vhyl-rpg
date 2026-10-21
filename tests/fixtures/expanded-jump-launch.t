#include "expanded-jump-preparation.t"
#include <vhyl-rpg-expanded-skills.t>
#include <vhyl-rpg-expanded-hazards.t>
launchOccurrence: object;
jumpLaunch: RpgExpandedJumpLaunch id = 'jump-launch' occurrence = launchOccurrence fighter = prepFighter
    battle = prepBattle jumping = prepDistance direction = 'vertical' requiredInchTenths = 180
    fallYards = 3 fallPlan = launchFallPlan
    approved = true evidence = 'A reachable vertical ledge with a clear approach and a required accuracy check';
launchGate: RpgExpandedActionGate id = 'launch-permission' profile = bleedProfile requiresMovement = true evidence = 'Move maneuver to jump';
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

launchFallInjury: RpgExpandedFallInjury id = 'launch-fall' profile = bleedProfile fall = launchOccurrence
    damageVelocity = 8 approved = true evidence = 'Three-yard critical fall onto the authored landing surface';
launchFallImpact: RpgExpandedFallImpact injury = launchFallInjury;
launchFallPlan: RpgExpandedJumpFallImpact impact = launchFallImpact;
modify rpgRandom die() { self.draws += 1; return 4; };
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 1360)
        {
            event('test.jump-fall-injury'); eventValue(bleedProfile.injury);
            eventValue(bleedProfile.fallImpacts.length()); eventValue(bleedProfile.fallInjuries.length());
            eventValue(rpgRandom.draws); return nil;
        }
        if (code == 1361) { jumpLaunch.fallPlan = nil; return nil; }
        if (code == 1362) { launchFallInjury.resistance = 10; return nil; }
        return inherited(context);
    }
;
