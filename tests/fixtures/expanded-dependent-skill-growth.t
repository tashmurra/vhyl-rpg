#include "expanded-dependent-growth.t"
#include <vhyl-rpg-expanded-skills.t>
dependentGrowthSkill: RpgExpandedSkill id = 'fieldcraft' attribute = rpgIQ difficulty = 0
    blocked = nil learningPrerequisiteReason(profile) { return self.blocked ? 'authored-prerequisite' : nil; };
dependentGrowthTraining: RpgExpandedTraining skill = dependentGrowthSkill points = 10;
dependentNpc: RpgExpandedProfile rules = bleedRules iq = 12 skills = [dependentGrowthTraining];
dependentSkillApplication: RpgExpandedDependentSkillGrowth growth = dependentGrowth
    purchases = [['study',dependentGrowthTraining,10,20,nil]];
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 13900)
        {
            bleedProfile.contributions = [dependentRelationship]; dependentRelationship.dependent = dependentNpc;
            dependentGrowth.improvements = [['study',10,'Approved fieldcraft development']]; dependentGrowth.record(); return nil;
        }
        if (code == 13901)
        {
            local value = dependentSkillApplication.assess(); event('test.dependent-skill-preview');
            eventValue(value.status); eventValue(value.reason); return nil;
        }
        if (code == 13902 || code == 13903)
        { dependentSkillApplication.apply(); if (code == 13903) throw new RpgError(); return nil; }
        if (code == 13904)
        {
            event('test.dependent-skill-state'); eventValue(dependentGrowthTraining.points); eventValue(dependentNpc.developmentRevision);
            eventValue(dependentNpc.dependentSkillGrowthApplications.length()); eventValue(dependentNpc.earnedPoints);
            eventValue(dependentNpc.unspentPoints); eventValue(bleedProfile.earnedPoints); eventValue(bleedProfile.unspentPoints);
            eventValue(rpgRandom.draws); eventValue(rpgExpandedCharacterCost(dependentNpc,nil)); return nil;
        }
        if (code == 13905)
        {
            dependentGrowthTraining.points = 9;
            try { dependentSkillApplication.assess(); }
            catch (RpgExpandedError error) { event('test.dependent-skill-reject'); eventValue(error.reason); } return nil;
        }
        if (code == 13906) { dependentGrowthSkill.blocked = true; return nil; }
        return inherited(context);
    }
;
