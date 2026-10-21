#include "expanded-status-sensitivity.t"
#include <vhyl-rpg-expanded-social.t>
sensitivitySubject: RpgExpandedProfile rules = fearRules;
sensitivitySocial: RpgExpandedStatusSensitivityReactionContext subject = sensitivitySubject observer = fearProfile
    observerIsNpc = true perceivedSlight = true approved = true evidence = 'The reacting observer is the NPC who owns the sensitivity trait';
sensitivityEncounter: RpgExpandedReactionEncounter id = 'sensitivity-encounter' subject = sensitivitySubject audience = fearProfile;
sensitivityAttempt: RpgExpandedObservedReactionAttempt encounter = sensitivityEncounter approach = 'greeting' socialContext = sensitivitySocial;
sensitivityOutburst: RpgExpandedStatusOutburstObservation id = 'actual-outburst' subject = fearProfile observer = sensitivityPerson
    trigger = sensitivityTrigger badReactionApplies = true approved = true evidence = 'The offended person reacts badly to the committed hostile response';
sensitivityOutburstContext: RpgExpandedObservedReactionContext subject = fearProfile observer = sensitivityPerson observations = [sensitivityOutburst];
sensitivityOutburstEncounter: RpgExpandedReactionEncounter id = 'outburst-encounter' subject = fearProfile audience = sensitivityPerson;
sensitivityOutburstAttempt: RpgExpandedObservedReactionAttempt encounter = sensitivityOutburstEncounter approach = 'after-outburst'
    socialContext = sensitivityOutburstContext;
modify FearTestAction
    exec(context)
    {
        local code = fearInput.code;
        if (code == 980) { sensitivitySubject.reactionEncounters = [sensitivityEncounter]; return nil; }
        if (code == 981) { sensitivitySocial.observerIsNpc = nil; return nil; }
        if (code == 982 || code == 983)
        { local v = sensitivityAttempt.resolve(); event('test.sensitivity-reaction'); eventValue(v.total);
          if (code == 983) throw new RpgError(); return nil; }
        if (code == 984)
        { event('test.sensitivity-social'); eventValue(rpgLiteReactionModifier(sensitivitySubject,sensitivitySocial));
          eventValue(sensitivityEncounter.history.length()); eventValue(rpgRandom.draws); return nil; }
        if (code == 987) { sensitivitySubject.traits = [rpgExpandedTemplateTraits.copy(sensitivityTrait)]; return nil; }
        if (code == 989)
        {
            event('test.sensitivity-table');
            foreach (local rating in [6,9,12,15])
            { local observer = new RpgExpandedProfile(); observer.rules = fearRules;
              observer.traits = [rpgExpandedTemplateTraits.rated('status-sensitivity',1,nil,rating)];
              eventValue(observer.statusSensitivityReactionPenalty()); }
            return nil;
        }
        if (code == 990) { sensitivitySocial.perceivedSlight = nil; return nil; }
        if (code == 991)
        { fearProfile.reactionEncounters = [sensitivityOutburstEncounter]; sensitivityOutburst.record(); return nil; }
        if (code == 992 || code == 993)
        { local v = sensitivityOutburstAttempt.resolve(); event('test.status-outburst-result'); eventValue(v.total);
          if (code == 993) throw new RpgError(); return nil; }
        if (code == 994)
        { event('test.status-outburst'); eventValue(fearProfile.socialObservations.length());
          eventValue(sensitivityOutburstEncounter.history.length()); eventValue(rpgRandom.draws); return nil; }
        if (code == 996)
        { fearProfile.traits = fearProfile.traits + [rpgExpandedTemplateTraits.rated('solitude',1,nil,6)]; return nil; }
        if (code == 995) { sensitivityOutburst.badReactionApplies = nil; return nil; }
        return inherited(context);
    }
;
