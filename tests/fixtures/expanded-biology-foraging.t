#include "expanded-nature-defaults.t"
forageBiology: RpgExpandedBiologySkill techLevel = 8 specialty = 'habitable';
forageBiologyTraining: RpgTraining skill = forageBiology points = 24;
modify natureTarget planetType = 'habitable';
modify plantAttempt skill = natureTarget;
modify bleedProfile techLevel = 8 skills = [forageBiologyTraining];
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 20200) { forageBiology.specialty = 'rocky'; return nil; }
        if (code == 20201) { forageBiologyTraining.points = 0; return nil; }
        if (code == 20202)
        {
            local skill = rpgExpandedBiologySubfield(forageBiology,'field-botany','botany',true,'Botany supports practical plant knowledge at this technology');
            local training = new RpgTraining(); training.skill = skill; training.points = 4;
            bleedProfile.skills = [training]; return nil;
        }
        return inherited(context);
    }
;
