#include "expanded-sustenance-aging-calendar.t"
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 13100)
        {
            sustenanceAgeCalendar.months = sustenanceAgeCalendar.months + [[553,16590]];
            sustenanceAgeCalendar.startDay = 15855; sustenanceAgeCalendar.endDay = 16575;
            sustenanceAgeCalendar.evidence = 'The authored two-year anniversary runs from day fifteen of the starting month to day fifteen of the ending month';
            return nil;
        }
        if (code == 13101)
        {
            local value = sustenanceAging.assessPlan(); event('test.sustenance-aging-dates');
            eventValue(value.oldAgeCalendarDay); eventValue(value.newAgeCalendarDay); eventValue(value.boundaryCalendarDays.length());
            eventValue(value.boundaryCalendarDays[1]); eventValue(value.boundaryCalendarDays[value.boundaryCalendarDays.length()]);
            eventValue(rpgRandom.draws); return nil;
        }
        if (code == 13102) { sustenanceAgeCalendar.endDay = 16590; return nil; }
        return inherited(context);
    }
;
