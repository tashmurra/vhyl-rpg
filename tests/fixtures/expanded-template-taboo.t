#include "expanded-template-customization.t"
tabooSkill: RpgExpandedSkill id = 'test-forbidden' attribute = rpgIQ difficulty = 1 defaultPenalty = -5;
tabooPurchase: RpgLiteTrait id = 'luck' points = 15;
tabooConstraint: RpgExpandedTabooTraits
    id = 'ancestry-prohibitions'
    traitIds = ['luck'] skills = [tabooSkill] attributeRanges = [[rpgST,12,1000]]
    approved = true evidence = 'Authored ancestry prohibitions'
;
tabooOffer: RpgDevelopment
    id = 'taboo-purchase' kind = 'trait' trait = tabooPurchase cost = 15 unlocked = true
    attribute = rpgST target = 12
    available(profile) { return nil; }
;
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 5810 || code == 5811)
        {
            tabooConstraint.attributeRanges = [[code == 5810 ? rpgWill : rpgPerception,12,13]];
            tabooOffer.kind = 'attribute'; tabooOffer.attribute = rpgIQ; tabooOffer.target = 12; return nil;
        }
        if (code == 5812) { tabooOffer.attribute = tabooConstraint.attributeRanges[1][1]; return nil; }
        if (code == 5813) { tabooOffer.target = 11; return nil; }
        if (code == 5814) { tabooOffer.target = 13; return nil; }
        if (code == 5815) { tabooOffer.target = 14; return nil; }
        if (code == 5816)
        {
            local value = rpgAssessDevelopment(tabooOffer); event('test.taboo-secondary');
            eventValue(value.status); eventValue(value.reason); eventValue(value.points);
            eventValue(personalState.profile.iq); eventValue(personalState.profile.will);
            eventValue(personalState.profile.perception); eventValue(personalState.profile.unspentPoints);
            return nil;
        }
        if (code == 5819)
        {
            if (tabooConstraint.attributeRanges[1][1] == rpgWill) personalState.profile.willAdjustment = 1;
            else personalState.profile.perceptionAdjustment = 1;
            tabooOffer.attribute = rpgIQ; tabooOffer.target = 11; return nil;
        }
        if (code == 5817) { personalState.profile.willAdjustment = 2; return nil; }
        if (code == 5818) { personalState.profile.perceptionAdjustment = 2; return nil; }
        if (code == 5800)
        {
            local p = personalRequest.create(bleedRules); personalState.profile = p;
            tabooConstraint.owner = p; p.contributions = [tabooConstraint]; tabooOffer.profile = p;
            p.unspentPoints = 100; p.earnedPoints = 100; p.developmentOpen = true; return nil;
        }
        if (code == 5801)
        {
            local p = personalState.profile; event('test.taboo');
            eventValue(rpgExpandedCharacterCost(p,nil)); eventValue(p.skillLearningReason(tabooSkill));
            eventValue(rpgLiteLearn(p,tabooSkill,1,nil) ? 1 : 0);
            eventValue(rpgDevelop(tabooOffer).reason); eventValue(p.unspentPoints);
            eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 5802) { tabooOffer.kind = 'attribute'; return nil; }
        if (code == 5803) { personalState.profile.st = 12; return nil; }
        if (code == 5804) { personalState.profile.traits = personalState.profile.traits + [tabooPurchase]; return nil; }
        if (code == 5805)
        {
            local training = new RpgExpandedTraining(); training.skill = tabooSkill; training.points = 1;
            personalState.profile.skills = personalState.profile.skills + [training]; return nil;
        }
        if (code == 5806)
        {
            event('test.taboo-error');
            try { rpgExpandedValidateCharacter(personalState.profile); eventValue('accepted'); }
            catch (RpgExpandedError error) { eventValue(error.reason); } return nil;
        }
        return inherited(context);
    }
;
