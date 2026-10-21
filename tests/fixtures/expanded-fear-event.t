#include "expanded-fear.t"
fearOccurrence: object;
ownedFearEvent: RpgExpandedFearEvent id = 'apparition' occurrence = fearOccurrence context = fearContext;
duplicateFearEvent: RpgExpandedFearEvent id = 'duplicate' occurrence = fearOccurrence context = fearContext;
fearEventInput: object initialRoll = 11 tableRoll = 3 rolls = 0;
fearImmunity: RpgLiteTrait id = 'unfazeable' level = 1;
modify rpgRandom
    roll()
    {
        self.draws += 3; fearEventInput.rolls += 1;
        return fearEventInput.rolls == 1 ? fearEventInput.initialRoll : fearEventInput.tableRoll;
    }
;
modify FearTestAction
    exec(context)
    {
        local code = fearInput.code;
        if (code == 300 || code == 301)
        { ownedFearEvent.resolve(); if (code == 301) throw new RpgError(); return nil; }
        if (code == 302)
        { local v = ownedFearEvent.assess(); event('test.fear-event-preview'); eventValue(v.status); eventValue(v.reason); return nil; }
        if (code == 303 || code == 304)
        { ownedFearEvent.applyConsequence(fearEpisode); if (code == 304) throw new RpgError(); return nil; }
        if (code == 305)
        {
            local v = ownedFearEvent.result; event('test.fear-event'); eventValue(fearProfile.fearEvents.length());
            eventValue(v == nil ? nil : v.score); eventValue(v == nil || v.check == nil ? nil : v.check.roll);
            eventValue(v == nil ? nil : v.tableTotal); eventValue(v == nil ? nil : v.row);
            eventValue(ownedFearEvent.consequence == nil ? 0 : 1); eventValue(fearProfile.mentalStun ? 1 : 0);
            eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
        }
        if (code == 306) { fearEventInput.initialRoll = 10; return nil; }
        if (code == 307) { fearProfile.traits = [fearImmunity]; return nil; }
        if (code == 308) { ownedFearEvent.result.tableTotal = 40; ownedFearEvent.assess(); return nil; }
        if (code == 309) { duplicateFearEvent.resolve(); return nil; }
        if (code == 310) { fearEventInput.tableRoll = 17; return nil; }
        if (code == 311)
        { local v = ownedFearEvent.assessConsequence(fearEpisode); event('test.fear-event-consequence');
          eventValue(v.status); eventValue(v.reason); return nil; }
        if (code == 312) { fearEpisode.tableTotal = 10; ownedFearEvent.applyConsequence(fearEpisode); return nil; }
        return inherited(context);
    }
;
