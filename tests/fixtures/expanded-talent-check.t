#include "expanded-talent-study.t"
talentCheckContext: RpgLiteContext skill = studyTalentSkill;
talentLiteProfile: RpgLiteProfile traits = [studyTalent];
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
        if (code == 7101) { studyTalentTraining.points = 0; return nil; }
        return inherited(context);
    }
;
