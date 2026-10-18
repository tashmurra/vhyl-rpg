#include "expanded-physiology-skill.t"
biologyCatalogue: RpgExpandedBiologySkill techLevel = 8 specialty = 'habitable';
alienBiology: RpgExpandedBiologySkill techLevel = 8 specialty = 'rocky';
alienBiologyTraining: RpgTraining skill = alienBiology points = 24;
fieldNaturalist: RpgExpandedNaturalistSkill planet = 'home' planetType = 'habitable' specialty = 'home';
fieldNaturalistTraining: RpgTraining skill = fieldNaturalist points = 20;
modify PhysicianFixtureAction
    exec(context)
    {
        local code = healthInput.code;
        if (code == 20000)
        { event('test.biology-score'); eventValue(crossPhysician.skillScore(biologyCatalogue)); eventValue(rpgRandom.draws); return nil; }
        if (code == 20001) { crossPhysician.nativePlanetType = 'habitable'; return nil; }
        if (code == 20002) { crossPhysician.nativePlanetType = 'rocky'; return nil; }
        if (code == 20003) { crossPhysician.skills = [alienBiologyTraining]; return nil; }
        if (code == 20004) { crossPhysician.skills = [fieldNaturalistTraining]; return nil; }
        if (code == 20005) { alienBiology.techLevel = 7; return nil; }
        if (code == 20006) { fieldNaturalist.planetType = 'rocky'; return nil; }
        if (code == 20007) { alienBiologyTraining.points = 0; return nil; }
        return inherited(context);
    }
;
