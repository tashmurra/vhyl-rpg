#include "expanded-incuriosity.t"
#include <vhyl-rpg-expanded-social.t>
incuriousSubject: RpgExpandedProfile rules = fearRules;
incuriousSocial: RpgExpandedIncuriosityReactionContext subject = incuriousSubject observer = fearProfile
    newToObserver = true approved = true evidence = 'The reacting observer is the NPC who owns the incurious trait';
incuriousEncounter: RpgExpandedReactionEncounter id = 'incurious-encounter' subject = incuriousSubject audience = fearProfile;
incuriousAttempt: RpgExpandedObservedReactionAttempt encounter = incuriousEncounter approach = 'greeting' socialContext = incuriousSocial;
modify FearTestAction
    exec(context)
    {
        local code = fearInput.code;
        if (code == 980) { incuriousSubject.reactionEncounters = [incuriousEncounter]; return nil; }
        if (code == 981) { incuriousSocial.newToObserver = nil; return nil; }
        if (code == 982 || code == 983)
        { local v = incuriousAttempt.resolve(); event('test.incurious-reaction'); eventValue(v.total);
          if (code == 983) throw new RpgError(); return nil; }
        if (code == 984)
        { event('test.incurious-social'); eventValue(rpgLiteReactionModifier(incuriousSubject,incuriousSocial));
          eventValue(incuriousEncounter.history.length()); eventValue(rpgRandom.draws); return nil; }
        if (code == 987) { incuriousSubject.traits = [rpgExpandedTemplateTraits.copy(incuriousTrait)]; return nil; }
        if (code == 989)
        {
            event('test.incurious-table');
            foreach (local rating in [6,9,12,15])
            { local observer = new RpgExpandedProfile(); observer.rules = fearRules;
              observer.traits = [rpgExpandedTemplateTraits.rated('incuriosity',1,nil,rating)];
              eventValue(observer.incuriosityActive() ? -1 : 0); }
            return nil;
        }
        return inherited(context);
    }
;
