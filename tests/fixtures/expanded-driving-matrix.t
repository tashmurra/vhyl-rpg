#include "expanded-driving.t"
modify ExpandedTestAction
    exec(context)
    {
        local code = expandedInput.code;
        if (code == 16600)
        {
            local skills = [];
            foreach (local specialty in ['automobile','construction-equipment','halftrack','heavy-wheeled',
                'hovercraft','locomotive','mecha','motorcycle','tracked'])
            {
                local skill = new RpgExpandedDrivingSkill(); skill.techLevel = 8; skill.specialty = specialty;
                skills = skills + [skill];
            }
            event('test.driving-matrix');
            foreach (local target in skills)
                foreach (local source in skills)
                {
                    local training = new RpgExpandedTraining(); training.skill = source; training.points = 32;
                    drivingHero.skills = [training]; eventValue(drivingHero.skillScore(target));
                }
            return nil;
        }
        if (code == 16601)
        {
            local bicycle = new RpgExpandedSkill(); bicycle.id = 'bicycling'; bicycle.attribute = rpgDX; bicycle.difficulty = 0;
            local suit = new RpgExpandedSkill(); suit.id = 'battlesuit'; suit.attribute = rpgDX; suit.difficulty = 1; suit.techLevel = 8;
            local mecha = new RpgExpandedDrivingSkill(); mecha.techLevel = 8; mecha.specialty = 'mecha';
            local training = new RpgExpandedTraining(); training.points = 32; training.skill = bicycle;
            drivingHero.skills = [training]; event('test.driving-external'); eventValue(drivingHero.skillScore(drivingMotorcycle));
            training.skill = suit; eventValue(drivingHero.skillScore(mecha));
            suit.techLevel = 7; eventValue(drivingHero.skillScore(mecha));
            training.skill = drivingCar; training.points = 0; eventValue(drivingHero.skillScore(drivingTruck)); return nil;
        }
        if (code == 16602)
        {
            drivingCar.attributeDefaults = [[rpgIQ,0]];
            try { drivingHero.skillScore(drivingCar); }
            catch (RpgExpandedError error) { event('test.driving-invalid-default'); eventValue(error.reason); }
            return nil;
        }
        return inherited(context);
    }
;
