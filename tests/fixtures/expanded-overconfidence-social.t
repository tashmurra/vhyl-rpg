#include "expanded-overconfidence.t"
#include <vhyl-rpg-expanded-social.t>
confidenceAudience: RpgLiteProfile;
confidenceObservation: RpgExpandedOverconfidenceObservation id = 'confidence-audience' subject = fearProfile observer = confidenceAudience
    audienceKind = 'young-or-naive' approved = true evidence = 'The author classifies this observer as naive and impressed by the confidence';
confidenceSocial: RpgExpandedObservedReactionContext subject = fearProfile observer = confidenceAudience observations = [confidenceObservation];
confidenceEncounter: RpgExpandedReactionEncounter id = 'confidence-encounter' subject = fearProfile audience = confidenceAudience;
confidenceAttempt: RpgExpandedObservedReactionAttempt encounter = confidenceEncounter approach = 'greeting' socialContext = confidenceSocial;
modify FearTestAction
    exec(context)
    {
        local code = fearInput.code;
        if (code == 980) { fearProfile.reactionEncounters = [confidenceEncounter]; confidenceObservation.record(); return nil; }
        if (code == 981) { confidenceObservation.audienceKind = 'experienced'; return nil; }
        if (code == 982 || code == 983)
        { local v = confidenceAttempt.resolve(); event('test.confidence-reaction'); eventValue(v.total);
          if (code == 983) throw new RpgError(); return nil; }
        if (code == 984)
        { event('test.confidence-social'); eventValue(confidenceSocial.traitReactionModifier(fearProfile));
          eventValue(confidenceEncounter.history.length()); eventValue(rpgRandom.draws); return nil; }
        if (code == 985) { confidenceSocial.observations = [confidenceObservation,confidenceObservation]; confidenceAttempt.assess(); return nil; }
        return inherited(context);
    }
;
