#include "expanded-compelled-aid.t"
motivationTrait: RpgExpandedLowMotivation approved = true selfControlRating = 6;
modify bleedProfile traits = [motivationTrait];
motivationTrigger: RpgExpandedMotivationTrigger
    id = 'departure-choice' profile = bleedProfile trait = motivationTrait trigger = aidOccurrence
    choices = ['remain','follow-companion'] leastEffort = 'follow-companion' approved = true
    evidence = 'A demanding companion makes following the easier course in this authored scene'
;
motivationDecision: RpgExpandedMotivationDecision source = motivationTrigger choice = 'remain';
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 4400 || code == 4401 || code == 4402)
        {
            local value = code == 4400 ? motivationTrigger.assess() : motivationTrigger.resolve();
            event('test.motivation-trigger'); eventValue(value.status); eventValue(value.reason);
            if (code == 4402) throw new RpgError(); return nil;
        }
        if (code == 4403)
        { local value = motivationDecision.apply(); event('test.motivation-choice'); eventValue(value.status); eventValue(value.reason); return nil; }
        if (code == 4404) { motivationDecision.choice = 'follow-companion'; return nil; }
        if (code == 4405) { motivationTrait.selfControlRating = 12; return nil; }
        if (code == 4406)
        { motivationTrigger.choices = ['eat']; motivationTrigger.leastEffort = 'eat'; motivationTrigger.minimumNecessitiesOnly = true; return nil; }
        if (code == 4407) { motivationTrigger.minimumNecessitiesOnly = true; return nil; }
        if (code == 4408)
        {
            event('test.motivation-state'); eventValue(motivationTrigger.active ? 1 : 0);
            eventValue(bleedProfile.selfControlTriggers.length()); eventValue(motivationTrigger.decision == motivationDecision ? 1 : 0);
            eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
        }
        return inherited(context);
    }
;
