#include "expanded-self-control.t"
curiosityTrait: RpgExpandedCuriosity approved = true selfControlRating = 9;
modify bleedProfile traits = [curiosityTrait];
curiosityCabinet: object open = nil;
curiosityInspect: object;
curiosityLeave: object;
curiosityOccurrence: RpgExpandedCuriosityTrigger id = 'unfamiliar-cabinet' profile = bleedProfile trait = curiosityTrait
    trigger = 'first-opportunity' subject = curiosityCabinet interesting = true
    investigationActions = [curiosityInspect] evidence = 'An unfamiliar cabinet with an intriguing mechanism';
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 680) { curiosityOccurrence.assess(); return nil; }
        if (code == 681 || code == 682)
        { curiosityOccurrence.resolve(); if (code == 682) throw new RpgError(); return nil; }
        if (code == 683)
        {
            event('test.curiosity'); eventValue(curiosityOccurrence.active ? 1 : 0);
            eventValue(curiosityOccurrence.permits(curiosityInspect) ? 1 : 0);
            eventValue(curiosityOccurrence.permits(curiosityLeave) ? 1 : 0);
            eventValue(curiosityCabinet.open ? 1 : 0); eventValue(curiosityOccurrence.completedAt);
            eventValue(bleedProfile.selfControlTriggers.length()); eventValue(rpgLedger.seconds);
            eventValue(rpgRandom.draws); return nil;
        }
        if (code == 684 || code == 685)
        {
            if (!curiosityOccurrence.permits(curiosityInspect)) return nil;
            if (!curiosityCabinet.open)
            { rpgSpendTime(5); curiosityCabinet.open = true; }
            curiosityOccurrence.complete(curiosityInspect,'Opened and examined the authored cabinet');
            if (code == 685) throw new RpgError(); return nil;
        }
        if (code == 686) { curiosityOccurrence.complete(curiosityLeave,'Walked away'); return nil; }
        if (code == 687) { curiosityOccurrence.giveIn = true; return nil; }
        if (code == 688) { curiosityTrait.selfControlRating = 15; return nil; }
        if (code == 689) { curiosityOccurrence.investigationActions = []; return nil; }
        if (code == 690)
        {
            event('test.curiosity-purchase');
            foreach (local rating in [6,9,12,15])
            {
                local trait = rpgExpandedTemplateTraits.rated('curious',1,nil,rating);
                eventValue(trait.creationCost()); eventValue(trait.selfControlNumber());
                eventValue(trait.ofKind(RpgExpandedCuriosity));
            }
            return nil;
        }
        return inherited(context);
    }
;
