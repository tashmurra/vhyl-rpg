#include "expanded-self-control.t"
avoidanceTrait: RpgExpandedDangerAvoidance approved = true selfControlRating = 12;
modify bleedProfile traits = [avoidanceTrait];
avoidanceRisk: object;
avoidanceRetreat: object;
avoidanceTrigger: RpgExpandedDangerAvoidanceTrigger id = 'exposed-crossing' profile = bleedProfile trait = avoidanceTrait
    trigger = 'original-crossing-offer' physicalDanger = true riskyActions = [avoidanceRisk]
    evidence = 'The authored crossing presents physical danger';
avoidanceFear: RpgExpandedFearContext profile = bleedProfile approved = true physicalRisk = true
    evidence = 'The extraordinary threat includes physical danger';
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 700)
        {
            local value = avoidanceFear.assess(); event('test.avoidance-fear');
            eventValue(value.modifier); eventValue(value.score); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 701 || code == 702)
        { avoidanceTrigger.resolve(); if (code == 702) throw new RpgError(); return nil; }
        if (code == 703)
        {
            event('test.avoidance'); eventValue(avoidanceTrigger.active ? 1 : 0);
            eventValue(avoidanceTrigger.permits(avoidanceRisk) ? 1 : 0);
            eventValue(avoidanceTrigger.permits(avoidanceRetreat) ? 1 : 0);
            eventValue(avoidanceTrigger.check == nil ? nil : avoidanceTrigger.check.score);
            eventValue(bleedProfile.selfControlTriggers.length()); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 704) { avoidanceTrigger.risksDeath = true; return nil; }
        if (code == 705)
        { avoidanceTrigger.greaterDanger = true; avoidanceTrigger.greaterDangerEvidence = 'Remaining exposes the actor to a greater physical threat'; return nil; }
        if (code == 706) { avoidanceTrigger.greaterDanger = true; return nil; }
        if (code == 707) { avoidanceFear.physicalRisk = nil; return nil; }
        if (code == 708) { avoidanceFear.cowardicePenalty = 2; return nil; }
        if (code == 709) { avoidanceFear.cowardicePenalty = 4; return nil; }
        if (code == 710)
        {
            event('test.avoidance-purchases');
            foreach (local rating in [6,9,12,15])
            {
                local trait = rpgExpandedTemplateTraits.rated('cowardice',1,nil,rating);
                bleedProfile.traits = [trait]; local value = avoidanceFear.assess();
                eventValue(trait.creationCost()); eventValue(value.modifier); eventValue(value.score);
            }
            bleedProfile.traits = [avoidanceTrait]; return nil;
        }
        if (code == 711)
        {
            event('test.avoidance-conflict');
            try { avoidanceFear.assess(); eventValue('unexpected-success'); }
            catch (RpgExpandedError error) { eventValue(error.reason); }
            eventValue(rpgRandom.draws); return nil;
        }
        return inherited(context);
    }
;
