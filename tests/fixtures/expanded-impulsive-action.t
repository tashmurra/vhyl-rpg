#include "expanded-fear-mental.t"
impulsiveTrait: RpgExpandedImpulsiveAction approved = true;
impulsiveOpen: object;
impulsivePlan: object;
impulsiveUnclassified: object;
impulsiveDoor: object opened = nil planned = nil;
impulsiveTrigger: RpgExpandedImpulsiveActionTrigger id = 'sealed-door' profile = fearProfile trait = impulsiveTrait
    trigger = 'first-door-decision' waitingWise = true immediateActions = [impulsiveOpen] deliberativeActions = [impulsivePlan]
    evidence = 'Discussing the unknown mechanism before touching it would be wise';
modify FearTestAction
    exec(context)
    {
        local code = fearInput.code;
        if (code == 870)
        { mentalAward.trait = impulsiveTrait; fearProfile.creationComplete = true;
          fearProfile.earnedPoints = 9; fearProfile.unspentPoints = 7; return nil; }
        if (code == 871 || code == 872)
        { impulsiveTrigger.resolve(); if (code == 872) throw new RpgError(); return nil; }
        if (code == 873 || code == 874 || code == 875)
        {
            local chosen = code == 874 ? impulsivePlan : impulsiveOpen;
            if (!impulsiveTrigger.permits(chosen)) { event('test.impulsive-denied'); return nil; }
            if (impulsiveTrigger.completedAt == nil)
            {
                rpgSpendTime(1);
                if (chosen == impulsiveOpen) impulsiveDoor.opened = true; else impulsiveDoor.planned = true;
            }
            impulsiveTrigger.recordAction(chosen,'Executed the selected scene action');
            if (code == 875) throw new RpgError(); return nil;
        }
        if (code == 876)
        {
            event('test.impulsive'); eventValue(impulsiveTrigger.active ? 1 : 0);
            eventValue(impulsiveDoor.opened ? 1 : 0); eventValue(impulsiveDoor.planned ? 1 : 0);
            eventValue(impulsiveTrigger.completedAt); eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws);
            eventValue(impulsiveTrigger.permits(impulsiveUnclassified) ? 1 : 0); return nil;
        }
        if (code == 877) { fearEventInput.initialRoll = 13; return nil; }
        if (code == 878)
        {
            event('test.impulsive-prices');
            foreach (local rating in [6,9,12,15])
            {
                local trait = rpgExpandedTemplateTraits.rated('impulsive-action',1,nil,rating);
                local copy = rpgExpandedTemplateTraits.copy(trait);
                eventValue(copy.creationCost()); eventValue(copy != trait ? 1 : 0);
            }
            return nil;
        }
        if (code == 879) { impulsiveTrigger.deliberativeActions = [impulsiveOpen]; return nil; }
        if (code == 880) { impulsiveTrigger.completedAction = impulsivePlan; impulsiveTrigger.assess(); return nil; }
        if (code == 881)
        { impulsiveTrigger.completedAt = 0; impulsiveTrigger.resolve(); return nil; }
        if (code == 882) { impulsiveTrait.selfControlRating = 9; mentalAward.tableTotal = 35; return nil; }
        if (code == 890) { impulsiveTrait.mitigated = true; return nil; }
        if (code == 891) { impulsiveTrait.mitigated = nil; return nil; }
        if (code == 892) { impulsiveTrait.active = nil; return nil; }
        return inherited(context);
    }
;
