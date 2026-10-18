#include "expanded-mortal-stabilization.t"
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 210)
        {
            bleedProfile.unconscious = nil; mortalRollInput.rolls = [10,18];
            rpgLiteHeal(bleedProfile,1); return nil;
        }
        if (code == 211) { mortalRollInput.rolls = [3,11]; rpgSpendTime(3600); return nil; }
        if (code == 212)
        {
            local receipt = bleedProfile.mortalRecoveryHistory[1];
            event('test.mortal-recovery'); eventValue(bleedProfile.mortalRecoveryHistory.length());
            eventValue(receipt.cause); eventValue(receipt.completedAt); eventValue(receipt.healthBefore); eventValue(receipt.healthAfter);
            eventValue(bleedProfile.ht); eventValue(bleedProfile.developmentRevision); eventValue(bleedProfile.earnedPoints);
            eventValue(bleedProfile.unspentPoints); eventValue(receipt.additionalConsequence); return nil;
        }
        if (code == 213)
        {
            bleedProfile.mortalRecoveryHistory[1].declineAdditionalConsequence(true,'Author elects no additional consequence'); return nil;
        }
        return inherited(context);
    }
;
