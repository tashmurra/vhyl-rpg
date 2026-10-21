#include "expanded-bleeding.t"
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 90)
        {
            event('test.bleeding-timeline');
            eventValue(bleedEpisode.startedAt); eventValue(bleedEpisode.nextCheckAt); eventValue(bleedEpisode.stoppedAt);
            eventValue(bleedEpisode.clearMinutes); eventValue(bleedEpisode.minutes.length());
            eventValue(bleedProfile.bleedingEpisode == bleedEpisode ? 1 : 0);
            eventValue(bleedMinute.resolvedAt);
            eventValue(bleedMinute.result == nil ? nil : bleedMinute.result.injury);
            eventValue(bleedMinute.result == nil ? nil : bleedMinute.result.check.roll);
            eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code >= 91 && code <= 99)
        {
            if (code == 91) bleedEpisode.startedAt += 1;
            if (code == 92) bleedEpisode.nextCheckAt += 60;
            if (code == 93) bleedEpisode.stoppedAt = rpgLedger.seconds;
            if (code == 94) bleedEpisode.clearMinutes += 1;
            if (code == 95) bleedProfile.bleedingEpisode = nil;
            if (code == 96) bleedEpisode.minutes = [];
            if (code == 97) bleedMinute.resolvedAt += 1;
            if (code == 98) bleedMinute.result.injury += 1;
            if (code == 99) bleedMinute.result.check.roll += 1;
            /* Even falsifying stoppedAt must not bypass shared-clock validation. */
            rpgSpendTime(0); return nil;
        }
        return inherited(context);
    }
;
