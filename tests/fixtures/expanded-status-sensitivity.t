#include "expanded-fear-mental.t"
sensitivityTrait: RpgExpandedStatusSensitivity approved = true selfControlRating = 6;
sensitivityOpen: object;
sensitivityPlan: object;
sensitivityUnclassified: object;
sensitivityPerson: RpgLiteProfile;
sensitivityDoor: object struck = nil waited = nil;
sensitivityRage: RpgLiteTrait id = 'uncontrolled-rage' points = -10 level = 1;
sensitivityTrigger: RpgExpandedStatusSensitivityTrigger id = 'frustrating-door' profile = fearProfile trait = sensitivityTrait
    trigger = 'first-door-decision' clearSlight = true person = sensitivityPerson stressor = sensitivityPerson hostileActions = [sensitivityOpen] restrainedActions = [sensitivityPlan]
    evidence = 'The person clearly snubs the character; slamming the door on that person is the hostile response';
modify FearTestAction
    exec(context)
    {
        local code = fearInput.code;
        if (code == 870)
        { mentalAward.trait = sensitivityTrait; fearProfile.creationComplete = true;
          fearProfile.earnedPoints = 9; fearProfile.unspentPoints = 7; fearEventInput.initialRoll = 3; return nil; }
        if (code == 871 || code == 872)
        { sensitivityTrigger.resolve(); if (code == 872) throw new RpgError(); return nil; }
        if (code == 873 || code == 874 || code == 875)
        {
            local chosen = code == 874 ? sensitivityPlan : sensitivityOpen;
            if (!sensitivityTrigger.permits(chosen)) { event('test.sensitivity-denied'); return nil; }
            if (sensitivityTrigger.completedAt == nil)
            {
                rpgSpendTime(1);
                if (chosen == sensitivityOpen) sensitivityDoor.struck = true; else sensitivityDoor.waited = true;
            }
            sensitivityTrigger.recordAction(chosen,'Executed the selected scene action');
            if (code == 875) throw new RpgError(); return nil;
        }
        if (code == 876)
        {
            event('test.sensitivity'); eventValue(sensitivityTrigger.active ? 1 : 0);
            eventValue(sensitivityDoor.struck ? 1 : 0); eventValue(sensitivityDoor.waited ? 1 : 0);
            eventValue(sensitivityTrigger.completedAt); eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws);
            eventValue(sensitivityTrigger.permits(sensitivityUnclassified) ? 1 : 0); return nil;
        }
        if (code == 877) { fearEventInput.initialRoll = 13; return nil; }
        if (code == 878)
        {
            event('test.sensitivity-prices');
            foreach (local rating in [6,9,12,15])
            {
                local trait = rpgExpandedTemplateTraits.rated('status-sensitivity',1,nil,rating);
                local copy = rpgExpandedTemplateTraits.copy(trait);
                eventValue(copy.creationCost()); eventValue(copy != trait ? 1 : 0);
            }
            return nil;
        }
        if (code == 879) { sensitivityTrigger.restrainedActions = [sensitivityOpen]; return nil; }
        if (code == 880) { sensitivityTrigger.completedAction = sensitivityPlan; sensitivityTrigger.assess(); return nil; }
        if (code == 881)
        { sensitivityTrigger.completedAt = 0; sensitivityTrigger.resolve(); return nil; }
        if (code == 883) { sensitivityTrigger.stressor = nil; return nil; }
        if (code == 884) { fearProfile.traits = fearProfile.traits + [sensitivityRage]; return nil; }
        if (code == 885)
        { local v = sensitivityTrigger.assess(); event('test.sensitivity-preview'); eventValue(v.status); eventValue(v.reason); return nil; }
        if (code == 886) { fearProfile.traits = fearProfile.traits + [mentalVoices]; return nil; }
        if (code == 887)
        { event('test.sensitivity-voices'); eventValue(fearProfile.phantomVoiceOccurrences.length());
          eventValue(rpgRandom.draws); return nil; }
        if (code == 890) { sensitivityTrait.mitigated = true; return nil; }
        if (code == 891) { sensitivityTrait.mitigated = nil; return nil; }
        if (code == 892) { sensitivityTrait.active = nil; return nil; }
        if (code == 893) { sensitivityTrigger.person = fearProfile; sensitivityTrigger.stressor = fearProfile; return nil; }
        if (code == 894) { sensitivityTrigger.clearSlight = nil; return nil; }
        return inherited(context);
    }
;
