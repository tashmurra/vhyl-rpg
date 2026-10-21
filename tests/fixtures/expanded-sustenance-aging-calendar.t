#include "expanded-sustenance-aging.t"
sustenanceAgeCalendar: RpgExpandedSustenanceAgingCalendar calendarId = 'campaign-years' approved = true
    evidence = 'This authored calendar has thirty-day months in the supplied two-year span' dayBandOrigins = [[45,16200]];
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 13000)
        {
            for (local index = 0; index <= 24; index += 1)
                sustenanceAgeCalendar.months = sustenanceAgeCalendar.months + [[528 + index,15840 + index * 30]];
            sustenanceTrait.acceleratedAging = true; bleedProfile.traits = [sustenanceTrait,sustenanceShort];
            bleedProfile.st = 30; bleedProfile.dx = 30; bleedProfile.iq = 30; bleedProfile.ht = 30;
            sustenanceAging.oldAgeMonths = 528; sustenanceAging.calendar = sustenanceAgeCalendar;
            sustenanceAging.evidence = 'The exact age before this injury is forty-four years in the authored calendar';
            sustenanceTick.agingAdvance = sustenanceAging; sustenanceEpisode.begin(); return nil;
        }
        if (code == 13001)
        {
            local value = sustenanceAging.assessPlan(); event('test.sustenance-calendar-plan');
            eventValue(value.status); eventValue(value.boundaryAgeMonths.length());
            foreach (local day in value.boundaryCalendarDays) eventValue(day);
            eventValue(rpgRandom.draws); return nil;
        }
        if (code == 13002)
        { for (local index = 1; index <= 12; index += 1) sustenanceAging.applyNextBoundary(); return nil; }
        if (code == 13003) { sustenanceAgeCalendar.dayBandOrigins = [[45,16201]]; return nil; }
        if (code == 13004)
        {
            event('test.sustenance-calendar-error');
            try { sustenanceAging.assessPlan(); eventValue('accepted'); }
            catch (RpgExpandedError error) { eventValue(error.reason); } return nil;
        }
        return inherited(context);
    }
;
