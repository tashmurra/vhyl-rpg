#include "expanded-bleeding.t"
#include <vhyl-rpg-expanded-exploration.t>
#include <vhyl-rpg-expanded-equipment.t>
throwLeftArm: RpgExpandedBodyPart id = 'left-arm' kind = 'arm' profile = bleedProfile;
throwLeftHand: RpgExpandedBodyPart id = 'left-hand' kind = 'hand' parent = throwLeftArm profile = bleedProfile;
throwRightArm: RpgExpandedBodyPart id = 'right-arm' kind = 'arm' profile = bleedProfile;
throwRightHand: RpgExpandedBodyPart id = 'right-hand' kind = 'hand' parent = throwRightArm profile = bleedProfile;
throwStone: RpgLiteItem id = 'stone' weight = 100 ready = true bodySupports = [throwLeftHand];
throwOther: RpgLiteItem id = 'held-tool' weight = 100 ready = true bodySupports = [throwLeftHand];
heldThrowSkill: RpgLiteSkill id = 'throwing' attribute = rpgDX difficulty = 1 defaultPenalty = -3;
heldThrowTraining: RpgTraining skill = heldThrowSkill points = 4;
modify bleedProfile skills = [heldThrowTraining] equipment = [throwStone]
    bodyParts = [throwLeftArm,throwLeftHand,throwRightArm,throwRightHand];
heldThrow: RpgExpandedHeldThrow profile = bleedProfile item = throwStone skill = heldThrowSkill
    palmSized = true approved = true evidence = 'A single smooth stone is held for an ordinary throw at a visible target';
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 1150)
        {
            local value = heldThrow.assess(); event('test.held-throw'); eventValue(value.status); eventValue(value.reason);
            eventValue(value.score); eventValue(value.distanceHundredths); eventValue(value.handsRequired);
            eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 1151) { heldThrowTraining.points = 0; return nil; }
        if (code == 1152) { heldThrow.target = 'area'; return nil; }
        if (code == 1153) { throwStone.ready = nil; return nil; }
        if (code == 1154) { throwStone.weight = 5000; return nil; }
        if (code == 1155) { throwStone.bodySupports = [throwLeftHand,throwRightHand]; return nil; }
        if (code == 1156) { throwLeftHand.disabled = true; return nil; }
        if (code == 1157) { bleedProfile.equipment = [throwStone,throwOther]; return nil; }
        if (code == 1158) { throwStone.storageLocation = bleedRoom; return nil; }
        if (code == 1159) { bleedProfile.shock = 2; return nil; }
        if (code == 1160) { heldThrow.offHand = true; return nil; }
        if (code == 1161) { heldThrow.palmSized = nil; return nil; }
        if (code == 1162) { bleedProfile.fatigue = 7; return nil; }
        if (code == 1163) { throwOther.bodySupports = []; return nil; }
        return inherited(context);
    }
;
