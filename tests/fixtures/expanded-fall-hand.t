#include "expanded-fall-injury.t"
fallArm: RpgExpandedBodyPart id = 'arm' kind = 'arm' profile = bleedProfile;
fallHand: RpgExpandedBodyPart id = 'hand' kind = 'hand' profile = bleedProfile parent = fallArm;
modify bleedProfile bodyParts = [fallArm,fallHand];
modify fallInjury location = 'hand' bodyPart = fallHand damage = 20 resistance = 10
    locationEvidence = 'The already resolved random fall location selected this hand';
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 920)
        {
            event('test.fall-hand'); eventValue(bleedProfile.injury); eventValue(fallHand.disabled ? 1 : 0);
            eventValue(fallArm.disabled ? 1 : 0); eventValue(bleedProfile.expandedWounds.length());
            eventValue(bleedProfile.fallInjuries.length()); eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
        }
        if (code == 921) { fallInjury.locationEvidence = nil; return nil; }
        if (code == 922) { fallInjury.damage = 13; return nil; }
        return inherited(context);
    }
;
