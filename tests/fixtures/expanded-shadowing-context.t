#include "expanded-sensory-recognition.t"
modify crossPhysician dx = 12;
shadowingCatalogue: RpgExpandedShadowingSkill;
shadowingContextFixture: RpgExpandedShadowingContext skill = shadowingCatalogue crowdAvailable = true approved = true
    evidence = 'The target is being followed through an ordinary crowd';
shadowStealthSkill: RpgExpandedSkill id = 'stealth' attribute = rpgDX difficulty = 1 defaultPenalty = -5;
shadowStealthTraining: RpgExpandedTraining skill = shadowStealthSkill points = 24;
shadowObservationSkill: RpgExpandedSkill id = 'observation' attribute = rpgPerception difficulty = 1 defaultPenalty = -5;
shadowObservationTraining: RpgExpandedTraining skill = shadowObservationSkill points = 24;
modify PhysicianFixtureAction
    exec(context)
    {
        local code = healthInput.code;
        if (code == 29100)
        { event('test.shadowing-score'); eventValue(rpgLiteScore(crossPhysician,shadowingContextFixture));
          eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil; }
        if (code == 29101) { crossPhysician.skills = [shadowStealthTraining]; return nil; }
        if (code == 29102) { shadowingContextFixture.mode = 'vehicle'; return nil; }
        if (code == 29103) { crossPhysician.skills = [shadowObservationTraining]; return nil; }
        if (code == 29104) { shadowingContextFixture.targetKnowsFollower = true; return nil; }
        if (code == 29105) { shadowingContextFixture.noisyTarget = true; return nil; }
        if (code == 29106) { shadowingContextFixture.distinctiveModifier = -2; return nil; }
        if (code == 29107)
        { shadowingContextFixture.visiblyDifferent = true; shadowingContextFixture.sizeDifference = 2; shadowingContextFixture.crowdModifier = -2; return nil; }
        if (code == 29108) { shadowingContextFixture.crowdAvailable = nil; return nil; }
        if (code == 29109) { shadowStealthTraining.points = 0; return nil; }
        if (code == 29110)
        { shadowingContextFixture.crowdModifier = -1; rpgLiteScore(crossPhysician,shadowingContextFixture); return nil; }
        return inherited(context);
    }
;
