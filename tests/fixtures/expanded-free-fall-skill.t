#include "expanded-free-fall.t"
fallSkill: RpgExpandedFreeFallSkill;
fallTraining: RpgExpandedTraining skill = fallSkill points = 2;
fallOtherSkill: RpgExpandedSkill id = 'fixture-dexterity-task' attribute = rpgDX difficulty = 0;
fallOtherTraining: RpgExpandedTraining skill = fallOtherSkill points = 4;
fallTask: RpgLiteContext skill = fallOtherSkill;
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 9300)
        { event('test.free-fall-default'); eventValue(bleedProfile.skillScore(fallSkill)); eventValue(rpgRandom.draws); return nil; }
        if (code == 9301) { bleedProfile.ht = 20; return nil; }
        if (code == 9302) { bleedProfile.ht = 30; return nil; }
        if (code == 9303)
        {
            bleedProfile.dx = 14; bleedProfile.ht = 10;
            bleedProfile.skills = [fallTraining,fallOtherTraining]; freeFall.skill = fallSkill; return nil;
        }
        if (code == 9304)
        {
            event('test.free-fall-cap'); eventValue(bleedProfile.skillScore(fallSkill));
            eventValue(bleedProfile.skillScore(fallOtherSkill)); eventValue(rpgLiteScore(bleedProfile,fallTask));
            eventValue(rpgRandom.draws); return nil;
        }
        if (code == 9305) { fallTask.modifier = 3; return nil; }
        if (code == 9306)
        {
            fallSkill.attributeDefaults = [[rpgHT,-4]]; event('test.free-fall-definition');
            try { bleedProfile.skillScore(fallSkill); eventValue('accepted'); }
            catch (RpgExpandedError error) { eventValue(error.reason); }
            fallSkill.attributeDefaults = [[rpgHT,-5]]; return nil;
        }
        return inherited(context);
    }
;
