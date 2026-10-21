#include "expanded-recurrent-pain-episode.t"
modify painDay onsetAt = 0 duringSleep = true;
modify bleedProfile awakeClock = 57590;
painNeeds: RpgLiteNeeds profile = bleedProfile active = nil;
painRest: RpgExpandedPainSleeplessRest
    id = 'sleepless-interval' episode = painDay needs = painNeeds seconds = 10
    approved = true evidence = 'Pain prevents sleep during this quiet rest interval'
;
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 4700 || code == 4701 || code == 4702)
        {
            local value = code == 4700 ? painRest.assess() : painRest.apply();
            event('test.pain-sleep'); eventValue(value.status); eventValue(value.reason);
            if (code == 4702) throw new RpgError(); return nil;
        }
        if (code == 4703)
        {
            event('test.pain-sleep-state'); eventValue(bleedProfile.awakeClock); eventValue(bleedProfile.sleepClock);
            eventValue(bleedProfile.sleepDebt); eventValue(bleedProfile.fatigue); eventValue(painNeeds.elapsed);
            eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); eventValue(painDay.sleeplessRests.length());
            eventValue(bleedProfile.recurrentPainPenalty()); return nil;
        }
        if (code == 4704)
        {
            event('test.pain-sleep-direct');
            try { rpgLiteRest(bleedProfile,10,nil,nil,true,nil); eventValue('accepted'); }
            catch (RpgExpandedError error) { eventValue(error.reason); }
            eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        return inherited(context);
    }
;
