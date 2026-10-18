#include "expanded-disguise-skill.t"
animalDisguiseType: object;
animalDisguiseEncounter: object;
animalDisguiseSkill: RpgExpandedDisguiseSkill techLevel = 8 specialty = 'animals';
animalHabitsSkill: RpgExpandedNaturalistSkill planet = 'home' planetType = 'habitable' specialty = 'home';
animalHabitsStudy: RpgExpandedAnimalHabitsStudy id = 'animal-habits' profile = crossPhysician skill = animalHabitsSkill
    animalType = animalDisguiseType encounter = animalDisguiseEncounter successMagnitude = 3 failureMagnitude = 2
    approved = true evidence = 'The relevant habits strongly affect this encounter';
animalDisguiseContext: RpgExpandedAnimalDisguiseContext skill = animalDisguiseSkill study = animalHabitsStudy
    animalType = animalDisguiseType encounter = animalDisguiseEncounter approved = true evidence = 'One group of the same animal type';
modify PhysicianFixtureAction
    exec(context)
    {
        local code = healthInput.code;
        if (code == 25500 || code == 25501)
        { animalHabitsStudy.resolve(); if (code == 25501) throw new RpgError(); return nil; }
        if (code == 25502)
        { event('test.animal-disguise'); eventValue(rpgLiteScore(crossPhysician,animalDisguiseContext));
          eventValue(animalDisguiseContext.unavailableReason(crossPhysician)); eventValue(rpgRandom.draws);
          eventValue(crossPhysician.animalHabitsStudies.length()); return nil; }
        if (code == 25503) { rpgRandom.medicalRoll = 18; return nil; }
        if (code == 25504) { animalDisguiseContext.downwind = true; animalDisguiseContext.skinConditionPenalty = -1; return nil; }
        if (code == 25505) { animalDisguiseContext.animalCount = 3; return nil; }
        if (code == 25506) { animalDisguiseContext.herd = true; animalDisguiseContext.animalCount = 9; return nil; }
        if (code == 25507) { animalDisguiseContext.herd = true; animalDisguiseContext.animalCount = 10; return nil; }
        if (code == 25508) { crossPhysician.fatigue = crossPhysician.maxEnergy; rpgRandom.medicalRoll = 13; return nil; }
        if (code == 25509) { crossPhysician.fatigue = 0; return nil; }
        if (code == 25510)
        {
            animalHabitsStudy.result.allowed = true;
            try { animalHabitsStudy.assess(); }
            catch (RpgExpandedError error) { event('test.animal-habits-error'); eventValue(error.reason); }
            return nil;
        }
        return inherited(context);
    }
;
