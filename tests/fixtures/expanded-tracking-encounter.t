#include "expanded-march-steps.t"
modify trackingContextFixture terrain = 'urban' subjectCategory = 'human-group';
modify trackingAcquisitionFixture seconds = 0;
trackingEncounterFixture: RpgExpandedTrackingEncounter id = 'follow-trail' acquisition = trackingAcquisitionFixture;
firstFollowContext: RpgExpandedTrackingContext skill = trackingCatalogue terrain = 'urban' subjectCategory = 'human-group'
    trailAgeSeconds = 30 trailAvailable = true approved = true evidence = 'The same unconcealed trail remains accessible';
secondFollowContext: RpgExpandedTrackingContext skill = trackingCatalogue terrain = 'urban' subjectCategory = 'human-group'
    trailAgeSeconds = 60 trailAvailable = true approved = true evidence = 'The same unconcealed trail remains accessible';
modify firstMarchStep seconds = 30;
modify lastMarchStep seconds = 30;
firstFollowStep: RpgExpandedTrackingStep id = 'first-half' encounter = trackingEncounterFixture context = firstFollowContext march = firstMarchStep;
secondFollowStep: RpgExpandedTrackingStep id = 'second-half' encounter = trackingEncounterFixture context = secondFollowContext march = lastMarchStep;
thirdFollowContext: RpgExpandedTrackingContext skill = trackingCatalogue terrain = 'urban' subjectCategory = 'human-group'
    trailAgeSeconds = 90 trailAvailable = true approved = true evidence = 'A further portion of the same trail';
thirdFollowMarch: RpgExpandedMarchStep id = 'third-half' progress = stepProgress seconds = 30;
thirdFollowStep: RpgExpandedTrackingStep id = 'third-half' encounter = trackingEncounterFixture context = thirdFollowContext march = thirdFollowMarch;
modify PhysicianFixtureAction
    exec(context)
    {
        local code = healthInput.code;
        if (code == 28800) { trackingEncounterFixture.start(); return nil; }
        if (code == 28801) { firstFollowStep.resolve(); return nil; }
        if (code == 28802 || code == 28803)
        { secondFollowStep.resolve(); if (code == 28803) throw new RpgError(); return nil; }
        if (code == 28804)
        { event('test.tracking-encounter'); eventValue(trackingEncounterFixture.steps.length()); eventValue(trackingEncounterFixture.elapsed());
          eventValue(trackingEncounterFixture.lost() ? 1 : 0); eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws);
          eventValue(stepProgress.elapsed); eventValue(crossPhysician.fatigue); return nil; }
        if (code == 28805) { lastMarchStep.seconds = 31; return nil; }
        if (code == 28806) { secondFollowContext.trailAgeSeconds = 59; return nil; }
        if (code == 28807) { secondFollowContext.terrain = 'woodland'; return nil; }
        if (code == 28808)
        { secondFollowStep.result.check.roll += 1; trackingEncounterFixture.validate(); return nil; }
        if (code == 28809)
        { local value = secondFollowStep.assess(); event('test.follow-preview'); eventValue(value.status); eventValue(value.reason); return nil; }
        if (code == 28810) { thirdFollowStep.resolve(); return nil; }
        return inherited(context);
    }
;
