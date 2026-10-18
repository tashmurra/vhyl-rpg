#include "expanded-packing-skill.t"
#include <vhyl-rpg-expanded-creatures.t>
packingAnimal: RpgExpandedProfile;
packingOccurrence: object;
packingOtherOccurrence: object;
packingPrerequisite: RpgExpandedAnimalHandlingAttempt id = 'prepare-load' animal = packingAnimal handler = crossPhysician
    skill = packingHandling appropriateSpecialty = true mode = 'calm' packingOccurrence = packingOccurrence
    approved = true available = true uninterrupted = true evidence = 'Calm this difficult animal before loading';
packingAttempt: RpgExpandedPackingAttempt id = 'load-animal' profile = crossPhysician animal = packingAnimal
    skill = packingCatalogue occurrence = packingOccurrence difficult = true approved = true evidence = 'Authored load is suitable for this animal';
modify crossPhysician skills = [packingTraining,packingHandlingTraining];
modify PhysicianFixtureAction
    exec(context)
    {
        local code = healthInput.code;
        if (code == 22500 || code == 22501)
        { local value = packingAttempt.resolve(); event('test.packing-result'); eventValue(value.status); eventValue(value.reason);
          if (code == 22501) throw new RpgError(); return nil; }
        if (code == 22502)
        { local value = packingAttempt.assess(); event('test.packing-preview'); eventValue(value.status); eventValue(value.reason); eventValue(value.score); return nil; }
        if (code == 22503) { packingAttempt.handling = packingPrerequisite; return nil; }
        if (code == 22504) { packingPrerequisite.apply(); return nil; }
        if (code == 22505) { rpgRandom.medicalRoll = 18; return nil; }
        if (code == 22506)
        { event('test.packing-state'); eventValue(crossPhysician.packingAttempts.length()); eventValue(packingAnimal.animalHandlingAttempts.length());
          eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil; }
        if (code == 22507)
        {
            packingPrerequisite.packingOccurrence = packingOtherOccurrence;
            try { packingAttempt.resolve(); }
            catch (RpgExpandedError error) { event('test.packing-binding'); eventValue(error.reason); }
            return nil;
        }
        return inherited(context);
    }
;
