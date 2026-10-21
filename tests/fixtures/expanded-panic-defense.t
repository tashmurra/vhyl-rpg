#include "expanded-panic-attack.t"
#include <vhyl-rpg-expanded-combat.t>
panicShield: RpgLiteItem id = 'shield' db = 1 ready = true worn = true;
panicDefenseFailure: RpgExpandedDefenseFailure id = 'panic-defense-failure' fighter = attackOther kind = 'dodge'
    score = 8 roll = 18 evidence = 'The recorded defense critically failed during this attack';
panicDefenseConsequence: RpgExpandedStrikeDefenseFailure owner = attackDecision failure = panicDefenseFailure;
modify attackTarget
    requiresTacticalFall = nil
    jumpPositionRequired() { return self.requiresTacticalFall; }
;
modify FearTestAction
    exec(context)
    {
        local code = fearInput.code;
        if (code == 760 || code == 761)
        {
            attackWeapon.id = 'test-bow'; attackMode.base = 'thrust'; attackMode.damageType = 'imp';
            attackDecision.defenseRoll = 18; attackDecision.defenseConsequence = panicDefenseConsequence;
            attackTarget.equipment = [panicShield]; attackOther.shield = panicShield;
            if (code == 761) { attackDecision.defenseKind = 'block'; panicDefenseFailure.kind = 'block'; }
            return nil;
        }
        if (code == 762)
        {
            event('test.panic-defense'); eventValue(attackTarget.posture); eventValue(panicShield.ready ? 1 : 0);
            eventValue(attackTarget.criticalDefenseFailures.length()); eventValue(attackTarget.injury);
            eventValue(attackWeapon.ammunition); eventValue(fearProfile.adjudicatedStrikes.length());
            eventValue(rpgRandom.draws); eventValue(attackDecision.committingDefense ? 1 : 0); return nil;
        }
        if (code == 763) { panicDefenseConsequence.apply(attackDecision); return nil; }
        if (code == 764) { panicDefenseFailure.roll = 17; attackDecision.validateReceipt(); return nil; }
        if (code == 765) { panicDefenseFailure.result.check.achieved = true; attackDecision.validateReceipt(); return nil; }
        if (code == 766) { panicDefenseFailure.score = 9; return nil; }
        if (code == 767) { panicDefenseFailure.mobility = 'flight'; return nil; }
        if (code == 769) { attackTarget.requiresTacticalFall = true; return nil; }
        if (code == 768) { attackDecision.defenseConsequence = nil; return nil; }
        return inherited(context);
    }
;
