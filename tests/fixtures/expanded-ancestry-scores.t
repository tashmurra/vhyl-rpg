#include "expanded-template-customization.t"
ancestryPersonalHealth: RpgExpandedTemplate st = 11 hpAdjustment = 2 pointBudget = 1000;
ancestryHealth: RpgExpandedAncestryScoreTemplate
    id = 'strong-body' stChange = 6 hpChange = 4 approved = true evidence = 'Approved score package';
ancestryPersonalSpeed: RpgExpandedTemplate dx = 12 ht = 12 speedQuarterAdjustment = 4 pointBudget = 1000;
ancestrySpeed: RpgExpandedAncestryScoreTemplate
    id = 'quick-body' dxChange = 2 htChange = 1 speedQuarterChange = -3
    approved = true evidence = 'Approved score package';
ancestryPersonalSplit: RpgExpandedTemplate st = 9 iq = 14 pointBudget = 1000 disadvantageLimit = 10;
ancestrySplit: RpgExpandedAncestryScoreTemplate
    id = 'large-body' stChange = 10 iqChange = -1 approved = true evidence = 'Approved score package';
ancestrySmall: RpgExpandedAncestryScoreTemplate
    id = 'small-body' stChange = -1 approved = true evidence = 'Approved score package';
ancestryPlain: RpgExpandedTemplate pointBudget = 1000 disadvantageLimit = 0;
ancestryState: object profile = nil;
ancestryOffer: RpgDevelopment
    id = 'ancestry-personal-growth' kind = 'attribute' attribute = rpgST unlocked = true
    available(profile) { return nil; }
;
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code >= 5900 && code <= 5904 || code == 5911)
        {
            bleedRules.exceptionalCharacteristics = true;
            local personal = ancestryPlain; local packages = [];
            if (code == 5900) { personal = ancestryPersonalHealth; packages = [ancestryHealth]; }
            if (code == 5901) { personal = ancestryPersonalSpeed; packages = [ancestrySpeed]; }
            if (code == 5902) { personal = ancestryPersonalSplit; packages = [ancestrySplit]; }
            if (code == 5911) packages = [ancestrySmall];
            if (code == 5903) packages = [ancestrySmall,ancestryHealth];
            ancestryState.profile = rpgExpandedCreateAncestryCharacter(personal,packages,bleedRules);
            return nil;
        }
        if (code == 5905)
        {
            local p = ancestryState.profile; event('test.ancestry-scores');
            eventValue(rpgExpandedCharacterCost(p,nil)); eventValue(rpgExpandedCharacterCost(p,true));
            eventValue(p.creationDisadvantageExemption()); eventValue(p.st); eventValue(p.dx);
            eventValue(p.iq); eventValue(p.ht); eventValue(p.maxHP); eventValue(p.basicSpeedQuarters());
            eventValue(p.ancestryScores.origins.length()); eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws);
            return nil;
        }
        if (code == 5906)
        { ancestryState.profile.ancestryScores.changes = [0,0,0,0,0,0,0,0,0,0]; return nil; }
        if (code == 5907)
        {
            event('test.ancestry-score-error');
            try { rpgExpandedValidateCharacter(ancestryState.profile); eventValue('accepted'); }
            catch (RpgExpandedError error) { eventValue(error.reason); } return nil;
        }
        if (code == 5908) { ancestryState.profile.disadvantageLimit = 9; return nil; }
        if (code == 5909)
        {
            local p = ancestryState.profile; p.unspentPoints = 100; p.developmentOpen = true;
            ancestryOffer.profile = p; ancestryOffer.target = p.st + 1;
            local value = rpgDevelop(ancestryOffer); event('test.ancestry-growth');
            eventValue(value.status); eventValue(value.points); eventValue(p.unspentPoints); return nil;
        }
        if (code == 5910)
        {
            bleedRules.exceptionalCharacteristics = nil; event('test.ancestry-score-error');
            try { rpgExpandedCreateAncestryCharacter(ancestryPlain,[ancestrySmall],bleedRules); eventValue('accepted'); }
            catch (RpgExpandedError error) { eventValue(error.reason); } return nil;
        }
        return inherited(context);
    }
;
