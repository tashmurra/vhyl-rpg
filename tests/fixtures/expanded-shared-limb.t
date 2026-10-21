#include "expanded-shared-release.t"
carryLeftArm: RpgExpandedBodyPart id = 'left-arm' profile = carryPartner;
carryRightArm: RpgExpandedBodyPart id = 'right-arm' profile = carryPartner;
carryLeftHand: RpgExpandedBodyPart id = 'left-hand' kind = 'hand' parent = carryLeftArm profile = carryPartner;
carryRightHand: RpgExpandedBodyPart id = 'right-hand' kind = 'hand' parent = carryRightArm profile = carryPartner;
modify carryPartner bodyParts = [carryLeftArm,carryRightArm,carryLeftHand,carryRightHand];
modify sharedCarry members = [[bleedProfile,2000,2,[]],[carryPartner,4000,2,[carryLeftHand,carryRightHand]]];
modify sharedRelease cause = 'disabled-support';
carryLimbWound: RpgExpandedWound id = 'support-injury' profile = carryPartner amount = 4 location = 'hand'
    bodyPart = carryLeftHand dropDestination = bleedRoom;
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 810 || code == 811)
        { carryLimbWound.apply(); if (code == 811) throw new RpgError(); return nil; }
        if (code == 812)
        {
            event('test.shared-limb'); eventValue(carryPartner.injury);
            eventValue(carryLeftHand.disabled ? 1 : 0); eventValue(carryLeftArm.disabled ? 1 : 0);
            eventValue(sharedCarry.supportLosses.length()); eventValue(sharedCarry.pendingSupportLoss() ? 1 : 0);
            eventValue(carryPartner.expandedWounds.length()); eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 813)
        { carryLimbWound.location = 'arm'; carryLimbWound.bodyPart = carryLeftArm; carryLimbWound.amount = 6; return nil; }
        if (code == 814) { carryLimbWound.bodyPart = carryRightHand; return nil; }
        if (code == 815)
        { sharedCarry.mode = 'one-hand'; sharedCarry.members = [[bleedProfile,2000,1,[]],[carryPartner,4000,1,[carryLeftHand]]]; return nil; }
        if (code == 816) { bleedInput.forcedRoll = 17; return nil; }
        return inherited(context);
    }
;
