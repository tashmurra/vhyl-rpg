#include "expanded-fall-lower.t"
lowerLeftArm: RpgExpandedBodyPart id = 'left-arm' kind = 'arm' profile = bleedProfile;
lowerLeftHand: RpgExpandedBodyPart id = 'left-hand' kind = 'hand' profile = bleedProfile parent = lowerLeftArm;
lowerRightArm: RpgExpandedBodyPart id = 'right-arm' kind = 'arm' profile = bleedProfile;
lowerRightHand: RpgExpandedBodyPart id = 'right-hand' kind = 'hand' profile = bleedProfile parent = lowerRightArm;
modify bleedProfile bodyParts = [fallArm,fallHand,fallOtherArm,fallOtherHand,lowerLeftArm,lowerLeftHand,lowerRightArm,lowerRightHand]
    skills = [lowerTraining];
lowerSkill: RpgLiteSkill id = 'balance-task' attribute = rpgDX difficulty = 1 usesLegs = true;
lowerTraining: RpgTraining skill = lowerSkill points = 4;
modify BleedTestAction
    exec(context)
    {
        if (bleedInput.code == 960)
        {
            local checkContext = new RpgLiteContext(); checkContext.attribute = rpgDX; checkContext.kind = 'defense';
            event('test.lower-skills'); eventValue(bleedProfile.legUsePenalty());
            checkContext.legUse = 'required'; eventValue(rpgLiteScore(bleedProfile,checkContext));
            checkContext.legUse = 'none'; eventValue(rpgLiteScore(bleedProfile,checkContext));
            checkContext.legUse = 'auto'; checkContext.skill = lowerSkill; eventValue(rpgLiteScore(bleedProfile,checkContext));
            local defender = new RpgLiteFighter(); defender.profile = bleedProfile;
            local attacker = new RpgLiteFighter(); attacker.profile = new RpgLiteProfile();
            local weapon = new RpgLiteWeapon(); weapon.id = 'punch';
            local mode = new RpgLiteAttackMode(); mode.base = 'thrust'; weapon.modes = [mode]; attacker.weapon = weapon;
            eventValue(rpgLiteDefenseScore(defender,attacker,new RpgLiteManeuver(),'parry'));
            eventValue(rpgRandom.draws); return nil;
        }
        return inherited(context);
    }
;
