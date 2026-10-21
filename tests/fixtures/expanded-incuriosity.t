#include "expanded-fear-mental.t"
incuriousTrait: RpgExpandedIncuriosity approved = true selfControlRating = 6;
incuriousPerson: object;
incuriousOpen: object;
incuriousPlan: object;
incuriousUnclassified: object;
incuriousDoor: object ignored = nil investigated = nil;
incuriousTrigger: RpgExpandedIncuriosityTrigger id = 'sealed-door' profile = fearProfile trait = incuriousTrait
    trigger = 'first-door-decision' strangeConfirmed = true novelty = incuriousPerson ignoreActions = [incuriousOpen] investigationActions = [incuriousPlan]
    evidence = 'Ignoring the strange mechanism leaves it unexplored; examining it is the investigation choice';
modify FearTestAction
    exec(context)
    {
        local code = fearInput.code;
        if (code == 870)
        { mentalAward.trait = incuriousTrait; fearProfile.creationComplete = true;
          fearProfile.earnedPoints = 9; fearProfile.unspentPoints = 7; fearEventInput.initialRoll = 3; return nil; }
        if (code == 871 || code == 872)
        { incuriousTrigger.resolve(); if (code == 872) throw new RpgError(); return nil; }
        if (code == 873 || code == 874 || code == 875)
        {
            local chosen = code == 874 ? incuriousPlan : incuriousOpen;
            if (!incuriousTrigger.permits(chosen)) { event('test.incurious-denied'); return nil; }
            if (incuriousTrigger.completedAt == nil)
            {
                rpgSpendTime(1);
                if (chosen == incuriousOpen) incuriousDoor.ignored = true; else incuriousDoor.investigated = true;
            }
            incuriousTrigger.recordAction(chosen,'Executed the selected scene action');
            if (code == 875) throw new RpgError(); return nil;
        }
        if (code == 876)
        {
            event('test.incurious'); eventValue(incuriousTrigger.active ? 1 : 0);
            eventValue(incuriousDoor.ignored ? 1 : 0); eventValue(incuriousDoor.investigated ? 1 : 0);
            eventValue(incuriousTrigger.completedAt); eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws);
            eventValue(incuriousTrigger.permits(incuriousUnclassified) ? 1 : 0); return nil;
        }
        if (code == 877) { fearEventInput.initialRoll = 13; return nil; }
        if (code == 878)
        {
            event('test.incurious-prices');
            foreach (local rating in [6,9,12,15])
            {
                local trait = rpgExpandedTemplateTraits.rated('incuriosity',1,nil,rating);
                local copy = rpgExpandedTemplateTraits.copy(trait);
                eventValue(copy.creationCost()); eventValue(copy != trait ? 1 : 0);
            }
            return nil;
        }
        if (code == 879) { incuriousTrigger.investigationActions = [incuriousOpen]; return nil; }
        if (code == 880) { incuriousTrigger.completedAction = incuriousPlan; incuriousTrigger.assess(); return nil; }
        if (code == 881)
        { incuriousTrigger.completedAt = 0; incuriousTrigger.resolve(); return nil; }
        if (code == 882) { incuriousTrigger.strangeConfirmed = nil; return nil; }
        if (code == 885) { local v = incuriousTrigger.assess(); event('test.incurious-preview'); eventValue(v.status); eventValue(v.reason); return nil; }
        if (code == 890) { incuriousTrait.mitigated = true; return nil; }
        if (code == 891) { incuriousTrait.mitigated = nil; return nil; }
        if (code == 892) { incuriousTrait.active = nil; return nil; }
        return inherited(context);
    }
;
