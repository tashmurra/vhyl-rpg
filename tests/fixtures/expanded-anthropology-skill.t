#include "expanded-sociology-skill.t"
anthropologyCatalogue: RpgExpandedAnthropologySkill specialty = 'river-folk';
anthropologyForeign: RpgExpandedAnthropologySkill specialty = 'hill-folk';
anthropologyForeignTraining: RpgTraining skill = anthropologyForeign points = 24;
anthropologyRelation: RpgExpandedAnthropologyDefault source = anthropologyForeign penalty = -2 approved = true evidence = 'Author established related species';
originsSkill: RpgExpandedSkill id = 'paleontology' attribute = rpgIQ difficulty = 2 techLevel = 8 specialty = 'human-origins';
originsTraining: RpgTraining skill = originsSkill points = 20;
modify PhysicianFixtureAction
    exec(context)
    {
        local code = healthInput.code;
        if (code == 21700)
        { event('test.anthropology-score'); eventValue(crossPhysician.skillScore(anthropologyCatalogue)); eventValue(rpgRandom.draws); return nil; }
        if (code == 21701) { crossPhysician.skills = [originsTraining]; return nil; }
        if (code == 21702) { crossPhysician.skills = [anthropologyForeignTraining]; return nil; }
        if (code == 21703) { anthropologyCatalogue.speciesDefaults = [anthropologyRelation]; return nil; }
        if (code == 21704) { anthropologyRelation.penalty = -5; return nil; }
        if (code == 21705) { originsSkill.specialty = 'fossil-plants'; return nil; }
        if (code == 21706) { anthropologyForeignTraining.points = 0; return nil; }
        return inherited(context);
    }
;
