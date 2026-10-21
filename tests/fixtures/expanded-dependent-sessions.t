#include "expanded-dependents.t"
dependentSessionIdentity: object;
dependentSession: RpgExpandedDependentSession profile = bleedProfile session = dependentSessionIdentity
    approved = true evidence = 'Session ended; all dependent outcomes reviewed';
dependentSessionMilestone: RpgMilestone id = 'session-objective' points = 3 awardSession = dependentSessionIdentity;
dependentSessionAward: RpgAward profile = bleedProfile milestone = dependentSessionMilestone;
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 13500)
        {
            bleedProfile.contributions = [dependentRelationship];
            dependentSession.outcomes = [[dependentRelationship,nil,nil,nil,nil,'No peril or harm this session']]; return nil;
        }
        if (code == 13501)
        { dependentSession.outcomes = [[dependentRelationship,true,nil,true,nil,'Seriously injured during the session']]; return nil; }
        if (code == 13502)
        { dependentSession.outcomes = [[dependentRelationship,true,nil,nil,true,'Rescue was possible but deliberately refused; bonus denied']]; return nil; }
        if (code == 13503) { dependentSessionMilestone.bonusAward = true; return nil; }
        if (code == 13504)
        { event('test.dependent-session-preview'); eventValue(dependentSession.assess().status); eventValue(rpgRandom.draws); return nil; }
        if (code == 13505 || code == 13506)
        { dependentSession.record(); if (code == 13506) throw new RpgError(); return nil; }
        if (code == 13507 || code == 13508)
        {
            local value = rpgAwardMilestone(bleedProfile,dependentSessionMilestone);
            event('test.dependent-session-award'); eventValue(value.status); eventValue(value.reason);
            if (code == 13508) throw new RpgError(); return nil;
        }
        if (code == 13509)
        {
            event('test.dependent-session-state'); eventValue(bleedProfile.dependentSessions.length());
            eventValue(bleedProfile.earnedPoints); eventValue(bleedProfile.unspentPoints);
            eventValue(dependentSessionAward.claimed ? 1 : 0); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 13510)
        {
            dependentSession.outcomes = [[dependentRelationship,nil,nil,nil,nil,'Changed adjudication']];
            try { dependentSession.assess(); }
            catch (RpgExpandedError error) { event('test.dependent-session-binding'); eventValue(error.reason); }
            return nil;
        }
        return inherited(context);
    }
;
