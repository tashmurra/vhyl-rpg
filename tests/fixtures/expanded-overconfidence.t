#include "expanded-fear-mental.t"
confidenceTrait: RpgExpandedOverconfidence approved = true selfControlRating = 6;
confidenceOpen: object;
confidencePlan: object;
confidenceUnclassified: object;
confidenceDoor: object opened = nil planned = nil;
confidenceTrigger: RpgExpandedOverconfidenceTrigger id = 'sealed-door' profile = fearProfile trait = confidenceTrait
    trigger = 'first-door-decision' cautionUnreasonable = true confidentActions = [confidenceOpen] cautiousActions = [confidencePlan]
    evidence = 'The author judges refusal to approach this manageable challenge unreasonably cautious';
modify FearTestAction
    exec(context)
    {
        local code = fearInput.code;
        if (code == 870)
        { mentalAward.trait = confidenceTrait; fearProfile.creationComplete = true;
          fearProfile.earnedPoints = 9; fearProfile.unspentPoints = 7; fearEventInput.initialRoll = 3; return nil; }
        if (code == 871 || code == 872)
        { confidenceTrigger.resolve(); if (code == 872) throw new RpgError(); return nil; }
        if (code == 873 || code == 874 || code == 875)
        {
            local chosen = code == 874 ? confidencePlan : confidenceOpen;
            if (!confidenceTrigger.permits(chosen)) { event('test.confidence-denied'); return nil; }
            if (confidenceTrigger.completedAt == nil)
            {
                rpgSpendTime(1);
                if (chosen == confidenceOpen) confidenceDoor.opened = true; else confidenceDoor.planned = true;
            }
            confidenceTrigger.recordAction(chosen,'Executed the selected scene action');
            if (code == 875) throw new RpgError(); return nil;
        }
        if (code == 876)
        {
            event('test.confidence'); eventValue(confidenceTrigger.active ? 1 : 0);
            eventValue(confidenceDoor.opened ? 1 : 0); eventValue(confidenceDoor.planned ? 1 : 0);
            eventValue(confidenceTrigger.completedAt); eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws);
            eventValue(confidenceTrigger.permits(confidenceUnclassified) ? 1 : 0); return nil;
        }
        if (code == 877) { fearEventInput.initialRoll = 13; return nil; }
        if (code == 878)
        {
            event('test.confidence-prices');
            foreach (local rating in [6,9,12,15])
            {
                local trait = rpgExpandedTemplateTraits.rated('overconfidence',1,nil,rating);
                local copy = rpgExpandedTemplateTraits.copy(trait);
                eventValue(copy.creationCost()); eventValue(copy != trait ? 1 : 0);
            }
            return nil;
        }
        if (code == 879) { confidenceTrigger.cautiousActions = [confidenceOpen]; return nil; }
        if (code == 880) { confidenceTrigger.completedAction = confidencePlan; confidenceTrigger.assess(); return nil; }
        if (code == 881)
        { confidenceTrigger.completedAt = 0; confidenceTrigger.resolve(); return nil; }
        return inherited(context);
    }
;
