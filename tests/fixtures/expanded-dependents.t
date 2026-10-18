#include "expanded-fixed-beliefs.t"
dependentPerson: object;
dependentAdventure: object;
dependentRelationship: RpgExpandedDependent id = 'ward' owner = bleedProfile dependent = dependentPerson principalPoints = 200
    dependentPoints = 50 importance = 'friend' frequency = 12 approved = true evidence = 'Author-approved character totals and protective responsibility';
dependentAppearance: RpgExpandedDependentAppearance relationship = dependentRelationship adventure = dependentAdventure
    approved = true evidence = 'The adventure is beginning; determine the dependent role once';
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 13400) { bleedProfile.contributions = [dependentRelationship]; return nil; }
        if (code == 13401)
        {
            event('test.dependent-prices');
            foreach (local points in [-1,0,50,51,100,101,150,151,200]) eventValue(rpgExpandedDependentBase(200,points));
            eventValue(rpgExpandedDependentCost(200,50,'friend',12,nil));
            eventValue(rpgExpandedDependentCost(200,50,'friend',12,true));
            eventValue(rpgExpandedDependentCost(200,150,'loved-one',6,nil));
            eventValue(rpgExpandedDependentCost(200,50,'acquaintance',6,nil));
            eventValue(rpgExpandedDependentCost(200,50,'acquaintance',6,true)); return nil;
        }
        if (code == 13402)
        { event('test.dependent-preview'); eventValue(dependentAppearance.assess().status); eventValue(rpgRandom.draws); return nil; }
        if (code == 13403 || code == 13404)
        { dependentAppearance.resolve(); if (code == 13404) throw new RpgError(); return nil; }
        if (code == 13405)
        {
            event('test.dependent-state'); eventValue(bleedProfile.dependentAppearances.length());
            eventValue(dependentAppearance.result == nil ? nil : dependentAppearance.result.roll);
            eventValue(dependentAppearance.result == nil ? nil : (dependentAppearance.result.appeared ? 1 : 0));
            eventValue(rpgRandom.draws); eventValue(rpgExpandedCharacterCost(bleedProfile,nil)); return nil;
        }
        if (code == 13406) { bleedInput.forcedRoll = 13; return nil; }
        if (code == 13407) { dependentRelationship.frequency = 0; dependentRelationship.constantAttachment = 'supernatural'; return nil; }
        return inherited(context);
    }
;
