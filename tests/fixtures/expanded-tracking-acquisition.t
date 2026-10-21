#include "expanded-tracking-context.t"
trackingTrailFixture: object;
trackingOccurrenceFixture: object;
trackingAcquisitionFixture: RpgExpandedTrackingAcquisition id = 'acquire-trail' profile = crossPhysician context = trackingContextFixture
    trail = trackingTrailFixture occurrence = trackingOccurrenceFixture seconds = 30 approved = true
    evidence = 'The character examines this accessible trail at the authored acquisition point';
trackingDuplicateFixture: RpgExpandedTrackingAcquisition id = 'duplicate-acquisition' profile = crossPhysician context = trackingContextFixture
    trail = trackingTrailFixture occurrence = trackingOccurrenceFixture seconds = 30 approved = true evidence = 'A duplicate request for the same attempt';
modify PhysicianFixtureAction
    exec(context)
    {
        local code = healthInput.code;
        if (code == 28500 || code == 28501)
        { trackingAcquisitionFixture.resolve(); if (code == 28501) throw new RpgError(); return nil; }
        if (code == 28502)
        { event('test.tracking-acquisition'); eventValue(crossPhysician.trackingAcquisitions.length());
          eventValue(trackingAcquisitionFixture.result == nil ? nil : trackingAcquisitionFixture.result.acquired);
          eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil; }
        if (code == 28503)
        { local value = trackingAcquisitionFixture.assess(); event('test.tracking-preview'); eventValue(value.status); eventValue(value.reason); eventValue(value.score); return nil; }
        if (code == 28504) { trackingDuplicateFixture.resolve(); return nil; }
        if (code == 28505) { trackingAcquisitionFixture.result.acquired = nil; trackingAcquisitionFixture.assess(); return nil; }
        if (code == 28506) { trackingContextFixture.trailAgeSeconds = 90000; trackingAcquisitionFixture.assess(); return nil; }
        return inherited(context);
    }
;
