#include "expanded-dependent-loss.t"
dependentTraitReplacement: RpgExpandedDependentTraitReplacement loss = dependentLoss trait = beliefOne
    approved = true evidence = 'The loss produced this specific belief and behavior';
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 14400)
        {
            bleedProfile.contributions = [dependentRelationship]; dependentRelationship.frequency = 9;
            bleedProfile.earnedPoints = 25; bleedProfile.unspentPoints = 25;
            dependentLoss.originalBonus = 10; dependentLoss.bonusEvidence = 'Ten-point original credit'; dependentLoss.record(); return nil;
        }
        if (code == 14401)
        { local value = dependentTraitReplacement.assess(); event('test.dependent-trait-preview'); eventValue(value.status); eventValue(value.reason); eventValue(value.points); return nil; }
        if (code == 14402 || code == 14403)
        { dependentTraitReplacement.apply(); if (code == 14403) throw new RpgError(); return nil; }
        if (code == 14404)
        {
            event('test.dependent-trait-state'); eventValue(bleedProfile.dependentLossSettlements.length());
            eventValue(bleedProfile.traits.length()); eventValue(rpgExpandedCharacterCost(bleedProfile,nil));
            eventValue(bleedProfile.earnedPoints); eventValue(bleedProfile.unspentPoints);
            eventValue(bleedProfile.disadvantageBuyoffCost(beliefOne)); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 14405) { bleedProfile.developmentOpen = true; rpgLiteBuyOff(bleedProfile,beliefOne); return nil; }
        if (code == 14406)
        {
            beliefOne.level = 1;
            try { dependentTraitReplacement.assess(); }
            catch (RpgExpandedError error) { event('test.dependent-trait-reject'); eventValue(error.reason); } return nil;
        }
        if (code == 14407) { dependentTraitReplacement.approved = nil; return nil; }
        return inherited(context);
    }
;
