#include "expanded-paralysis.t"
seizureEpisode: RpgExpandedSeizure id = 'fit' profile = bleedProfile durationSeconds = 60
    approved = true evidence = 'An original resolved effect causes a one-minute seizure';
modify rpgRandom
    die() { self.draws += 1; return 4; }
;
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 470) { seizureEpisode.assess(); return nil; }
        if (code == 471 || code == 472)
        { seizureEpisode.apply(); if (code == 472) throw new RpgError(); return nil; }
        if (code == 473 || code == 474)
        { seizureEpisode.finish(); if (code == 474) throw new RpgError(); return nil; }
        if (code == 475)
        {
            event('test.seizure'); eventValue(bleedProfile.seizing() ? 1 : 0);
            eventValue(bleedProfile.posture); eventValue(bleedProfile.fatigue);
            eventValue(bleedProfile.injury); eventValue(bleedProfile.effortHistory.length());
            eventValue(bleedProfile.seizureFatigueLosses.length());
            eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 476) { bleedProfile.posture = 'sitting'; return nil; }
        if (code == 477) { seizureEpisode.assessEnd(); return nil; }
        if (code == 478)
        {
            local check = new RpgLiteContext(); check.attribute = rpgWill; check.kind = 'pain-cry';
            event('test.seizure-pain-cry'); eventValue(rpgLiteScore(bleedProfile,check)); return nil;
        }
        return inherited(context);
    }
;
