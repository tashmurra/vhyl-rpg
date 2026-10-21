#include "expanded-dependent-sessions.t"
dependentLoss: RpgExpandedDependentLoss relationship = dependentRelationship session = dependentSessionIdentity disposition = 'dead' originalBonus = 20
    approved = true evidence = 'Confirmed permanent loss during the session' bonusEvidence = 'Creation record credited twenty points';
dependentLossBuyoff: RpgExpandedDependentLossBuyoff loss = dependentLoss;
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 14100)
        {
            bleedProfile.contributions = [dependentRelationship]; bleedProfile.earnedPoints = 25; bleedProfile.unspentPoints = 25;
            dependentSession.outcomes = [[dependentRelationship,true,true,true,nil,'Fatal injury despite rescue']];
            dependentSession.record(); return nil;
        }
        if (code == 14101) { dependentLoss.record(); return nil; }
        if (code == 14102)
        { local value = dependentLossBuyoff.assess(); event('test.dependent-loss-preview'); eventValue(value.status); eventValue(value.reason); eventValue(value.points); return nil; }
        if (code == 14103 || code == 14104)
        { dependentLossBuyoff.apply(); if (code == 14104) throw new RpgError(); return nil; }
        if (code == 14105)
        {
            event('test.dependent-loss-state'); eventValue(bleedProfile.dependentLosses.length());
            eventValue(bleedProfile.dependentLossSettlements.length()); eventValue(rpgExpandedCharacterCost(bleedProfile,nil));
            eventValue(bleedProfile.earnedPoints); eventValue(bleedProfile.unspentPoints); eventValue(bleedProfile.developmentRevision);
            eventValue(rpgRandom.draws); return nil;
        }
        if (code == 14106) { bleedProfile.unspentPoints = 19; return nil; }
        if (code == 14107)
        { event('test.dependent-loss-appearance'); eventValue(dependentAppearance.assess().reason); return nil; }
        if (code == 14108)
        {
            dependentRelationship.group = true;
            try { dependentLoss.assess(); }
            catch (RpgExpandedError error) { event('test.dependent-loss-reject'); eventValue(error.reason); } return nil;
        }
        return inherited(context);
    }
;
