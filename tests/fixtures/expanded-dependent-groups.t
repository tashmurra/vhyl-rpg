#include "expanded-dependent-sessions.t"
dependentMemberOne: object;
dependentMemberTwo: object;
dependentRoster: RpgExpandedDependentRoster relationship = dependentRelationship members = [dependentMemberOne,dependentMemberTwo]
    approved = true evidence = 'Both pupils belong to the protected class this session';
dependentGroupSession: RpgExpandedDependentGroupSession profile = bleedProfile session = dependentSessionIdentity
    approved = true evidence = 'Every group member reviewed at session end' rosters = [dependentRoster];
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 14000)
        {
            bleedProfile.contributions = [dependentRelationship]; dependentRelationship.group = true;
            dependentGroupSession.outcomes = [[dependentRelationship,nil,nil,nil,nil,'No incidents for this group']];
            dependentGroupSession.memberOutcomes = [[dependentRoster,dependentMemberOne,nil,nil,nil,nil,'Safe'],
                [dependentRoster,dependentMemberTwo,nil,nil,nil,nil,'Safe']]; return nil;
        }
        if (code == 14001)
        {
            dependentGroupSession.outcomes = [[dependentRelationship,true,true,true,nil,'A member was seriously hurt despite rescue']];
            dependentGroupSession.memberOutcomes = [[dependentRoster,dependentMemberOne,true,true,true,nil,'Rescued but seriously hurt'],
                [dependentRoster,dependentMemberTwo,nil,nil,nil,nil,'Safe']]; return nil;
        }
        if (code == 14002)
        { dependentGroupSession.outcomes = [[dependentRelationship,nil,nil,nil,nil,'Incorrect safe summary']]; return nil; }
        if (code == 14003 || code == 14004)
        { dependentGroupSession.record(); if (code == 14004) throw new RpgError(); return nil; }
        if (code == 14005)
        {
            try { event('test.dependent-group-preview'); eventValue(dependentGroupSession.assess().status); }
            catch (RpgExpandedError error) { event('test.dependent-group-reject'); eventValue(error.reason); } return nil;
        }
        if (code == 14006)
        { dependentGroupSession.memberOutcomes = [[dependentRoster,dependentMemberOne,nil,nil,nil,nil,'Safe']]; return nil; }
        if (code == 14007) { dependentRoster.members = [dependentMemberOne]; return nil; }
        return inherited(context);
    }
;
