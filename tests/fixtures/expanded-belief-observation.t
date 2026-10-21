#include "expanded-fixed-beliefs.t"
beliefSituation: object;
beliefPortrayal: RpgExpandedFixedBeliefPortrayal id = 'doorway-portrayal' profile = bleedProfile belief = beliefOne
    situation = beliefSituation decision = 'followed' approved = true
    observedBehavior = 'The subject addresses the unseen observer before opening the door';
beliefObservation: RpgExpandedFixedBeliefObservation id = 'noticed-belief' subject = bleedProfile observer = observedAudience
    portrayal = beliefPortrayal noticed = true approved = true evidence = 'The audience witnessed and noticed the behavior';
beliefUnnoticed: RpgExpandedFixedBeliefObservation id = 'unnoticed-belief' subject = bleedProfile observer = observedAudience
    portrayal = beliefPortrayal noticed = nil approved = true evidence = 'The audience did not notice the relevant behavior';
beliefReaction: RpgExpandedObservedReactionContext subject = bleedProfile observer = observedAudience observations = [beliefObservation];
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 11300) { event('test.belief-portrayal-preview'); eventValue(beliefPortrayal.assess().status); eventValue(rpgRandom.draws); return nil; }
        if (code == 11301 || code == 11302)
        {
            beliefPortrayal.apply(); beliefObservation.record(); if (code == 11302) throw new RpgError(); return nil;
        }
        if (code == 11303)
        {
            event('test.belief-observation'); eventValue(rpgLiteReactionModifier(bleedProfile,beliefReaction));
            eventValue(bleedProfile.fixedBeliefPortrayals.length()); eventValue(bleedProfile.socialObservations.length()); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 11304)
        {
            event('test.belief-portrayal-state'); eventValue(bleedProfile.fixedBeliefPortrayals.length());
            eventValue(bleedProfile.socialObservations.length()); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 11305) { beliefUnnoticed.record(); beliefReaction.observations = [beliefUnnoticed]; return nil; }
        if (code == 11306) { beliefPortrayal.belief.mitigated = true; return nil; }
        if (code == 11307) { beliefReaction.observations = [beliefObservation,beliefUnnoticed]; return nil; }
        if (code == 11308)
        {
            event('test.belief-observation-error');
            try { rpgLiteReactionModifier(bleedProfile,beliefReaction); eventValue('accepted'); }
            catch (RpgExpandedError error) { eventValue(error.reason); } return nil;
        }
        if (code == 11309) { beliefPortrayal.belief = beliefTwo; beliefPortrayal.observedBehavior = 'The subject covers the mirror before discussing the expedition'; return nil; }
        if (code == 11310) { beliefOne.level = 1; bleedProfile.traits = [beliefOne]; return nil; }
        return inherited(context);
    }
;
