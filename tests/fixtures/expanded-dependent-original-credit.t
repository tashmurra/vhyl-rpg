#include "expanded-dependent-loss.t"
dependentFinalization: RpgExpandedCharacterFinalization id = 'initial-build' profile = bleedProfile approved = true
    evidence = 'Initial character accounting approved';
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 14200)
        {
            bleedProfile.contributions = [dependentRelationship]; bleedProfile.earnedPoints = 25; bleedProfile.unspentPoints = 25;
            dependentLoss.originalBonus = nil; dependentLoss.bonusEvidence = nil; return nil;
        }
        if (code == 14201 || code == 14202)
        { dependentFinalization.apply(); if (code == 14202) throw new RpgError(); return nil; }
        if (code == 14203)
        {
            event('test.dependent-original-credit'); eventValue(bleedProfile.creationComplete ? 1 : 0);
            eventValue(bleedProfile.contributionBuyoffBases.length()); eventValue(bleedProfile.originalContributionBonus(dependentRelationship));
            eventValue(rpgRandom.draws); return nil;
        }
        if (code == 14204) { dependentRelationship.importance = 'loved-one'; return nil; }
        if (code == 14205)
        {
            dependentLoss.originalBonus = 40;
            try { dependentLoss.assess(); }
            catch (RpgExpandedError error) { event('test.dependent-original-reject'); eventValue(error.reason); } return nil;
        }
        if (code == 14206)
        {
            bleedProfile.contributionBuyoffBases[1].originalBonus = 21;
            try { bleedProfile.originalContributionBonus(dependentRelationship); }
            catch (RpgExpandedError error) { event('test.dependent-original-reject'); eventValue(error.reason); } return nil;
        }
        if (code == 14207) { dependentRelationship.credited = nil; return nil; }
        return inherited(context);
    }
;
