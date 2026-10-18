#include "expanded-fall-arm.t"
modify fallArm kind = 'leg';
modify fallHand kind = 'foot';
modify fallOtherArm kind = 'leg';
modify fallOtherHand kind = 'foot';
modify fallInjury location = 'leg' locationEvidence = 'The resolved random fall location selected this leg';
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 950)
        {
            event('test.fall-lower'); eventValue(bleedProfile.injury); eventValue(bleedProfile.posture);
            eventValue(fallArm.disabled ? 1 : 0); eventValue(fallHand.disabled ? 1 : 0);
            eventValue(fallOtherArm.disabled ? 1 : 0); eventValue(rpgRandom.draws);
            try { eventValue(bleedProfile.move()); }
            catch (RpgExpandedError error) { eventValue(error.reason); }
            return nil;
        }
        if (code == 951) { fallInjury.location = 'foot'; fallInjury.bodyPart = fallHand; return nil; }
        if (code == 952)
        {
            event('test.lower-posture'); eventValue(bleedProfile.postureChangeReason('standing'));
            eventValue(bleedProfile.postureChangeReason('kneeling'));
            eventValue(bleedProfile.postureChangeReason('sitting')); return nil;
        }
        return inherited(context);
    }
;
