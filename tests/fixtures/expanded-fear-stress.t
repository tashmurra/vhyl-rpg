#include "expanded-fear-event-traits.t"
eventVoices: RpgExpandedPhantomVoices approved = true;
modify FearTestAction
    exec(context)
    {
        local code = fearInput.code;
        if (code == 330) { fearProfile.traits = [eventVoices]; return nil; }
        if (code == 331) { fearEventInput.initialRoll = 9; return nil; }
        if (code == 332) { fearProfile.traits = [eventVoices,fearImmunity]; return nil; }
        if (code == 333)
        {
            event('test.fear-stress'); eventValue(fearProfile.phantomVoiceOccurrences.length());
            eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds);
            eventValue(ownedFearEvent.result == nil || ownedFearEvent.result.stressFollowup == nil ? 0 : 1); return nil;
        }
        if (code == 334)
        { ownedFearEvent.result.stressFollowup.stressor = fearOccurrence; ownedFearEvent.assess(); return nil; }
        return inherited(context);
    }
;
