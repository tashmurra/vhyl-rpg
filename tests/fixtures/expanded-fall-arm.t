#include "expanded-fall-hand.t"
fallOtherArm: RpgExpandedBodyPart id = 'other-arm' kind = 'arm' profile = bleedProfile;
fallOtherHand: RpgExpandedBodyPart id = 'other-hand' kind = 'hand' profile = bleedProfile parent = fallOtherArm;
modify bleedProfile bodyParts = [fallArm,fallHand,fallOtherArm,fallOtherHand];
modify fallInjury location = 'arm' bodyPart = fallArm
    locationEvidence = 'The already resolved random fall location selected this arm';
fallArmInput: object die = 5;
modify rpgRandom
    die() { self.draws += 1; return fallArmInput.die; }
;
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 930)
        {
            event('test.fall-arm'); eventValue(bleedProfile.injury); eventValue(fallArm.disabled ? 1 : 0);
            eventValue(fallOtherArm.disabled ? 1 : 0); eventValue(bleedProfile.expandedWounds.length());
            eventValue(bleedProfile.fallInjuries.length()); eventValue(rpgRandom.draws);
            if (fallInjury.result != nil) eventValue(fallInjury.result.wound.additionalRoll);
            return nil;
        }
        if (code == 931) { fallArmInput.die = 4; return nil; }
        return inherited(context);
    }
;
