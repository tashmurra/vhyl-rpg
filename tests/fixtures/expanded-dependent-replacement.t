#include "expanded-dependent-loss.t"
dependentReplacementPerson: object;
dependentReplacementPurchase: RpgExpandedDependent id = 'new-ward' owner = bleedProfile dependent = dependentReplacementPerson
    principalPoints = 200 dependentPoints = 50 importance = 'friend' frequency = 12 approved = true evidence = 'Approved new responsibility';
dependentReplacement: RpgExpandedDependentReplacement loss = dependentLoss replacement = dependentReplacementPurchase
    approved = true evidence = 'The campaign established a new responsibility after the loss';
dependentReplacementLossSession: object;
dependentReplacementLoss: RpgExpandedDependentLoss relationship = dependentReplacementPurchase session = dependentReplacementLossSession
    disposition = 'dead' approved = true evidence = 'Later permanent loss';
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 14301)
        { local value = dependentReplacement.assess(); event('test.dependent-replacement-preview'); eventValue(value.status); eventValue(value.reason); eventValue(value.points); return nil; }
        if (code == 14302 || code == 14303)
        { dependentReplacement.apply(); if (code == 14303) throw new RpgError(); return nil; }
        if (code == 14304)
        {
            event('test.dependent-replacement-state'); eventValue(bleedProfile.contributions.length());
            eventValue(bleedProfile.dependentLossSettlements.length()); eventValue(rpgExpandedCharacterCost(bleedProfile,nil));
            eventValue(bleedProfile.earnedPoints); eventValue(bleedProfile.unspentPoints); eventValue(bleedProfile.developmentRevision);
            eventValue(bleedProfile.originalContributionBonus(dependentReplacementPurchase)); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 14305)
        { event('test.dependent-replacement-old-session'); eventValue(dependentSession.assess().status); return nil; }
        if (code == 14306)
        { local value = dependentReplacementLoss.assess(); event('test.dependent-replacement-next-loss'); eventValue(value.status); eventValue(value.points); return nil; }
        if (code == 14307 || code == 14308)
        {
            if (code == 14307) dependentReplacementPurchase.frequency = 9;
            else dependentReplacementPurchase.dependent = dependentPerson;
            try { dependentReplacement.assess(); }
            catch (RpgExpandedError error) { event('test.dependent-replacement-reject'); eventValue(error.reason); } return nil;
        }
        if (code == 14309) { dependentReplacement.approved = nil; return nil; }
        return inherited(context);
    }
;
