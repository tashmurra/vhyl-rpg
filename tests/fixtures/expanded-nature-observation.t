#include "expanded-biology-foraging.t"
natureOccurrence: object;
natureObservation: RpgExpandedNatureObservation id = 'field-observation' profile = bleedProfile skill = natureTarget
    occurrence = natureOccurrence purpose = 'plant-safety' planet = 'home' planetType = 'habitable' accessible = true
    approved = true evidence = 'The plant can be examined and the finding is known to the author' finding = 'These berries are unsafe to eat';
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 20300 || code == 20301)
        { local value = natureObservation.resolve(); event('test.nature-finding'); eventValue(value.status); eventValue(value.finding);
          if (code == 20301) throw new RpgError(); return nil; }
        if (code == 20302)
        { local value = natureObservation.assess(); event('test.nature-assessment'); eventValue(value.status); eventValue(value.reason); eventValue(value.score); return nil; }
        if (code == 20303)
        { event('test.nature-history'); eventValue(bleedProfile.natureObservations.length()); eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); eventValue(bleedProfile.plantForageAttempts.length()); return nil; }
        if (code == 20304) { natureObservation.accessible = nil; return nil; }
        return inherited(context);
    }
;
