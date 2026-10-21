#include "expanded-frenzy-entry.t"
frenzyMajor: RpgExpandedWound id = 'frenzy-major' profile = fearProfile amount = 6;
frenzyRuling: RpgExpandedFrenzyKnockdownRuling wound = frenzyMajor episode = frenzyEpisode
    approved = true evidence = 'Recorded author ruling: retain consciousness without knockdown';
modify FearTestAction
    exec(context)
    {
        local code = fearInput.code;
        if (code == 1330) { frenzyMajor.frenzyRuling = frenzyRuling; return nil; }
        if (code == 1331 || code == 1332)
        { frenzyMajor.apply(); if (code == 1332) throw new RpgError(); return nil; }
        if (code == 1333) { frenzyMajor.assess(); return nil; }
        if (code == 1334)
        {
            event('test.frenzy-knockdown'); eventValue(fearProfile.injury);
            eventValue(fearProfile.stunned ? 1 : 0); eventValue(fearProfile.unconscious ? 1 : 0);
            eventValue(fearProfile.posture); eventValue(frenzyRuling.result == nil ? 0 : 1);
            eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
        }
        if (code == 1335) { frenzyRuling.knockdown = true; frenzyRuling.unconscious = true; return nil; }
        if (code == 1336) { rpgLiteWound(fearProfile,6); return nil; }
        if (code == 1337) { frenzyRuling.evidence = 'Changed'; frenzyMajor.assess(); return nil; }
        if (code == 1338) { frenzyMajor.frenzyRuling = nil; frenzyMajor.assess(); return nil; }
        return inherited(context);
    }
;
