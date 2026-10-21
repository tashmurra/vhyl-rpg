#include "expanded-tactical-path.t"
pathFighter: RpgLiteFighter profile = positionHero;
pathOtherFighter: RpgLiteFighter profile = positionOther;
pathBattle: RpgLiteBattle fighters = [pathFighter,pathOtherFighter];
pathOperation: RpgExpandedPathMove id = 'first-path' fighter = pathFighter battle = pathBattle path = pathRequest
    uninterrupted = true evidence = 'No reaction, interrupt or hazard check is pending on the authored route';
pathGate: RpgExpandedActionGate id = 'path-permission' profile = positionHero requiresMovement = true
    evidence = 'One Move turn along the assessed path';
pathManeuver: RpgExpandedPathMoveManeuver operation = pathOperation healthGate = pathGate;
modify PositionTestAction
    exec(context)
    {
        local code = positionInput.code;
        if (code == 100)
        { pathBattle.order = [pathFighter,pathOtherFighter]; pathBattle.active = true; return nil; }
        if (code == 101 || code == 102)
        { pathBattle.step(pathFighter,pathManeuver); if (code == 102) throw new RpgError(); return nil; }
        if (code == 103) { pathBattle.step(pathOtherFighter,new RpgLiteManeuver()); return nil; }
        if (code == 104)
        {
            event('test.path-move'); eventValue(positionFigure.coordinate.q); eventValue(positionFigure.coordinate.r);
            eventValue(positionFigure.facing); eventValue(positionHero.pathMoves.length());
            eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 105)
        { local value = pathOperation.assess(); event('test.path-move-preview'); eventValue(value.status); eventValue(value.reason); return nil; }
        if (code == 106) { pathOperation.uninterrupted = nil; return nil; }
        if (code == 107)
        {
            event('test.path-move-allowance'); eventValue(positionHero.moveBeforePosture());
            eventValue(positionHero.move()); return nil;
        }
        if (code == 108)
        {
            local legacy = new RpgLiteProfile();
            foreach (local posture in ['standing','crouching','kneeling','crawling','sitting','lying'])
            {
                legacy.posture = posture;
                event('test.legacy-move'); eventValue(legacy.move());
            }
            legacy.injury = 7; legacy.fatigue = 7;
            foreach (local posture in ['standing','crouching','kneeling','crawling','sitting','lying'])
            {
                legacy.posture = posture;
                event('test.legacy-move'); eventValue(legacy.move());
            }
            legacy.unconscious = true;
            event('test.legacy-move'); eventValue(legacy.move()); return nil;
        }
        return inherited(context);
    }
;

pathForcedRoll: object value = nil;
modify rpgRandom
    roll()
    {
        if (pathForcedRoll.value == nil) return inherited();
        self.draws += 3; return pathForcedRoll.value;
    }
;
modify PositionTestAction
    exec(context)
    {
        local code = positionInput.code;
        if (code == 109) { positionHero.fatigue = 10; pathRequest.move = 3; pathForcedRoll.value = 11; return nil; }
        if (code == 110)
        {
            event('test.physical-gate-state'); eventValue(positionHero.effortHistory.length());
            eventValue(positionHero.exhaustionCollapsed ? 1 : 0); eventValue(rpgRandom.draws);
            eventValue(rpgLedger.seconds); return nil;
        }
        if (code == 111 || code == 112)
        {
            pathGate.requiresMovement = code == 112;
            pathGate.mentalAbility = code == 112;
            event('test.physical-gate-invalid');
            try { pathBattle.step(pathFighter,pathManeuver); eventValue('accepted'); }
            catch (RpgExpandedError error) { eventValue(error.reason); }
            return nil;
        }
        if (code == 113)
        {
            foreach (local request in [new RpgExpandedJumpPrepareManeuver(),new RpgExpandedJumpLaunchManeuver(),new RpgExpandedPathMoveManeuver()])
            {
                local gate = new RpgExpandedActionGate(); gate.id = 'permission-preview'; gate.profile = positionHero;
                gate.evidence = 'Preview a physical permission'; request.healthGate = gate;
                event('test.physical-gate-contract');
                try { request.healthAvailable(pathFighter); eventValue('accepted'); }
                catch (RpgExpandedError error) { eventValue(error.reason); }
                gate.requiresMovement = true; eventValue(request.healthAvailable(pathFighter));
            }
            return nil;
        }
        return inherited(context);
    }
;
