#include "expanded-plant-forage.t"
#include <vhyl-rpg-expanded-skills.t>
natureTarget: RpgExpandedNaturalistSkill planet = 'home' specialty = 'home' planetType = 'terrestrial';
survivalTarget: RpgExpandedSurvivalSkill planet = 'home' specialty = 'woodlands' planetType = 'terrestrial';
natureSource: RpgExpandedNaturalistSkill planet = 'home' specialty = 'home' planetType = 'terrestrial';
survivalSource: RpgExpandedSurvivalSkill planet = 'home' specialty = 'desert' planetType = 'terrestrial';
natureSourceTraining: RpgExpandedTraining skill = natureSource points = 20;
survivalSourceTraining: RpgExpandedTraining skill = survivalSource points = 20;
modify plantAttempt skill = survivalTarget;
modify bleedProfile skills = [];
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 2200) { plantAttempt.skill = natureTarget; return nil; }
        if (code == 2201) { bleedProfile.skills = [natureSourceTraining]; return nil; }
        if (code == 2202) { bleedProfile.skills = [survivalSourceTraining]; return nil; }
        if (code == 2203) { survivalSource.planet = 'other'; survivalSource.specialty = 'woodlands'; return nil; }
        if (code == 2204) { survivalSource.planet = 'other'; return nil; }
        if (code == 2205) { survivalSource.planetType = 'oceanic'; survivalSource.planet = 'other'; return nil; }
        if (code == 2206) { natureSource.planet = 'other'; natureSource.specialty = 'other'; return nil; }
        if (code == 2207) { natureSourceTraining.points = 0; return nil; }
        if (code == 2208)
        { event('test.nature-score'); eventValue(bleedProfile.skillScore(plantAttempt.skill)); eventValue(rpgRandom.draws); return nil; }
        if (code == 2209)
        {
            event('test.survival-defaults');
            eventValue(rpgExpandedSurvivalDefault('desert','woodlands',true,true));
            eventValue(rpgExpandedSurvivalDefault('reef','open-ocean',true,true));
            eventValue(rpgExpandedSurvivalDefault('island-beach','tropical-lagoon',true,true));
            eventValue(rpgExpandedSurvivalDefault('river-stream','swampland',true,true));
            eventValue(rpgExpandedSurvivalDefault('reef','woodlands',true,true));
            eventValue(rpgExpandedSurvivalDefault('desert','woodlands',nil,true));
            eventValue(rpgExpandedSurvivalDefault('woodlands','woodlands',nil,true));
            eventValue(rpgExpandedSurvivalDefault('desert','woodlands',nil,nil));
            eventValue(rpgExpandedSurvivalDefault('special','woodlands',true,true)); return nil;
        }
        return inherited(context);
    }
;
