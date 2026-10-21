#include "expanded-fear-event-traits.t"
emitterProfile: RpgExpandedProfile rules = fearRules traits = [eventAura];
eventAura: RpgExpandedFearAura approved = true;
auraFirstContext: RpgExpandedFearAuraContext profile = fearProfile auraOwner = emitterProfile aura = eventAura
    perceived = true activated = true approved = true evidence = 'The character sees the activated pattern';
auraNextContext: RpgExpandedFearAuraContext profile = fearProfile auraOwner = emitterProfile aura = eventAura
    perceived = true activated = true approved = true evidence = 'The character sees a later activation';
auraNextOccurrence: object;
auraNextEvent: RpgExpandedFearEvent id = 'later-pattern' context = auraNextContext occurrence = auraNextOccurrence;
modify ownedFearEvent context = auraFirstContext;
modify FearTestAction
    exec(context)
    {
        local code = fearInput.code;
        if (code == 350) { fearEventInput.initialRoll = 10; return nil; }
        if (code == 351)
        { local v = auraNextContext.assess(); event('test.fear-aura'); eventValue(v.status); eventValue(v.reason);
          eventValue(v.immune ? 1 : 0); eventValue(v.score); eventValue(v.modifier); eventValue(rpgRandom.draws); return nil; }
        if (code == 352) { rpgSpendTime(3599); return nil; }
        if (code == 353) { rpgSpendTime(86400); return nil; }
        if (code == 354) { auraNextEvent.resolve(); return nil; }
        if (code == 355) { eventAura.penalty = 2; eventAura.alwaysOn = true; eventAura.touchOnly = true; return nil; }
        if (code == 356) { event('test.aura-price'); eventValue(eventAura.creationCost()); return nil; }
        if (code == 357) { auraNextContext.activated = nil; return nil; }
        if (code == 358) { auraNextContext.contactEstablished = true; auraNextContext.touching = true; return nil; }
        if (code == 359) { eventAura.alwaysOn = true; return nil; }
        return inherited(context);
    }
;
