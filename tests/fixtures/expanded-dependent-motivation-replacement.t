#include "expanded-dependent-trait-replacement.t"
lossMotivation: RpgExpandedLowMotivation approved = true selfControlRating = 12;
lossMotivationOccurrence: object;
lossMotivationTrigger: RpgExpandedMotivationTrigger id = 'after-loss-choice' profile = bleedProfile trait = lossMotivation
    trigger = lossMotivationOccurrence choices = ['rest','investigate'] leastEffort = 'rest' approved = true
    evidence = 'Both options are available; resting is the least demanding choice';
lossMotivationDecision: RpgExpandedMotivationDecision source = lossMotivationTrigger choice = 'investigate';
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 14500)
        {
            bleedProfile.contributions = [dependentRelationship]; dependentRelationship.dependentPoints = 100; dependentRelationship.frequency = 15;
            bleedProfile.earnedPoints = 25; bleedProfile.unspentPoints = 25;
            dependentLoss.originalBonus = 15; dependentLoss.bonusEvidence = 'Fifteen-point creation record'; dependentLoss.record();
            dependentTraitReplacement.trait = lossMotivation; return nil;
        }
        if (code == 14501)
        {
            bleedInput.forcedRoll = 13; lossMotivationTrigger.resolve();
            local value = lossMotivationDecision.apply(); event('test.loss-motivation-decision'); eventValue(value.status); eventValue(value.reason); return nil;
        }
        if (code == 14502)
        {
            lossMotivationDecision.choice = 'rest'; local value = lossMotivationDecision.apply();
            event('test.loss-motivation-decision'); eventValue(value.status); eventValue(value.reason); return nil;
        }
        if (code == 14503)
        {
            event('test.loss-motivation-state'); eventValue(bleedProfile.traits.length()); eventValue(rpgExpandedCharacterCost(bleedProfile,nil));
            eventValue(bleedProfile.unspentPoints); eventValue(bleedProfile.disadvantageBuyoffCost(lossMotivation));
            eventValue(rpgRandom.draws); eventValue(bleedProfile.selfControlTriggers.length()); return nil;
        }
        if (code == 14504) { bleedProfile.developmentOpen = true; rpgLiteBuyOff(bleedProfile,lossMotivation); return nil; }
        if (code == 14505)
        {
            lossMotivation.selfControlRating = 6;
            try { dependentTraitReplacement.assess(); }
            catch (RpgExpandedError error) { event('test.loss-motivation-reject'); eventValue(error.reason); } return nil;
        }
        return inherited(context);
    }
;
