#include "expanded-sustenance-dose.t"
sustenanceDeadline: RpgExpandedSustenanceDeadline id = 'next-dose' source = sustenanceEpisode
    approved = true evidence = 'The author confirms the next period boundary after restored access';
sustenanceMissed: RpgExpandedSustenanceDeprivation id = 'later-missed-dose' profile = bleedProfile requirement = sustenanceTrait
    approved = true evidence = 'No sufficient dose was ingested during the next period';
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 12100)
        {
            sustenanceTrait.frequency = 'monthly'; sustenanceDeadline.calendarId = 'campaign-calendar';
            sustenanceDeadline.boundaryId = 'second-month'; sustenanceDeadline.calendarDueAt = 2419200; return nil;
        }
        if (code == 12101)
        {
            local value = sustenanceDeadline.assess(); event('test.sustenance-deadline-preview');
            eventValue(value.status); eventValue(value.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 12102 || code == 12103)
        { sustenanceDeadline.register(); if (code == 12103) throw new RpgError(); return nil; }
        if (code == 12104)
        {
            while (rpgLedger.seconds < sustenanceDeadline.dueAt) rpgSpendTime(86400); return nil;
        }
        if (code == 12105)
        {
            event('test.sustenance-deadline-boundary');
            try { rpgLedger.validateAdvance(1); eventValue('accepted'); }
            catch (RpgExpandedError error) { eventValue(error.reason); } return nil;
        }
        if (code == 12106 || code == 12107)
        { sustenanceDeadline.miss(sustenanceMissed); if (code == 12107) throw new RpgError(); return nil; }
        if (code == 12108)
        {
            event('test.sustenance-deadline-state'); eventValue(bleedProfile.sustenanceDeadlines.length());
            eventValue(bleedProfile.sustenanceDeprivations.length()); eventValue(sustenanceDeadline.missedEpisode == nil ? 0 : 1);
            eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        return inherited(context);
    }
;
