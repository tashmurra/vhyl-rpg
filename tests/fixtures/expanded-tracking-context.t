#include "expanded-sensory-recognition.t"
trackingCatalogue: RpgExpandedTrackingSkill;
trackingContextFixture: RpgExpandedTrackingContext skill = trackingCatalogue terrain = 'woodland' trailAvailable = true approved = true
    evidence = 'Ordinary unconcealed tracks remain accessible in this terrain';
naturalHistoryFixture: RpgExpandedNaturalistSkill planet = 'home' planetType = 'habitable' specialty = 'home';
unrelatedNatureFixture: RpgExpandedSkill id = 'natural-history' attribute = rpgIQ difficulty = 2 defaultPenalty = -6;
unrelatedNatureTraining: RpgExpandedTraining skill = unrelatedNatureFixture points = 24;
naturalHistoryTraining: RpgExpandedTraining skill = naturalHistoryFixture points = 24;
modify PhysicianFixtureAction
    exec(context)
    {
        local code = healthInput.code;
        if (code == 28400)
        { local terrain = rpgExpandedTrackingTerrain(trackingContextFixture.terrain); event('test.tracking-context');
          eventValue(rpgLiteScore(crossPhysician,trackingContextFixture)); eventValue(terrain.interval); eventValue(terrain.modifier);
          eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil; }
        if (code == 28401) { trackingContextFixture.terrain = 'desert'; return nil; }
        if (code == 28402) { trackingContextFixture.terrain = 'swamp'; return nil; }
        if (code == 28403) { trackingContextFixture.terrain = 'urban'; return nil; }
        if (code == 28404) { trackingContextFixture.trailAgeSeconds = 86400; return nil; }
        if (code == 28405) { trackingContextFixture.trailAgeSeconds = 86401; return nil; }
        if (code == 28406) { trackingContextFixture.trailAgeSeconds = 604800; return nil; }
        if (code == 28407) { trackingContextFixture.trailAgeSeconds = 604801; return nil; }
        if (code == 28408) { trackingContextFixture.subjectCategory = 'human-single'; return nil; }
        if (code == 28409) { trackingContextFixture.subjectCategory = 'human-group'; return nil; }
        if (code == 28410) { trackingContextFixture.scentBonusApplicable = true; return nil; }
        if (code == 28411) { trackingContextFixture.visualBonusApplicable = true; crossPhysician.traits = crossPhysician.traits + [rpgLiteMakeTrait('acute-vision',2,nil)]; return nil; }
        if (code == 28412) { trackingContextFixture.concealedTrail = true; return nil; }
        if (code == 28413) { trackingContextFixture.trailAvailable = nil; return nil; }
        if (code == 28414) { crossPhysician.skills = [naturalHistoryTraining]; return nil; }
        if (code >= 28420 && code <= 28428)
        { local terrains = ['jungle','plains','woodland','arctic','desert','coast','mountain','swamp','urban'];
          trackingContextFixture.terrain = terrains[code-28419]; return nil; }
        if (code == 28415) { crossPhysician.skills = [unrelatedNatureTraining]; return nil; }
        if (code == 28416) { naturalHistoryTraining.points = 0; return nil; }
        if (code == 28417) { naturalHistoryFixture.planetType = nil; rpgLiteScore(crossPhysician,trackingContextFixture); return nil; }
        return inherited(context);
    }
;
