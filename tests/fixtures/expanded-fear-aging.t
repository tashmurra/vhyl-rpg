#include "expanded-fear-physical.t"
#include <vhyl-rpg-expanded-skills.t>
#include <vhyl-rpg-expanded-hazards.t>
fearAge: RpgExpandedFearAging profile = fearProfile years = 5 calendarId = 'local-calendar'
    oldAgeMonths = 540 medicalTL = 8 approved = true evidence = 'The character is exactly forty-five before the incident';
fearYouth: RpgExpandedRejuvenation id = 'youth' profile = fearProfile calendarId = 'local-calendar'
    oldAgeYears = 50 newAgeYears = 45 effectEvidence = 'An authored effect restores the pre-incident age';
fearAgeRuling: RpgExpandedFearAgingRuling owner = fearAge losses = [0,0,0,1] approved = true
    evidence = 'At an unrollable boundary the author selects one point of health loss and no other loss';
modify physicalAward aging = fearAge;
modify rpgRandom roll() { self.draws += 3; return 18; };
modify FearTestAction
    exec(context)
    {
        local code = fearInput.code;
        if (code == 600) { fearProfile.creationComplete = true; physicalAward.tableTotal = 24; return nil; }
        if (code == 601)
        { local v = physicalAward.assess(); event('test.fear-aging-preview'); eventValue(v.status); eventValue(v.reason); return nil; }
        if (code == 602 || code == 603)
        { physicalAward.apply(); if (code == 603) throw new RpgError(); return nil; }
        if (code == 604)
        {
            event('test.fear-aging'); eventValue(fearProfile.fearAgingHistory.length()); eventValue(fearProfile.agingHistory.length());
            eventValue(fearProfile.st); eventValue(fearProfile.dx); eventValue(fearProfile.iq); eventValue(fearProfile.ht);
            eventValue(fearProfile.postCreationDisadvantageAllowance()); eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds);
            eventValue(fearProfile.developmentRevision); return nil;
        }
        if (code == 605) { fearYouth.apply(); return nil; }
        if (code == 606) { fearAge.boundaries = []; fearAge.assess(); return nil; }
        if (code == 607) { fearAge.years = 6; fearAge.assess(); return nil; }
        if (code == 609) { fearProfile.ht = 2; fearAge.medicalTL = 3; fearAge.lowScoreRuling = fearAgeRuling; return nil; }
        if (code == 608) { fearProfile.validateFeatures(); return nil; }
        return inherited(context);
    }
;
