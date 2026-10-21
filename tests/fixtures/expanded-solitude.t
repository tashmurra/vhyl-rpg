#include "expanded-fear-mental.t"
solitudeTrait: RpgExpandedSolitude approved = true selfControlRating = 6;
solitudeOpen: object;
solitudePlan: object;
solitudeUnclassified: object;
solitudePerson: RpgLiteProfile;
solitudeDoor: object struck = nil waited = nil;
solitudeRage: RpgLiteTrait id = 'uncontrolled-rage' points = -10 level = 1;
solitudeTrigger: RpgExpandedSolitudeTrigger id = 'frustrating-door' profile = fearProfile trait = solitudeTrait
    trigger = 'first-door-decision' proximityUnwanted = true person = solitudePerson stressor = solitudePerson hostileActions = [solitudeOpen] restrainedActions = [solitudePlan]
    evidence = 'The person lingers uninvited; slamming the door on the visitor is a hostile response';
modify FearTestAction
    exec(context)
    {
        local code = fearInput.code;
        if (code == 870)
        { mentalAward.trait = solitudeTrait; fearProfile.creationComplete = true;
          fearProfile.earnedPoints = 9; fearProfile.unspentPoints = 7; fearEventInput.initialRoll = 3; return nil; }
        if (code == 871 || code == 872)
        { solitudeTrigger.resolve(); if (code == 872) throw new RpgError(); return nil; }
        if (code == 873 || code == 874 || code == 875)
        {
            local chosen = code == 874 ? solitudePlan : solitudeOpen;
            if (!solitudeTrigger.permits(chosen)) { event('test.solitude-denied'); return nil; }
            if (solitudeTrigger.completedAt == nil)
            {
                rpgSpendTime(1);
                if (chosen == solitudeOpen) solitudeDoor.struck = true; else solitudeDoor.waited = true;
            }
            solitudeTrigger.recordAction(chosen,'Executed the selected scene action');
            if (code == 875) throw new RpgError(); return nil;
        }
        if (code == 876)
        {
            event('test.solitude'); eventValue(solitudeTrigger.active ? 1 : 0);
            eventValue(solitudeDoor.struck ? 1 : 0); eventValue(solitudeDoor.waited ? 1 : 0);
            eventValue(solitudeTrigger.completedAt); eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws);
            eventValue(solitudeTrigger.permits(solitudeUnclassified) ? 1 : 0); return nil;
        }
        if (code == 877) { fearEventInput.initialRoll = 13; return nil; }
        if (code == 878)
        {
            event('test.solitude-prices');
            foreach (local rating in [6,9,12,15])
            {
                local trait = rpgExpandedTemplateTraits.rated('solitude',1,nil,rating);
                local copy = rpgExpandedTemplateTraits.copy(trait);
                eventValue(copy.creationCost()); eventValue(copy != trait ? 1 : 0);
            }
            return nil;
        }
        if (code == 879) { solitudeTrigger.restrainedActions = [solitudeOpen]; return nil; }
        if (code == 880) { solitudeTrigger.completedAction = solitudePlan; solitudeTrigger.assess(); return nil; }
        if (code == 881)
        { solitudeTrigger.completedAt = 0; solitudeTrigger.resolve(); return nil; }
        if (code == 883) { solitudeTrigger.stressor = nil; return nil; }
        if (code == 884) { fearProfile.traits = fearProfile.traits + [solitudeRage]; return nil; }
        if (code == 885)
        { local v = solitudeTrigger.assess(); event('test.solitude-preview'); eventValue(v.status); eventValue(v.reason); return nil; }
        if (code == 886) { fearProfile.traits = fearProfile.traits + [mentalVoices]; return nil; }
        if (code == 887)
        { event('test.solitude-voices'); eventValue(fearProfile.phantomVoiceOccurrences.length());
          eventValue(rpgRandom.draws); return nil; }
        if (code == 890) { solitudeTrait.mitigated = true; return nil; }
        if (code == 891) { solitudeTrait.mitigated = nil; return nil; }
        if (code == 892) { solitudeTrait.active = nil; return nil; }
        if (code == 893) { solitudeTrigger.person = fearProfile; solitudeTrigger.stressor = fearProfile; return nil; }
        if (code == 894) { solitudeTrigger.proximityUnwanted = nil; return nil; }
        return inherited(context);
    }
;
