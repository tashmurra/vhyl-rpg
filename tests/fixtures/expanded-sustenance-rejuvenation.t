#include "expanded-sustenance-aging-dates.t"
sustenanceRejuvenation: RpgExpandedDatedRejuvenation id = 'authored-youth' profile = bleedProfile calendarId = 'campaign-years'
    oldAgeYears = 46 newAgeYears = 45 oldAgeCalendarDay = 16575 newAgeCalendarDay = 16400
    effectEvidence = 'The authored effect restores the subject to the confirmed date within the earlier year';
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 13200) { bleedInput.forcedRoll = 18; return nil; }
        if (code == 13201)
        {
            local value = sustenanceRejuvenation.assess(); event('test.sustenance-rejuvenation-preview'); eventValue(value.status);
            eventValue(value.pointGain); eventValue(value.restoredEvents.length()); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 13202 || code == 13203)
        { sustenanceRejuvenation.apply(); if (code == 13203) throw new RpgError(); return nil; }
        if (code == 13204)
        {
            event('test.sustenance-rejuvenation-state'); eventValue(bleedProfile.st); eventValue(bleedProfile.ht);
            eventValue(bleedProfile.rejuvenations.length()); eventValue(bleedProfile.earnedPoints); eventValue(bleedProfile.unspentPoints);
            eventValue(rpgRandom.draws); return nil;
        }
        return inherited(context);
    }
;
