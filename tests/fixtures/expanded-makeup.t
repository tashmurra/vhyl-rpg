#include "expanded-disguise-skill.t"
makeupCatalogue: RpgExpandedMakeupSkill techLevel = 8;
makeupContextFixture: RpgExpandedMakeupContext skill = makeupCatalogue subject = beggingObserver
    presentation = 'An older stage character with silver brows' approved = true evidence = 'Prepared theatrical makeup without height changes';
makeupApplicationFixture: RpgExpandedMakeupApplication id = 'stage-makeup' profile = crossPhysician context = makeupContextFixture
    seconds = 600 materialsAvailable = true permitted = true;
modify PhysicianFixtureAction
    exec(context)
    {
        local code = healthInput.code;
        if (code == 25600 || code == 25601)
        { makeupApplicationFixture.apply(); if (code == 25601) throw new RpgError(); return nil; }
        if (code == 25602)
        { local value = makeupApplicationFixture.assess(); event('test.makeup-preview'); eventValue(value.status); eventValue(value.reason); return nil; }
        if (code == 25603)
        { event('test.makeup-state'); eventValue(beggingObserver.makeupPresentation == makeupApplicationFixture ? 1 : 0);
          eventValue(crossPhysician.makeupApplications.length()); eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil; }
        if (code == 25604) { makeupContextFixture.heightChange = 1; return nil; }
        if (code == 25605) { makeupCatalogue.techLevel = 5; makeupContextFixture.prosthetics = true; return nil; }
        if (code == 25606) { rpgRandom.medicalRoll = 18; return nil; }
        if (code == 25607)
        { crossPhysician.skills = [disguiseTraining]; event('test.makeup-default'); eventValue(crossPhysician.skillScore(makeupCatalogue)); return nil; }
        return inherited(context);
    }
;
