#include "expanded-ancestry-features.t"
omissionPersonal: RpgExpandedTemplate disadvantageLimit = 15;
omissionRequest: RpgExpandedAncestryOmission
    id = 'personal-omission' traitId = 'luck' approved = true evidence = 'Approved individual exception';
omissionState: object ancestry = conflictFirst;
omissionRestoreTrait: RpgLiteTrait id = 'luck' points = 15;
omissionRestoreOffer: RpgDevelopment
    id = 'ordinary-restoration' kind = 'trait' trait = omissionRestoreTrait cost = 15 unlocked = true
    available(profile) { return nil; }
;
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 6400)
        {
            ancestryState.profile = rpgExpandedCreateCustomizedAncestryCharacter(omissionPersonal,
                [omissionState.ancestry],[],[omissionRequest],bleedRules); return nil;
        }
        if (code == 6401)
        {
            local p = ancestryState.profile; local amounts = p.ancestryScores.omissionAccounting.amounts(p);
            event('test.ancestry-omission'); eventValue(rpgExpandedCharacterCost(p,nil));
            eventValue(rpgExpandedCharacterCost(p,true)); eventValue(p.creationDisadvantageExemption());
            eventValue(p.traits.length()); eventValue(amounts[1]); eventValue(amounts[2]);
            eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 6402)
        { omissionState.ancestry = conflictSecond; omissionRequest.traitId = 'unluckiness'; omissionPersonal.disadvantageLimit = 0; return nil; }
        if (code == 6403) { omissionPersonal.disadvantageLimit = 14; return nil; }
        if (code == 6404) { omissionRequest.approved = nil; return nil; }
        if (code == 6405) { omissionRequest.traitId = 'missing'; return nil; }
        if (code == 6406)
        {
            event('test.ancestry-omission-error');
            try { rpgExpandedCreateCustomizedAncestryCharacter(omissionPersonal,[omissionState.ancestry],[],[omissionRequest],bleedRules); eventValue('accepted'); }
            catch (RpgExpandedError error) { eventValue(error.reason); } return nil;
        }
        if (code == 6407) { ancestryState.profile.contributions = []; return nil; }
        if (code == 6408) { ancestryState.profile.traits = [omissionRestoreTrait]; return nil; }
        if (code == 6409)
        {
            local p = ancestryState.profile; p.unspentPoints = 100; p.developmentOpen = true; omissionRestoreOffer.profile = p;
            local value = rpgDevelop(omissionRestoreOffer); event('test.ancestry-restoration');
            eventValue(value.reason); eventValue(p.unspentPoints); eventValue(p.traits.length()); return nil;
        }
        return inherited(context);
    }
;
