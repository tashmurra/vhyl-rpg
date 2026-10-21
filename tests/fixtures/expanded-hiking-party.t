#include "expanded-hiking-attempt.t"
hikingPartnerAttempt: RpgExpandedHikingAttempt id = 'partner-walk'
    members = [[hikingPartner,hikingSkill,0,nil]] approved = true evidence = 'The partner makes an independent daily attempt';
hikingParty: RpgExpandedHikingParty id = 'two-travelers' attempts = [hikingAttempt,hikingPartnerAttempt]
    evidence = 'Both travelers choose to follow the trail together';
hikingOtherParty: RpgExpandedHikingParty id = 'rejoined-travelers' attempts = [hikingPartnerAttempt,hikingAttempt]
    evidence = 'The same travelers regroup using their existing rolls';
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 1120) { hikingPartnerAttempt.resolve(); return nil; }
        if (code == 1121)
        {
            local value = hikingParty.assess(); event('test.hiking-party-preview');
            eventValue(value.status); eventValue(value.reason); eventValue(value.bonusAchieved ? 1 : 0);
            eventValue(rpgRandom.draws); return nil;
        }
        if (code == 1122 || code == 1123)
        { hikingParty.resolve(); if (code == 1123) throw new RpgError(); return nil; }
        if (code == 1124)
        {
            event('test.hiking-party-owned'); eventValue(bleedProfile.hikingParties.length());
            eventValue(hikingPartner.hikingParties.length()); eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds);
            eventValue(hikingParty.result != nil && hikingParty.result.bonusAchieved ? 1 : 0); return nil;
        }
        if (code == 1125)
        {
            local value = hikingParty.assessPace(hikingConditions,[100,100]);
            event('test.hiking-party-pace'); eventValue(value.milesHundredths); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 1126) { hikingOtherParty.resolve(); return nil; }
        if (code == 1127) { hikingParty.attempts = [hikingAttempt,hikingAttempt]; return nil; }
        if (code == 1128)
        {
            event('test.hiking-party-error');
            try { eventValue(hikingParty.assess().reason); }
            catch (RpgExpandedError error) { eventValue(error.reason); }
            return nil;
        }
        return inherited(context);
    }
;
