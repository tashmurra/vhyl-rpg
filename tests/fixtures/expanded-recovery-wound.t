#include "expanded-mortal-recovery.t"
#include <vhyl-rpg-expanded-traits.t>
recoveryWoundTrait: RpgExpandedPersistentWound approved = true;
recoveryWoundAcquisition: RpgExpandedRecoveryWoundAcquisition trait = recoveryWoundTrait approved = true
    location = 'left shoulder' evidence = 'Author selects a persistent opening at the recovered injury site';
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 220)
        { bleedProfile.creationComplete = true; recoveryWoundAcquisition.recovery = bleedProfile.mortalRecoveryHistory[1]; return nil; }
        if (code == 221) { recoveryWoundAcquisition.assess(); return nil; }
        if (code == 222 || code == 223)
        { recoveryWoundAcquisition.apply(); if (code == 223) throw new RpgError(); return nil; }
        if (code == 224)
        {
            event('test.recovery-wound'); eventValue(bleedProfile.level('persistent-wound'));
            eventValue(bleedProfile.injury); eventValue(bleedProfile.ht); eventValue(bleedProfile.developmentRevision);
            eventValue(bleedProfile.postCreationDisadvantageAllowance()); eventValue(bleedProfile.earnedPoints);
            eventValue(bleedProfile.unspentPoints); eventValue(bleedProfile.recoveryWoundAcquisitions.length()); return nil;
        }
        if (code == 225)
        {
            local value = rpgExpandedAssessPersistentWound(true,true,nil,true);
            event('test.persistent-wound'); eventValue(recoveryWoundTrait.creationCost()); eventValue(value.targetModifier);
            eventValue(value.woundingNumerator); eventValue(value.woundingDenominator);
            eventValue(value.bloodAgentEntry ? 1 : 0); eventValue(value.infectionModifier); return nil;
        }
        if (code == 226) { recoveryWoundAcquisition.approved = nil; return nil; }
        if (code == 227) { surgicalHealer.traits = [recoveryWoundTrait]; return nil; }
        return inherited(context);
    }
;
