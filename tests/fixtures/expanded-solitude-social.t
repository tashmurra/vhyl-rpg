#include "expanded-solitude.t"
#include <vhyl-rpg-expanded-social.t>
solitudeSubject: RpgExpandedProfile rules = fearRules;
solitudeSocial: RpgExpandedSolitudeReactionContext subject = solitudeSubject observer = fearProfile
    observerIsNpc = true approved = true evidence = 'The reacting observer is the NPC who owns the solitude trait';
solitudeEncounter: RpgExpandedReactionEncounter id = 'solitude-encounter' subject = solitudeSubject audience = fearProfile;
solitudeAttempt: RpgExpandedObservedReactionAttempt encounter = solitudeEncounter approach = 'greeting' socialContext = solitudeSocial;
modify FearTestAction
    exec(context)
    {
        local code = fearInput.code;
        if (code == 980) { solitudeSubject.reactionEncounters = [solitudeEncounter]; return nil; }
        if (code == 981) { solitudeSocial.observerIsNpc = nil; return nil; }
        if (code == 982 || code == 983)
        { local v = solitudeAttempt.resolve(); event('test.solitude-reaction'); eventValue(v.total);
          if (code == 983) throw new RpgError(); return nil; }
        if (code == 984)
        { event('test.solitude-social'); eventValue(rpgLiteReactionModifier(solitudeSubject,solitudeSocial));
          eventValue(solitudeEncounter.history.length()); eventValue(rpgRandom.draws); return nil; }
        if (code == 987) { solitudeSubject.traits = [rpgExpandedTemplateTraits.copy(solitudeTrait)]; return nil; }
        if (code == 989)
        {
            event('test.solitude-table');
            foreach (local rating in [6,9,12,15])
            { local observer = new RpgExpandedProfile(); observer.rules = fearRules;
              observer.traits = [rpgExpandedTemplateTraits.rated('solitude',1,nil,rating)];
              eventValue(observer.solitudeReactionPenalty()); }
            return nil;
        }
        return inherited(context);
    }
;
