#include "expanded-callousness.t"
humorTrait: RpgExpandedHumorlessness approved = true;
observedAudience: RpgLiteProfile;
humorObservation: RpgExpandedHumorlessnessObservation id = 'evident-humorlessness' subject = bleedProfile observer = observedAudience
    evident = true approved = true evidence = 'The observer has seen the subject repeatedly take explicit jokes literally';
humorUnknown: RpgExpandedHumorlessnessObservation id = 'not-evident' subject = bleedProfile observer = observedAudience
    evident = nil approved = true evidence = 'This observer has not encountered the behavior';
callousObservation: RpgExpandedCallousnessObservation id = 'past-treatment' subject = bleedProfile observer = observedAudience
    pastVictim = true approved = true evidence = 'The observer personally experienced callous treatment';
observedContext: RpgExpandedObservedReactionContext subject = bleedProfile observer = observedAudience
    observations = [humorObservation,callousObservation];
observedEncounter: RpgExpandedReactionEncounter id = 'observed-encounter' subject = bleedProfile audience = observedAudience;
observedAttempt: RpgExpandedObservedReactionAttempt encounter = observedEncounter approach = 'greeting' socialContext = observedContext;
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 9800)
        {
            bleedProfile.traits = [humorTrait,callousTrait]; bleedProfile.reactionEncounters = [observedEncounter];
            humorObservation.record(); callousObservation.record(); return nil;
        }
        if (code == 9801)
        {
            event('test.observed-preview'); eventValue(humorTrait.creationCost());
            eventValue(observedContext.traitReactionModifier(bleedProfile)); eventValue(observedAttempt.assess().status);
            eventValue(rpgRandom.draws); return nil;
        }
        if (code == 9802 || code == 9803)
        {
            local value = observedAttempt.resolve(); event('test.observed-result'); eventValue(value.status); eventValue(value.total);
            if (code == 9803) throw new RpgError(); return nil;
        }
        if (code == 9804)
        {
            event('test.observed-state'); eventValue(bleedProfile.socialObservations.length());
            eventValue(observedEncounter.history.length()); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 9805) { observedContext.observations = [humorObservation,humorObservation]; return nil; }
        if (code == 9806)
        {
            event('test.observed-error');
            try { observedAttempt.resolve(); eventValue('accepted'); }
            catch (RpgExpandedError error) { eventValue(error.reason); }
            eventValue(rpgRandom.draws); return nil;
        }
        if (code == 9807) { humorObservation.evident = nil; return nil; }
        if (code == 9808) { humorUnknown.record(); observedContext.observations = [humorUnknown]; return nil; }
        return inherited(context);
    }
;
