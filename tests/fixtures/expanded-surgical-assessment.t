#include "expanded-bleeding.t"
#include <vhyl-rpg-expanded-skills.t>
surgicalSkill: RpgExpandedSkill id = 'surgery' attribute = rpgIQ difficulty = 3 techLevel = 8;
surgicalTraining: RpgExpandedTraining skill = surgicalSkill points = 4;
surgicalAid: RpgExpandedSkill id = 'first-aid' attribute = rpgIQ difficulty = 0 techLevel = 8;
surgicalAidTraining: RpgExpandedTraining skill = surgicalAid points = 1;
surgicalPhysician: RpgExpandedSkill id = 'physician' attribute = rpgIQ difficulty = 2 techLevel = 8;
surgicalPhysicianTraining: RpgExpandedTraining skill = surgicalPhysician points = 1;
surgicalHealer: RpgExpandedProfile rules = bleedRules techLevel = 8 campaignTL = 8 iq = 14 skills = [surgicalTraining,surgicalAidTraining];
surgicalConditions: RpgExpandedSurgeryContext techLevel = 8;
surgicalAssessment: RpgExpandedSurgicalAssessment surgeon = surgicalHealer skill = surgicalSkill conditions = surgicalConditions;
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 90)
        {
            local value = surgicalAssessment.assess();
            event('test.surgical-assessment'); eventValue(value.status); eventValue(value.reason);
            eventValue(value.score); eventValue(value.trainingModifier);
            eventValue(surgicalConditions.physicianTrained ? 1 : 0);
            eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 91) { surgicalHealer.skills = [surgicalTraining,surgicalPhysicianTraining]; return nil; }
        if (code == 92) { surgicalHealer.skills = [surgicalTraining]; return nil; }
        if (code == 93) { surgicalConditions.fieldExpedient = true; return nil; }
        if (code == 94) { surgicalConditions.techLevel = 7; return nil; }
        if (code == 95) { surgicalTraining.points = 0; return nil; }
        if (code == 96) { surgicalHealer.stunned = true; return nil; }
        if (code == 97) { surgicalConditions.site = 'chest'; return nil; }
        return inherited(context);
    }
;
