#include "expanded-panic-interrupted-path.t"
waitMode: RpgLiteAttackMode ranged = true base = 'fixed' dice = 1 damageType = 'pi';
waitWeapon: RpgLiteWeapon id = 'watch-pistol' modes = [waitMode] ammunition = 2 ready = true;
modify positionOther equipment = [waitWeapon];
modify pathOtherFighter weapon = waitWeapon;
waitDeclaration: RpgExpandedWaitDeclaration id = 'watch-gate' fighter = pathOtherFighter battle = pathBattle
    weapon = waitWeapon mode = waitMode targetProfile = positionHero triggerHex = positionEast approved = true
    evidence = 'Fire one stationary ordinary shot if this actor enters the watched hex before the next turn';
waitGate: RpgExpandedActionGate id = 'wait-permission' profile = positionOther evidence = 'Declare one Wait turn';
waitManeuver: RpgExpandedWaitManeuver declaration = waitDeclaration healthGate = waitGate;
waitStrike: RpgExpandedAdjudicatedStrike id = 'watch-shot' attacker = pathOtherFighter defender = pathFighter
    weapon = waitWeapon mode = waitMode attackScore = 12 attackRoll = 10 basicDamage = 1
    defenseKind = 'dodge' defenseScore = 8 defenseRoll = 10 wound = routeWound approved = true
    legalityEvidence = 'The watched hex is in clear range; one ordinary shot with no step or special options'
    resolutionEvidence = 'The author records the external hit, failed dodge and final torso injury after protection';
waitInterruption: RpgExpandedPathWaitInterruption move = interruptedMove afterLeg = 1
    declaration = waitDeclaration strike = waitStrike fallUpper = positionOrigin approved = true
    triggerEvidence = 'Entering the first hex matches the declared Wait trigger';
modify interruptedMove interruptions = [waitInterruption];
modify PositionTestAction
    exec(context)
    {
        local code = positionInput.code;
        if (code == 230 || code == 233 || code == 235)
        {
            positionPlacement.apply(); pathBattle.order = [pathOtherFighter,pathFighter]; pathBattle.active = true;
            if (code == 235) { positionOther.injury = 10; pathPanicDice.rolls = [3,18,18,7]; }
            pathBattle.step(pathOtherFighter,waitManeuver);
            if (code == 233)
            { pathBattle.step(pathFighter,new RpgLiteManeuver()); pathBattle.step(pathOtherFighter,new RpgLiteManeuver()); }
            pathPanicEpisode.apply(); return nil;
        }
        if (code == 231)
        {
            event('test.panic-wait'); eventValue(positionFigure.coordinate.q); eventValue(positionHero.injury);
            eventValue(waitWeapon.ammunition); eventValue(positionOther.waitDeclarations.length());
            eventValue(waitDeclaration.triggeredBy == nil ? 0 : 1); eventValue(positionOther.adjudicatedStrikes.length());
            eventValue(positionOther.effortHistory.length()); eventValue(pathOtherFighter.turnSerial);
            eventValue(pathFighter.turnSerial); eventValue(pathBattle.index); eventValue(pathBattle.seconds);
            eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 232) { waitDeclaration.triggerHex = pathFar; pathPanicReaction.assess(); return nil; }
        if (code == 234) { waitInterruption.apply([1,0,0,2]); return nil; }
        if (code == 236) { waitStrike.attackRoll = 13; waitStrike.basicDamage = 0; waitStrike.wound = nil;
            waitStrike.defenseKind = nil; waitStrike.defenseScore = nil; waitStrike.defenseRoll = nil; return nil; }
        if (code == 237) { waitDeclaration.declaredTurnSerial = 9; waitDeclaration.validateReceipt(); return nil; }
        if (code == 238) { waitDeclaration.triggeredBy = nil; waitDeclaration.validateReceipt(); return nil; }
        return inherited(context);
    }
;
