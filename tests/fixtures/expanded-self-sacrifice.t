#include "expanded-fear-mental.t"
sacrificeTrait: RpgExpandedSelfSacrifice approved = true selfControlRating = 6;
sacrificePerson: RpgLiteProfile;
sacrificeOpen: object;
sacrificePlan: object;
sacrificeUnclassified: object;
sacrificeDoor: object opened = nil planned = nil;
sacrificeTrigger: RpgExpandedSelfSacrificeTrigger id = 'sealed-door' profile = fearProfile trait = sacrificeTrait
    trigger = 'first-door-decision' competingNeeds = true person = sacrificePerson otherFirstActions = [sacrificeOpen] selfFirstActions = [sacrificePlan]
    evidence = 'Opening the shelter admits the other person first; planning reserves it for the actor';
modify FearTestAction
    exec(context)
    {
        local code = fearInput.code;
        if (code == 870)
        { mentalAward.trait = sacrificeTrait; fearProfile.creationComplete = true;
          fearProfile.earnedPoints = 9; fearProfile.unspentPoints = 7; fearEventInput.initialRoll = 3; return nil; }
        if (code == 871 || code == 872)
        { sacrificeTrigger.resolve(); if (code == 872) throw new RpgError(); return nil; }
        if (code == 873 || code == 874 || code == 875)
        {
            local chosen = code == 874 ? sacrificePlan : sacrificeOpen;
            if (!sacrificeTrigger.permits(chosen)) { event('test.sacrifice-denied'); return nil; }
            if (sacrificeTrigger.completedAt == nil)
            {
                rpgSpendTime(1);
                if (chosen == sacrificeOpen) sacrificeDoor.opened = true; else sacrificeDoor.planned = true;
            }
            sacrificeTrigger.recordAction(chosen,'Executed the selected scene action');
            if (code == 875) throw new RpgError(); return nil;
        }
        if (code == 876)
        {
            event('test.sacrifice'); eventValue(sacrificeTrigger.active ? 1 : 0);
            eventValue(sacrificeDoor.opened ? 1 : 0); eventValue(sacrificeDoor.planned ? 1 : 0);
            eventValue(sacrificeTrigger.completedAt); eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws);
            eventValue(sacrificeTrigger.permits(sacrificeUnclassified) ? 1 : 0); return nil;
        }
        if (code == 877) { fearEventInput.initialRoll = 13; return nil; }
        if (code == 878)
        {
            event('test.sacrifice-prices');
            foreach (local rating in [6,9,12,15])
            {
                local trait = rpgExpandedTemplateTraits.rated('self-sacrifice',1,nil,rating);
                local copy = rpgExpandedTemplateTraits.copy(trait);
                eventValue(copy.creationCost()); eventValue(copy != trait ? 1 : 0);
            }
            return nil;
        }
        if (code == 879) { sacrificeTrigger.selfFirstActions = [sacrificeOpen]; return nil; }
        if (code == 880) { sacrificeTrigger.completedAction = sacrificePlan; sacrificeTrigger.assess(); return nil; }
        if (code == 881)
        { sacrificeTrigger.completedAt = 0; sacrificeTrigger.resolve(); return nil; }
        if (code == 882) { sacrificeTrigger.person = fearProfile; return nil; }
        if (code == 885) { local v = sacrificeTrigger.assess(); event('test.sacrifice-preview'); eventValue(v.status); eventValue(v.reason); return nil; }
        if (code == 890) { sacrificeTrait.mitigated = true; return nil; }
        if (code == 891) { sacrificeTrait.mitigated = nil; return nil; }
        if (code == 892) { sacrificeTrait.active = nil; return nil; }
        return inherited(context);
    }
;
