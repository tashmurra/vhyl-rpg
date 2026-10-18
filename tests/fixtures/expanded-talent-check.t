#include "expanded-talent-study.t"
talentCheckContext: RpgLiteContext skill = studyTalentSkill;
talentLiteProfile: RpgLiteProfile traits = [studyTalent];
talentFixedContext: RpgExpandedSkillContext skill = studyTalentSkill fixedBase = 20;
modify bleedRules techniques = true;
talentTechnique: RpgExpandedTechnique owner = bleedProfile skill = studyTalentSkill penalty = -2;
talentTechniqueContext: RpgExpandedTechniqueContext technique = talentTechnique skill = studyTalentSkill;
talentOptionalSkill: RpgExpandedSkill
    id = 'specialized-repair' specialty = 'clockwork' optionalParent = studyTalentSkill optionalApproved = true
    attribute = rpgIQ difficulty = 0
;
talentOptionalTraining: RpgExpandedTraining skill = talentOptionalSkill points = 1;
talentOptionalContext: RpgExpandedSkillContext skill = talentOptionalSkill;
talentDuplicate: RpgLiteTrait id = 'artificer' points = 10 level = 1;
talentRequirement: RpgExpandedPrerequisite skill = studyTalentSkill minimum = 11;
talentAdvancedSkill: RpgExpandedSkill id = 'advanced-repair' attribute = rpgIQ difficulty = 2 prerequisite = talentRequirement;
talentUnavailable: RpgExpandedSkill id = 'mechanic' attribute = rpgIQ difficulty = 1;

modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 7100)
        {
            event('test.talent-check');
            eventValue(bleedProfile.catalogueTalentCheckModifier(studyTalentSkill));
            eventValue(talentLiteProfile.catalogueTalentCheckModifier(studyTalentSkill));
            eventValue(rpgLiteScore(bleedProfile,talentCheckContext) - bleedProfile.skillScore(studyTalentSkill));
            eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 7102)
        {
            event('test.talent-scores');
            eventValue(bleedProfile.skillScore(studyTalentSkill));
            eventValue(rpgLiteScore(bleedProfile,talentCheckContext));
            eventValue(rpgLiteScore(bleedProfile,talentFixedContext));
            eventValue(studyTalentTraining.points > 0 ? rpgLiteScore(bleedProfile,talentTechniqueContext) : nil);
            eventValue(bleedProfile.skillScore(talentUnavailable));
            eventValue(rpgExpandedPaidSkill(bleedProfile,studyTalentSkill,[]));
            eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 7103)
        {
            event('test.talent-prerequisite');
            eventValue(talentRequirement.satisfied(bleedProfile,[]) ? 1 : 0);
            eventValue(bleedProfile.skillLearningReason(talentAdvancedSkill));
            eventValue(studyTalentTraining.points); eventValue(bleedProfile.unspentPoints);
            eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 7106)
        {
            bleedProfile.skills = [studyTalentTraining,talentOptionalTraining];
            event('test.talent-specialty');
            eventValue(bleedProfile.skillScore(talentOptionalSkill));
            eventValue(rpgLiteScore(bleedProfile,talentOptionalContext));
            eventValue(bleedProfile.studyTimePercent(talentOptionalSkill));
            eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 7107) { bleedProfile.traits = [studyTalent,talentDuplicate]; studyTalentSkill.id = 'unrelated'; return nil; }
        if (code == 7108)
        {
            event('test.talent-invalid');
            try { rpgLiteCheck(bleedProfile,talentCheckContext); eventValue('accepted'); }
            catch (RpgExpandedError error) { eventValue(error.reason); }
            eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 7104) { talentRequirement.minimum = 12; return nil; }
        if (code == 7105) { talentRequirement.minimum = 7; return nil; }
        if (code == 7101) { studyTalentTraining.points = 0; return nil; }
        return inherited(context);
    }
;
