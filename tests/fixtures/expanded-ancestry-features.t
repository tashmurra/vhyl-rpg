#include "expanded-ancestry-conflicts.t"
ancestryForbiddenSkill: RpgExpandedSkill id = 'ancestry-forbidden-skill' attribute = rpgIQ difficulty = 1 defaultPenalty = -5;
ancestryFeaturePackage: RpgExpandedAncestryTemplate
    id = 'marked-ancestry' approved = true evidence = 'Approved appearance and purchase constraints'
    cosmeticFeatures = ['silver freckles'] tabooTraitIds = ['luck']
    tabooSkills = [ancestryForbiddenSkill] tabooAttributeRanges = [[rpgST,12,1000]]
;
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 6300)
        {
            ancestryState.profile = rpgExpandedCreateAncestryCharacter(ancestryPlain,[ancestryFeaturePackage],bleedRules);
            return nil;
        }
        if (code == 6301)
        {
            local p = ancestryState.profile; event('test.ancestry-features');
            eventValue(rpgExpandedCharacterCost(p,nil)); eventValue(p.contributions.length());
            eventValue(p.ancestryScores.features[1][1]); eventValue(p.ancestryScores.features[1][2]);
            eventValue(p.skillLearningReason(ancestryForbiddenSkill)); return nil;
        }
        if (code == 6302)
        {
            local p = ancestryState.profile; p.unspentPoints = 100; p.developmentOpen = true;
            event('test.ancestry-feature-learning'); eventValue(rpgLiteLearn(p,ancestryForbiddenSkill,1,nil) ? 1 : 0);
            eventValue(p.unspentPoints); eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 6303) { ancestryState.profile.contributions = []; return nil; }
        if (code == 6304) { ancestryState.profile.ancestryScores.constraints[1].skills = []; return nil; }
        if (code == 6305) { ancestryState.profile.ancestryScores.features = []; return nil; }
        if (code == 6306)
        { ancestryFeaturePackage.cosmeticFeatures = []; ancestryFeaturePackage.tabooSkills = []; return nil; }
        if (code == 6307) { ancestryPlain.st = 12; return nil; }
        if (code == 6308)
        {
            event('test.ancestry-feature-error');
            try { rpgExpandedCreateAncestryCharacter(ancestryPlain,[ancestryFeaturePackage],bleedRules); eventValue('accepted'); }
            catch (RpgExpandedError error) { eventValue(error.reason); } return nil;
        }
        if (code == 6309)
        {
            event('test.ancestry-feature-error');
            try { ancestryState.profile.skillLearningReason(ancestryForbiddenSkill); eventValue('accepted'); }
            catch (RpgExpandedError error) { eventValue(error.reason); } return nil;
        }
        if (code == 6310) { ancestryFeaturePackage.traitRows = [['luck',1,nil]]; return nil; }
        if (code == 6311)
        {
            local p = rpgExpandedCreateAncestryCharacter(ancestryPlain,[ancestryFeaturePackage],bleedRules);
            event('test.ancestry-feature-ownership');
            eventValue(p.contributions[1] == ancestryState.profile.contributions[1] ? 1 : 0);
            eventValue(p.contributions[1].owner == p ? 1 : 0); return nil;
        }
        return inherited(context);
    }
;
