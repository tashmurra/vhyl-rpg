#include "expanded-boating.t"
entryBoatSkill: RpgExpandedBoatingSkill techLevel = 8 specialty = 'unpowered';
entryBoatTraining: RpgExpandedTraining skill = entryBoatSkill points = 1;
entryBoatContext: RpgExpandedBoatingContext skill = entryBoatSkill eventKind = 'enter';
entryBoatWater: RpgExpandedSwimmingEncounter id = 'boarding-water' profile = boatingHero defaultAvailable = true
    evidence = 'Involuntary fall into water alongside the boat';
entryBoat: RpgExpandedBoatEntry id = 'boarding' profile = boatingHero context = entryBoatContext swimming = entryBoatWater
    approved = true evidence = 'Attempt to step into the small boat';
modify rpgRandom
    boatRoll = 16
    roll() { self.draws += 3; return self.boatRoll; }
;
modify ExpandedTestAction
    exec(context)
    {
        local code = expandedInput.code;
        if (code == 16900 || code == 16901)
        { entryBoat.apply(); if (code == 16901) throw new RpgError(); return nil; }
        if (code == 16902)
        {
            event('test.boat-entry'); eventValue(boatingHero.boatEntries.length()); eventValue(boatingHero.swimmingEncounter == entryBoatWater);
            eventValue(entryBoat.result == nil ? nil : entryBoat.result.boarded); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 16903) { rpgRandom.boatRoll = 3; return nil; }
        if (code == 16904) { boatingHero.skills = [entryBoatTraining]; return nil; }
        if (code == 16905)
        { local value = entryBoat.assess(); event('test.boat-entry-preview'); eventValue(value.status); eventValue(rpgRandom.draws); return nil; }
        return inherited(context);
    }
;
