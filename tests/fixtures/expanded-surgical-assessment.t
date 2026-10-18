#include "expanded-bleeding.t"
#include <vhyl-rpg-expanded-skills.t>
surgicalSkill: RpgExpandedSurgerySkill techLevel = 8;
surgicalTraining: RpgExpandedTraining skill = surgicalSkill points = 4;
surgicalAid: RpgExpandedSkill id = 'first-aid' attribute = rpgIQ difficulty = 0 techLevel = 8;
surgicalAidTraining: RpgExpandedTraining skill = surgicalAid points = 1;
surgicalPhysician: RpgExpandedSkill id = 'physician' attribute = rpgIQ difficulty = 2 techLevel = 8;
surgicalPhysicianTraining: RpgExpandedTraining skill = surgicalPhysician points = 1;
surgicalPhysiology: RpgExpandedSkill id = 'physiology' attribute = rpgIQ difficulty = 2 techLevel = 8;
surgicalPhysiologyTraining: RpgExpandedTraining skill = surgicalPhysiology points = 16;
surgicalVeterinary: RpgExpandedSkill id = 'veterinary' attribute = rpgIQ difficulty = 2 techLevel = 8;
surgicalVeterinaryTraining: RpgExpandedTraining skill = surgicalVeterinary points = 4;
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
        if (code == 98) { surgicalHealer.skills = [surgicalPhysiologyTraining]; return nil; }
        if (code == 99)
        {
            event('test.surgical-learning'); eventValue(surgicalHealer.skillLearningReason(surgicalSkill)); return nil;
        }
        if (code == 100) { surgicalHealer.skills = [surgicalVeterinaryTraining]; return nil; }
        if (code == 101) { surgicalHealer.skills = [surgicalPhysicianTraining]; return nil; }
        if (code == 102) { surgicalVeterinaryTraining.points = 0; surgicalVeterinary.defaultPenalty = -5; return nil; }
        if (code == 103) { surgicalPhysician.techLevel = 7; return nil; }
        if (code == 104) { surgicalHealer.familiarSkills = []; return nil; }
        if (code == 105)
        {
            surgicalPhysicianTraining.points = 36;
            surgicalHealer.skills = [surgicalTraining,surgicalPhysicianTraining]; return nil;
        }
        if (code == 106) { surgicalTraining.defaultFrom = surgicalPhysician; return nil; }
        return inherited(context);
    }
;
