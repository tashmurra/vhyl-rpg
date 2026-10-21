#include "expanded-thrown-injury.t"
impactArm: RpgExpandedBodyPart id = 'impact-arm' kind = 'arm' profile = catchProfile;
impactHand: RpgExpandedBodyPart id = 'impact-hand' kind = 'hand' parent = impactArm profile = catchProfile;
impactLeg: RpgExpandedBodyPart id = 'impact-leg' kind = 'leg' profile = catchProfile;
impactFoot: RpgExpandedBodyPart id = 'impact-foot' kind = 'foot' parent = impactLeg profile = catchProfile;
impactTool: RpgLiteItem id = 'target-tool' weight = 100 ready = true bodySupports = [impactHand];
modify catchProfile bodyParts = [impactArm,impactHand,impactLeg,impactFoot] equipment = [impactTool];
modify heldThrow hitLocation = 'arm' locationPart = impactArm locationEvidence = 'The attack selects this body part before rolling';
modify throwInjury location = 'arm';
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 1250) { bleedInput.forcedRoll = 7; return nil; }
        if (code == 1251) { heldThrow.hitLocation = 'hand'; heldThrow.locationPart = impactHand; throwInjury.location = 'hand'; return nil; }
        if (code == 1253) { heldThrow.hitLocation = 'leg'; heldThrow.locationPart = impactLeg; throwInjury.location = 'leg'; return nil; }
        if (code == 1254) { heldThrow.hitLocation = 'foot'; heldThrow.locationPart = impactFoot; throwInjury.location = 'foot'; return nil; }
        if (code == 1255) { thrownDamage.damageType = 'imp'; thrownDamage.shapeEvidence = 'A pointed ordinary object'; return nil; }
        if (code == 1256) { thrownDamage.damageType = 'cut'; thrownDamage.shapeEvidence = 'A cutting ordinary object'; return nil; }
        if (code == 1257) { heldThrow.shieldAtLocation = true; return nil; }
        if (code == 1258)
        {
            event('test.thrown-limb'); eventValue(catchProfile.injury);
            eventValue(impactArm.disabled ? 1 : 0); eventValue(impactHand.disabled ? 1 : 0);
            eventValue(impactLeg.disabled ? 1 : 0); eventValue(impactFoot.disabled ? 1 : 0);
            eventValue(heldThrow.locationPart.severed ? 1 : 0);
            eventValue(impactTool.storageLocation == bleedRoom ? 1 : 0); eventValue(rpgRandom.draws);
            eventValue(catchProfile.posture); return nil;
        }
        return inherited(context);
    }
;
