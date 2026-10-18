#include "expanded-makeup.t"
makeupNewContext: RpgExpandedMakeupContext skill = makeupCatalogue subject = beggingObserver
    presentation = 'A younger stage character with dark brows' approved = true evidence = 'A new theatrical presentation';
makeupNewApplication: RpgExpandedMakeupApplication id = 'new-stage-makeup' profile = crossPhysician context = makeupNewContext
    seconds = 300 materialsAvailable = true permitted = true;
modify PhysicianFixtureAction
    exec(context)
    {
        local code = healthInput.code;
        if (code == 25700 || code == 25701)
        { local value = makeupApplicationFixture.end('The cosmetic presentation has been removed');
          event('test.makeup-end'); eventValue(value.status); eventValue(value.reason);
          if (code == 25701) throw new RpgError(); return nil; }
        if (code == 25702)
        { event('test.makeup-lifecycle'); eventValue(makeupApplicationFixture.presentationReason());
          eventValue(beggingObserver.makeupPresentation == makeupNewApplication ? 1 : 0);
          eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil; }
        if (code == 25703) { makeupNewApplication.apply(); return nil; }
        if (code == 25704)
        {
            makeupApplicationFixture.endedAt += 1;
            try { makeupApplicationFixture.assess(); }
            catch (RpgExpandedError error) { event('test.makeup-end-error'); eventValue(error.reason); }
            return nil;
        }
        return inherited(context);
    }
;
