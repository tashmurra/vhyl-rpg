#include "expanded-medical-skills.t"
veterinaryCatalogue: RpgExpandedVeterinarySkill techLevel = 8;
veterinaryTraining: RpgTraining skill = veterinaryCatalogue points = 4;
veterinaryAnimal: RpgExpandedProfile rules = healthRules;
veterinaryContext: RpgExpandedVeterinaryContext skill = veterinaryCatalogue animal = veterinaryAnimal animalType = 'herd-animal'
    approved = true evidence = 'The animal type and relationship to this caregiver are established';
modify PhysicianFixtureAction
    exec(context)
    {
        local code = healthInput.code;
        if (code == 20600)
        { event('test.veterinary-score'); eventValue(rpgLiteScore(crossPhysician,veterinaryContext)); eventValue(rpgRandom.draws); return nil; }
        if (code == 20601) { crossPhysician.skills = [medicalSourceTraining]; medicalSource.id = 'physician'; return nil; }
        if (code == 20602) { crossPhysician.skills = [medicalSourceTraining]; medicalSource.id = 'surgery'; medicalSource.difficulty = 3; return nil; }
        if (code == 20603) { crossPhysician.skills = [medicalSourceTraining]; medicalSource.id = 'animal-handling'; medicalSource.techLevel = nil; return nil; }
        if (code == 20604) { crossPhysician.skills = [veterinaryTraining]; return nil; }
        if (code == 20605) { veterinaryContext.knowsAndTrusts = true; return nil; }
        if (code == 20606) { veterinaryContext.unfamiliarPenalty = -2; return nil; }
        if (code == 20607)
        {
            local skill = rpgExpandedOptionalSpecialty(veterinaryCatalogue,'herd-veterinary','herd-animal',true);
            local training = new RpgTraining(); training.skill = skill; training.points = 4;
            crossPhysician.skills = [training]; veterinaryContext.skill = skill; return nil;
        }
        if (code == 20608)
        {
            veterinaryContext.unfamiliarPenalty = -1;
            try { veterinaryContext.validateVeterinary(); }
            catch (RpgExpandedError error) { event('test.veterinary-error'); eventValue(error.reason); }
            return nil;
        }
        return inherited(context);
    }
;
