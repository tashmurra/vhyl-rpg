#include "expanded-panic-attack.t"
#include <vhyl-rpg-expanded-combat.t>
panicCritical: RpgExpandedRecordedCriticalHit owner = attackDecision location = 'torso' damageType = 'pi'
    rolledBasic = 2 maximumBasic = 6 dividedArmor = 3 approved = true
    evidence = 'Recorded critical table dice, basic damage dice and armor after ordinary divisors';
modify FearTestAction
    exec(context)
    {
        local code = fearInput.code;
        if (code == 780)
        {
            local row = fearInput.row; panicCritical.tableRoll = row;
            attackDecision.attackRoll = 3; attackDecision.defenseKind = nil;
            attackDecision.defenseScore = nil; attackDecision.defenseRoll = nil;
            attackDecision.criticalConsequence = panicCritical; attackWound.criticalHit = true;
            local damage = holds([3,18,6,15],row) ? 6 : holds([5,16],row) ? 4 : 2;
            local armor = holds([4,17],row) ? 1 : 3;
            panicCritical.penetratingDamage = damage > armor ? damage-armor : 0;
            attackDecision.basicDamage = damage; attackWound.amount = panicCritical.penetratingDamage;
            if (holds([7,13,14],row))
            {
                panicCritical.dividedArmor = 1; panicCritical.penetratingDamage = 1;
                attackWound.amount = 1; attackWound.forceMajorWound = true;
                panicDice.rolls = [18,3,18,7];
            }
            return nil;
        }
        if (code == 781)
        {
            event('test.panic-critical'); eventValue(attackTarget.injury); eventValue(attackWeapon.ammunition);
            eventValue(fearProfile.adjudicatedStrikes.length()); eventValue(attackTarget.expandedWounds.length());
            eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds);
            eventValue(attackDecision.result == nil ? nil : attackDecision.result.attack.critical); return nil;
        }
        if (code == 782) { panicCritical.tableRoll = 8; return nil; }
        if (code == 783) { attackDecision.defenseKind = 'dodge'; attackDecision.defenseScore = 8; attackDecision.defenseRoll = 10; return nil; }
        if (code == 784) { attackDecision.basicDamage += 1; return nil; }
        if (code == 785) { attackWound.forceMajorWound = true; return nil; }
        if (code == 786) { panicCritical.dividedArmor = 4; attackDecision.validateReceipt(); return nil; }
        if (code == 787) { panicCritical.approved = nil; return nil; }
        return inherited(context);
    }
;
