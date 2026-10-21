#include "expanded-fear-mental.t"
temperTrait: RpgExpandedVolatileTemper approved = true;
temperOpen: object;
temperPlan: object;
temperUnclassified: object;
temperDoor: object struck = nil waited = nil;
temperRage: RpgLiteTrait id = 'uncontrolled-rage' points = -10 level = 1;
temperTrigger: RpgExpandedVolatileTemperTrigger id = 'frustrating-door' profile = fearProfile trait = temperTrait
    trigger = 'first-door-decision' stressful = true stressor = temperDoor hostileActions = [temperOpen] restrainedActions = [temperPlan]
    evidence = 'The locked mechanism is the identified source of frustration; striking it is a hostile response';
modify FearTestAction
    exec(context)
    {
        local code = fearInput.code;
        if (code == 870)
        { mentalAward.trait = temperTrait; fearProfile.creationComplete = true;
          fearProfile.earnedPoints = 9; fearProfile.unspentPoints = 7; return nil; }
        if (code == 871 || code == 872)
        { temperTrigger.resolve(); if (code == 872) throw new RpgError(); return nil; }
        if (code == 873 || code == 874 || code == 875)
        {
            local chosen = code == 874 ? temperPlan : temperOpen;
            if (!temperTrigger.permits(chosen)) { event('test.temper-denied'); return nil; }
            if (temperTrigger.completedAt == nil)
            {
                rpgSpendTime(1);
                if (chosen == temperOpen) temperDoor.struck = true; else temperDoor.waited = true;
            }
            temperTrigger.recordAction(chosen,'Executed the selected scene action');
            if (code == 875) throw new RpgError(); return nil;
        }
        if (code == 876)
        {
            event('test.temper'); eventValue(temperTrigger.active ? 1 : 0);
            eventValue(temperDoor.struck ? 1 : 0); eventValue(temperDoor.waited ? 1 : 0);
            eventValue(temperTrigger.completedAt); eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws);
            eventValue(temperTrigger.permits(temperUnclassified) ? 1 : 0); return nil;
        }
        if (code == 877) { fearEventInput.initialRoll = 13; return nil; }
        if (code == 878)
        {
            event('test.temper-prices');
            foreach (local rating in [6,9,12,15])
            {
                local trait = rpgExpandedTemplateTraits.rated('bad-temper',1,nil,rating);
                local copy = rpgExpandedTemplateTraits.copy(trait);
                eventValue(copy.creationCost()); eventValue(copy != trait ? 1 : 0);
            }
            return nil;
        }
        if (code == 879) { temperTrigger.restrainedActions = [temperOpen]; return nil; }
        if (code == 880) { temperTrigger.completedAction = temperPlan; temperTrigger.assess(); return nil; }
        if (code == 881)
        { temperTrigger.completedAt = 0; temperTrigger.resolve(); return nil; }
        if (code == 882) { temperTrait.selfControlRating = 9; mentalAward.tableTotal = 35; return nil; }
        if (code == 883) { temperTrigger.stressor = nil; return nil; }
        if (code == 884) { fearProfile.traits = fearProfile.traits + [temperRage]; return nil; }
        if (code == 885)
        { local v = temperTrigger.assess(); event('test.temper-preview'); eventValue(v.status); eventValue(v.reason); return nil; }
        if (code == 886) { fearProfile.traits = fearProfile.traits + [mentalVoices]; return nil; }
        if (code == 887)
        { event('test.temper-voices'); eventValue(fearProfile.phantomVoiceOccurrences.length());
          eventValue(rpgRandom.draws); return nil; }
        return inherited(context);
    }
;
