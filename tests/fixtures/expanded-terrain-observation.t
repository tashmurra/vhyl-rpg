#include "expanded-vision.t"
modify terrainSearchFixture observation = visionObservationFixture observationApplicable = true
    observationEvidence = 'The observed hillside supplies the terrain evidence for this survey';
otherTerrainOccurrence: object;
modify PhysicianFixtureAction
    exec(context)
    {
        local code = healthInput.code;
        if (code == 27200) { visionObservationFixture.profile = beggingObserver; return nil; }
        if (code == 27201) { visionObservationFixture.target = terrainOccurrence; return nil; }
        if (code == 27202) { visionObservationFixture.occurrence = otherTerrainOccurrence; return nil; }
        if (code == 27203) { terrainSearchFixture.observationApplicable = nil; return nil; }
        if (code == 27204) { rpgRandom.medicalRoll = 3; return nil; }
        if (code == 27205)
        { terrainSearchFixture.observation = nil; terrainSearchFixture.assess(); return nil; }
        return inherited(context);
    }
;
