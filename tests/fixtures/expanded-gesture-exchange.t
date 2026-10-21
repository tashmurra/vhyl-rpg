#include "expanded-speech-limitation.t"
#include <vhyl-rpg-expanded-social.t>
gestureRecipient: RpgExpandedProfile rules = bleedRules;
gestureExchange: RpgExpandedGestureExchange
    id = 'warn-crossing' sender = bleedProfile recipient = gestureRecipient
    playerParticipants = true gesture = 'Point to the broken bridge, then hold up a palm'
    intendedMeaning = 'Stop before the bridge' interpretedMeaning = 'Wait here'
    interpretation = 'understood' observed = true approved = true
    evidence = 'Both players chose these meanings in the authored scene' seconds = 10
;
modify rpgLedger
    afterAdvance(previous)
    {
        inherited(previous);
        if (bleedInput.code == 3908) gestureRecipient.unconscious = true;
        return nil;
    }
;
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 3900 || code == 3901 || code == 3902 || code == 3908)
        {
            local value = code == 3900 ? gestureExchange.assess() : gestureExchange.apply();
            event('test.gesture-exchange'); eventValue(value.status); eventValue(value.reason);
            if (code == 3902) throw new RpgError(); return nil;
        }
        if (code == 3903)
        {
            event('test.gesture-state'); eventValue(bleedProfile.gestureExchanges.length());
            eventValue(gestureRecipient.gestureExchanges.length()); eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws);
            eventValue(gestureRecipient.unconscious ? 1 : 0);
            eventValue(gestureExchange.result == nil ? nil : gestureExchange.result.interpretation); return nil;
        }
        if (code == 3904) { gestureExchange.interpretation = 'misunderstood'; return nil; }
        if (code == 3905) { gestureExchange.interpretation = 'unresolved'; gestureExchange.interpretedMeaning = nil; return nil; }
        if (code == 3906) { gestureExchange.observed = nil; return nil; }
        if (code == 3907) { gestureExchange.sharedSigningLanguage = true; return nil; }
        return inherited(context);
    }
;
