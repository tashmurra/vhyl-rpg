#include "expanded-ancestry-skill-bonus.t"
ancestryIncompetence: RpgExpandedAncestryTemplate
    id = 'inept-ancestry' approved = true evidence = 'Approved innate limitation'
    incompetentSkillIds = ['test-learning'] incompetenceEvidence = 'This skill is important in the campaign'
;
incompetenceState: object personal = ancestryPlain;
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 6700)
        {
            ancestryState.profile = rpgExpandedCreateAncestryCharacter(incompetenceState.personal,[ancestryIncompetence],bleedRules);
            ancestryState.profile.unspentPoints = 100; ancestryState.profile.developmentOpen = true; return nil;
        }
        if (code == 6701)
        {
            local p = ancestryState.profile; event('test.ancestry-incompetence');
            eventValue(rpgExpandedCharacterCost(p,nil)); eventValue(rpgExpandedCharacterCost(p,true));
            eventValue(p.creationDisadvantageExemption()); eventValue(p.skillScore(learningSkill));
            eventValue(p.skillScore(bonusSpecialty)); eventValue(p.skillScore(bonusNoDefault));
            eventValue(bonusContext.scoreFor(p)); eventValue(p.skills.length()); return nil;
        }
        if (code == 6702)
        {
            local p = ancestryState.profile; event('test.ancestry-incompetence-learn');
            eventValue(p.skillLearningReason(bonusSpecialty)); eventValue(rpgLiteLearn(p,learningSkill,1,nil) ? 1 : 0);
            eventValue(p.unspentPoints); eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 6703) { incompetenceState.personal = bonusPersonal; return nil; }
        if (code == 6704) { ancestryIncompetence.incompetenceEvidence = nil; return nil; }
        if (code == 6705) { ancestryIncompetence.incompetentSkillIds = ['test-learning','a','b','c','d','e']; return nil; }
        if (code == 6706) { ancestryIncompetence.skillBonusRows = [['test-learning',1]]; return nil; }
        if (code == 6707) { ancestryState.profile.contributions = []; return nil; }
        if (code == 6708) { ancestryState.profile.ancestryScores.skillIncompetence.rows = []; return nil; }
        if (code == 6709)
        {
            event('test.ancestry-incompetence-error');
            try { rpgExpandedCreateAncestryCharacter(incompetenceState.personal,[ancestryIncompetence],bleedRules); eventValue('accepted'); }
            catch (RpgExpandedError error) { eventValue(error.reason); } return nil;
        }
        if (code == 6710) { ancestryIncompetence.incompetentSkillIds = ['test-learning','a','b','c','d']; return nil; }
        if (code == 6712) { ancestryIncompetence.incompetentSkillIds = ['test-learning','test-learning']; return nil; }
        return inherited(context);
    }
;
