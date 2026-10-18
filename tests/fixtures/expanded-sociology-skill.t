#include "expanded-psychology-skill.t"
sociologyCatalogue: RpgExpandedSociologySkill;
sociologyTraining: RpgTraining skill = sociologyCatalogue points = 24;
sociologyAnthropology: RpgExpandedSkill id = 'anthropology' attribute = rpgIQ difficulty = 2 specialty = 'river-folk';
sociologyAnthropologyTraining: RpgTraining skill = sociologyAnthropology points = 20;
modify PhysicianFixtureAction
    exec(context)
    {
        local code = healthInput.code;
        if (code == 21600)
        { event('test.sociology-scores'); eventValue(crossPhysician.skillScore(sociologyCatalogue)); eventValue(crossPhysician.skillScore(psychologyApplied)); eventValue(rpgRandom.draws); return nil; }
        if (code == 21601) { crossPhysician.skills = [sociologyTraining]; return nil; }
        if (code == 21602) { crossPhysician.skills = [sociologyAnthropologyTraining]; return nil; }
        if (code == 21603)
        {
            local skill = rpgExpandedOptionalSpecialty(sociologyAnthropology,'ritual-anthropology','rituals',true);
            local training = new RpgTraining(); training.skill = skill; training.points = 4;
            crossPhysician.skills = [training]; return nil;
        }
        return inherited(context);
    }
;
