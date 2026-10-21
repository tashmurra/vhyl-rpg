#include "expanded-terrain-search.t"
visionContextFixture: RpgExpandedVisionContext withinHorizon = true withinVisualArc = true ordinarySightAvailable = true
    approved = true evidence = 'The visible hillside is inside the ordinary visual arc and horizon';
visionObservationFixture: RpgExpandedVisionObservation id = 'hillside-view' profile = crossPhysician context = visionContextFixture
    target = healthRoom occurrence = terrainOccurrence;
modify PhysicianFixtureAction
    exec(context)
    {
        local code = healthInput.code;
        if (code == 27100)
        { event('test.vision-score'); eventValue(rpgLiteScore(crossPhysician,visionContextFixture)); eventValue(rpgRandom.draws); return nil; }
        if (code == 27101) { visionContextFixture.distanceHundredths = 1000; visionContextFixture.plainSight = true; return nil; }
        if (code == 27102) { visionContextFixture.task = 'identify'; return nil; }
        if (code == 27103) { visionContextFixture.darkness = 5; return nil; }
        if (code == 27104) { crossPhysician.traits = [rpgLiteMakeTrait('night-vision',3,nil)]; return nil; }
        if (code == 27105) { visionContextFixture.darkness = 10; return nil; }
        if (code == 27106) { crossPhysician.traits = [rpgLiteMakeTrait('acute-vision',2,nil)]; return nil; }
        if (code == 27107)
        { crossPhysician.traits = [rpgLiteMakeTrait('bad-sight',1,nil)]; visionContextFixture.badSightMode = 'near'; return nil; }
        if (code == 27108) { visionContextFixture.distanceHundredths = 200; return nil; }
        if (code == 27109) { visionContextFixture.badSightMode = 'far'; return nil; }
        if (code == 27110) { visionContextFixture.withinHorizon = nil; return nil; }
        if (code == 27111) { visionContextFixture.withinVisualArc = nil; return nil; }
        if (code == 27112) { visionContextFixture.ordinarySightAvailable = nil; return nil; }
        if (code == 27120 || code == 27121)
        { visionObservationFixture.resolve(); if (code == 27121) throw new RpgError(); return nil; }
        if (code == 27122)
        { event('test.vision-state'); eventValue(crossPhysician.visionObservations.length());
          eventValue(visionObservationFixture.result == nil ? nil : visionObservationFixture.result.noticed);
          eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil; }
        if (code == 27123)
        { visionObservationFixture.result.noticed = nil; visionObservationFixture.assess(); return nil; }
        return inherited(context);
    }
;
