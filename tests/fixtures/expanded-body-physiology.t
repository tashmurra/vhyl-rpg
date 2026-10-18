#include "expanded-body-reading.t"
physiologySkill: RpgExpandedSkill id = 'physiology' attribute = rpgIQ difficulty = 2 techLevel = 8 specialty = 'river-folk';
physiologyTraining: RpgTraining skill = physiologySkill points = 4;
biologySkill: RpgExpandedSkill id = 'biology' attribute = rpgIQ difficulty = 3 techLevel = 8 specialty = 'temperate';
biologyTraining: RpgTraining skill = biologySkill points = 8;
modify lieObserver techLevel = 8 skills = [bodyReadingTraining,physiologyTraining,biologyTraining];
physiologyObservation: RpgExpandedPhysiologyCheck id = 'read-river-folk' profile = lieObserver subject = lieSubject
    operation = bodyReading species = 'river-folk' skill = physiologySkill approved = true evidence = 'Relevant species specialty';
modify bodyReading physiology = 'similar' speciesModifier = -3 subjectSpecies = 'river-folk' physiologyCheck = physiologyObservation;
modify ExpandedTestAction
    exec(context)
    {
        local code = expandedInput.code;
        if (code == 18700 || code == 18701)
        { physiologyObservation.apply(); if (code == 18701) throw new RpgError(); return nil; }
        if (code == 18702)
        {
            local value = bodyReading.assess(); event('test.physiology-reading'); eventValue(value.status); eventValue(value.reason);
            eventValue(value.observerScore); eventValue(rpgRandom.draws); eventValue(lieObserver.physiologyChecks.length()); return nil;
        }
        if (code == 18703)
        { physiologyObservation.skill = biologySkill; physiologyObservation.commonAnimal = true; physiologyObservation.planetType = 'temperate'; physiologyObservation.species = 'marsh-animal';
          bodyReading.subjectSpecies = 'marsh-animal'; bodyReading.physiology = 'different'; bodyReading.speciesModifier = -5; return nil; }
        if (code == 18704)
        {
            local value = physiologyObservation.assess(); event('test.physiology-modifier'); eventValue(value.modifier); return nil;
        }
        if (code == 18705)
        {
            bodyReading.subjectSpecies = 'other-species';
            try { bodyReading.assess(); }
            catch (RpgExpandedError error) { event('test.physiology-binding'); eventValue(error.reason); }
            return nil;
        }
        return inherited(context);
    }
;
