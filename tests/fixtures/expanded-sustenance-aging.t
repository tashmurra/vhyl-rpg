#include "expanded-sustenance-aging-plan.t"
sustenanceAging: RpgExpandedSustenanceAgingAdvance id = 'first-aging-injury' tick = sustenanceTick oldAgeMonths = 588
    calendarId = 'campaign-years' approved = true evidence = 'The exact biological age before this injury is forty-nine years';
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 12800)
        {
            sustenanceTrait.acceleratedAging = true; bleedProfile.traits = [sustenanceTrait,sustenanceAgeless];
            sustenanceTick.agingAdvance = sustenanceAging; sustenanceEpisode.begin(); return nil;
        }
        if (code == 12801)
        {
            event('test.sustenance-aging-price'); eventValue(sustenanceTrait.creationCost());
            eventValue(rpgExpandedTemplateTraits.copy(sustenanceTrait).creationCost()); return nil;
        }
        if (code == 12802)
        { event('test.sustenance-aging-boundary'); eventValue(sustenanceAging.applyNextBoundary().status); return nil; }
        if (code == 12803)
        {
            event('test.sustenance-aging-state'); eventValue(sustenanceAging.plan == nil ? nil : sustenanceAging.plan.newAgeMonths);
            eventValue(sustenanceAging.boundaries.length()); eventValue(bleedProfile.agingHistory.length());
            eventValue(bleedProfile.injury); eventValue(rpgRandom.draws); return nil;
        }
        return inherited(context);
    }
;
