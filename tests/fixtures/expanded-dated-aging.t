#include "expanded-sustenance-injury.t"
datedAgingFirst: RpgExpandedAgingEvent profile = bleedProfile calendarId = 'ordinary-calendar' boundaryId = 'year-seventy'
    ageYears = 70 calendarDay = 25200 ordinal = 1 reached = true evidence = 'The authored seventieth birthday has occurred';
datedAgingSecond: RpgExpandedAgingEvent profile = bleedProfile calendarId = 'ordinary-calendar' boundaryId = 'seventy-and-half'
    ageYears = 70 calendarDay = 25380 ordinal = 2 reached = true evidence = 'The next authored six-month boundary has occurred';
datedAgingYouth: RpgExpandedDatedRejuvenation id = 'precise-youth' profile = bleedProfile calendarId = 'ordinary-calendar'
    oldAgeYears = 70 newAgeYears = 70 oldAgeCalendarDay = 25470 newAgeCalendarDay = 25290
    effectEvidence = 'The authored effect returns the subject to the stated earlier date within the same year';
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 13300) { bleedInput.forcedRoll = 11; datedAgingFirst.apply(); datedAgingSecond.apply(); return nil; }
        if (code == 13301)
        {
            local value = datedAgingYouth.assess(); event('test.dated-aging-preview');
            eventValue(value.status); eventValue(value.pointGain); eventValue(value.restoredEvents.length()); return nil;
        }
        if (code == 13302 || code == 13303)
        { datedAgingYouth.apply(); if (code == 13303) throw new RpgError(); return nil; }
        if (code == 13304)
        {
            event('test.dated-aging-state'); eventValue(bleedProfile.st); eventValue(bleedProfile.ht);
            eventValue(bleedProfile.rejuvenations.length()); eventValue(datedAgingFirst.restoredBy == nil ? 0 : 1);
            eventValue(datedAgingSecond.restoredBy == nil ? 0 : 1); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 13305) { datedAgingSecond.calendarDay = 25200; return nil; }
        if (code == 13306)
        {
            event('test.dated-aging-binding');
            try { datedAgingYouth.assess(); eventValue('accepted'); }
            catch (RpgExpandedError error) { eventValue(error.reason); } return nil;
        }
        return inherited(context);
    }
;
