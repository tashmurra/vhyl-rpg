#include "expanded-ancestry-training.t"
ancestrySkillBonus: RpgExpandedAncestryTemplate
    id = 'skilled-ancestry' approved = true evidence = 'Approved innate aptitude'
    skillBonusRows = [['test-learning',1]]
;
ancestrySecondBonus: RpgExpandedAncestryTemplate
    id = 'second-aptitude' approved = true evidence = 'Approved innate aptitude'
    skillBonusRows = [['test-learning',3]]
;
bonusPersonal: RpgExpandedTemplate skillRows = [[learningSkill,1]];
bonusSpecialty: RpgExpandedSkill id = 'test-learning' specialty = 'other' attribute = rpgIQ difficulty = 1 defaultPenalty = -5;
bonusNoDefault: RpgExpandedSkill id = 'test-learning' attribute = rpgIQ difficulty = 1 defaultPenalty = nil;
bonusOther: RpgExpandedSkill id = 'unmodified-skill' attribute = rpgIQ difficulty = 1 defaults = [[learningSkill,0]];
bonusLite: RpgLiteSkill id = 'test-learning' attribute = rpgIQ difficulty = 1 defaultPenalty = -5;
bonusContext: RpgExpandedSkillContext skill = learningSkill fixedBase = 20;
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 6600 || code == 6601)
        {
            ancestryState.profile = rpgExpandedCreateAncestryCharacter(code == 6600 ? bonusPersonal : ancestryPlain,
                [ancestrySkillBonus],bleedRules);
            ancestryState.profile.unspentPoints = 100; ancestryState.profile.developmentOpen = true; return nil;
        }
        if (code == 6602)
        {
            event('test.ancestry-bonus-learn'); eventValue(rpgLiteLearn(ancestryState.profile,learningSkill,2,nil) ? 1 : 0);
            eventValue(ancestryState.profile.unspentPoints); return nil;
        }
        if (code == 6603)
        {
            local p = ancestryState.profile; event('test.ancestry-skill-bonus'); eventValue(rpgExpandedCharacterCost(p,nil));
            eventValue(p.skillScore(learningSkill)); eventValue(p.skillScore(bonusSpecialty)); eventValue(p.skillScore(bonusNoDefault));
            eventValue(p.skillScore(bonusOther)); eventValue(p.skillScore(bonusLite)); eventValue(bonusContext.scoreFor(p));
            eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 6604) { ancestryState.profile.contributions = []; return nil; }
        if (code == 6605) { ancestryState.profile.ancestryScores.skillBonuses.rows = [['test-learning',3]]; return nil; }
        if (code == 6606)
        {
            event('test.ancestry-bonus-error');
            try { rpgExpandedCreateAncestryCharacter(ancestryPlain,[ancestrySkillBonus,ancestrySecondBonus],bleedRules); eventValue('accepted'); }
            catch (RpgExpandedError error) { eventValue(error.reason); } return nil;
        }
        return inherited(context);
    }
;
