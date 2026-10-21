#include "expanded-extreme-panic.t"
attackTarget: RpgExpandedProfile rules = fearRules;
attackMode: RpgLiteAttackMode ranged = true base = 'fixed' dice = 1 damageType = 'pi';
attackWeapon: RpgLiteWeapon id = 'test-pistol' modes = [attackMode] ammunition = 2 ready = true
    strikes = 0
    afterStrike(attacker,mode,result) { inherited(attacker,mode,result); self.strikes += 1; return nil; }
;
modify fearProfile equipment = [attackWeapon];
attackFighter: RpgLiteFighter profile = fearProfile weapon = attackWeapon;
attackOther: RpgLiteFighter profile = attackTarget;
attackBattle: RpgLiteBattle fighters = [attackFighter,attackOther];
attackWound: RpgExpandedWound id = 'panic-bullet' profile = attackTarget amount = 1;
attackDecision: RpgExpandedAdjudicatedStrike id = 'panic-shot' attacker = attackFighter defender = attackOther
    weapon = attackWeapon mode = attackMode attackScore = 12 attackRoll = 10 basicDamage = 1
    defenseKind = 'dodge' defenseScore = 8 defenseRoll = 10 wound = attackWound approved = true
    legalityEvidence = 'A single legal stationary shot at the visible target; no special attack options or counterattack'
    resolutionEvidence = 'The author records the externally rolled ordinary hit, failed dodge and one final torso injury after protection';
attackGate: RpgExpandedPanicActionGate id = 'panic-shot-permission' profile = fearProfile requiresMovement = true
    panicReaction = extremeFirst evidence = 'The actor must physically be able to fire';
attackManeuver: RpgExpandedPanicAttackManeuver target = attackOther strike = attackDecision
    healthGate = attackGate panicReaction = extremeFirst;
attackOperation: RpgExpandedPanicAttackOperation profile = fearProfile reaction = extremeFirst
    battle = attackBattle maneuver = attackManeuver;
modify extremeFirst kind = 'world-operation' operation = attackOperation;
modify FearTestAction
    exec(context)
    {
        local code = fearInput.code;
        if (code == 670) { attackBattle.active = true; attackBattle.order = [attackFighter,attackOther]; extremeEpisode.apply(); return nil; }
        if (code == 671)
        { local value = extremeFirst.assess(); event('test.panic-attack-preview'); eventValue(value.status); eventValue(value.reason); return nil; }
        if (code == 672)
        {
            event('test.panic-attack'); eventValue(attackTarget.injury); eventValue(attackWeapon.ammunition);
            eventValue(fearProfile.adjudicatedStrikes.length()); eventValue(fearProfile.effortHistory.length());
            eventValue(extremeEpisode.reactions.length()); eventValue(attackBattle.index);
            eventValue(attackBattle.seconds); eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws);
            eventValue(attackWeapon.strikes); return nil;
        }
        if (code == 673) { attackBattle.step(attackOther,new RpgLiteManeuver()); return nil; }
        if (code == 674) { attackDecision.attackRoll = 4; return nil; }
        if (code == 675) { attackDecision.attackRoll = 13; attackDecision.basicDamage = 0; attackDecision.defenseKind = nil;
            attackDecision.defenseScore = nil; attackDecision.defenseRoll = nil; attackDecision.wound = nil; return nil; }
        if (code == 676) { attackDecision.defenseRoll = 7; attackDecision.basicDamage = 0; attackDecision.wound = nil; return nil; }
        if (code == 677) { attackDecision.attackScore = 13; attackDecision.assess(); return nil; }
        if (code == 678) { attackWeapon.ammunition = 0; return nil; }
        if (code == 679) { fearProfile.stunned = true; return nil; }
        if (code == 680) { rpgSpendTime(1); return nil; }
        if (code == 681) { attackDecision.apply(nil); return nil; }
        if (code == 682) { attackDecision.defenseRoll = 3; return nil; }
        if (code == 683) { attackDecision.legalityEvidence = nil; return nil; }
        if (code == 684) { fearProfile.injury = fearProfile.maxHP; return nil; }
        if (code == 685) { event('test.panic-attack-incapacity'); eventValue(fearProfile.unconscious ? 1 : 0);
            eventValue(fearProfile.extremePanic == nil ? 0 : 1); return nil; }
        return inherited(context);
    }
;
