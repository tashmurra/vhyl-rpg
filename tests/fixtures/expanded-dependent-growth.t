#include "expanded-dependents.t"
dependentGrowth: RpgExpandedDependentGrowth id = 'first-growth' relationship = dependentRelationship
    newPrincipalPoints = 240 newDependentPoints = 60 approved = true evidence = 'Approved totals following principal advancement'
    improvements = [['skills',6,'Approved additional study'],['characteristics',4,'Approved physical improvement']];
dependentGrowthNext: RpgExpandedDependentGrowth id = 'second-growth' relationship = dependentRelationship previous = dependentGrowth
    newPrincipalPoints = 280 newDependentPoints = 70 approved = true evidence = 'Next approved advancement totals'
    improvements = [['education',10,'Further approved education']];
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 13800)
        {
            bleedProfile.contributions = [dependentRelationship];
            event('test.dependent-growth-total');
            eventValue(rpgExpandedDependentGrowthTotal(200,50,240));
            eventValue(rpgExpandedDependentGrowthTotal(200,150,1000000));
            eventValue(rpgExpandedDependentGrowthTotal(1000000,1000000,1000000)); return nil;
        }
        if (code == 13801)
        { event('test.dependent-growth-preview'); eventValue(dependentGrowth.assess().status); eventValue(rpgRandom.draws); return nil; }
        if (code == 13802 || code == 13803)
        { dependentGrowth.record(); if (code == 13803) throw new RpgError(); return nil; }
        if (code == 13804)
        {
            event('test.dependent-growth-state'); eventValue(dependentRelationship.growthHistory.length());
            eventValue(rpgExpandedCharacterCost(bleedProfile,nil)); eventValue(bleedProfile.earnedPoints);
            eventValue(bleedProfile.unspentPoints); eventValue(rpgRandom.draws);
            eventValue(dependentRelationship.principalPoints); eventValue(dependentRelationship.dependentPoints); return nil;
        }
        if (code == 13805) { dependentGrowthNext.record(); return nil; }
        if (code >= 13806 && code <= 13809)
        {
            if (code == 13806) dependentGrowth.newPrincipalPoints = 201;
            if (code == 13807) dependentGrowth.newDependentPoints = 61;
            if (code == 13808) dependentGrowth.improvements = [['skills',9,'Incorrect total']];
            if (code == 13809) dependentGrowth.evidence = 'Changed recorded facts';
            try { dependentGrowth.assess(); }
            catch (RpgExpandedError error) { event('test.dependent-growth-reject'); eventValue(error.reason); }
            return nil;
        }
        return inherited(context);
    }
;
