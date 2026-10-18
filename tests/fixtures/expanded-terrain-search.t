#include "expanded-geography.t"
geologyCatalogue: RpgExpandedGeologySkill specialty = 'habitable' techLevel = 8;
terrainSurvival: RpgExpandedSurvivalSkill planet = 'home' planetType = 'habitable' specialty = 'woodlands';
terrainContext: RpgExpandedTerrainSearchContext skill = geologyCatalogue planet = 'home' planetType = 'habitable' feature = 'flowing-water';
terrainOccurrence: object;
terrainSearchFixture: RpgExpandedTerrainSearch id = 'basin-survey' profile = crossPhysician context = terrainContext
    site = healthRoom occurrence = terrainOccurrence featureExists = true direction = 'down the eastern gully'
    seconds = 30 approved = true evidence = 'Visible terrain indicates an existing stream in the eastern gully';
modify PhysicianFixtureAction
    exec(context)
    {
        local code = healthInput.code;
        if (code == 27000 || code == 27001)
        { terrainSearchFixture.resolve(); if (code == 27001) throw new RpgError(); return nil; }
        if (code == 27002)
        { local value = terrainSearchFixture.assess(); event('test.terrain-preview'); eventValue(value.status); eventValue(value.reason); return nil; }
        if (code == 27003)
        { event('test.terrain-search'); eventValue(crossPhysician.terrainSearches.length());
          eventValue(terrainSearchFixture.result == nil ? nil : terrainSearchFixture.result.direction);
          eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil; }
        if (code == 27004) { rpgRandom.medicalRoll = 18; return nil; }
        if (code == 27005) { terrainSearchFixture.featureExists = nil; terrainSearchFixture.direction = nil; return nil; }
        if (code == 27006) { terrainContext.feature = 'mountain-pass'; return nil; }
        if (code == 27007) { terrainContext.skill = terrainSurvival; return nil; }
        if (code == 27008) { terrainContext.planetType = 'rocky'; return nil; }
        if (code == 27009) { crossPhysician.fatigue = crossPhysician.maxEnergy; rpgRandom.medicalRoll = 13; return nil; }
        if (code == 27010)
        { terrainSearchFixture.result.direction = 'rewritten'; terrainSearchFixture.assess(); return nil; }
        if (code == 27011)
        { geographySource.skill = geographyPhysical; crossPhysician.skills = [geographySource];
          event('test.geology-default'); eventValue(crossPhysician.skillScore(geologyCatalogue)); return nil; }
        return inherited(context);
    }
;
