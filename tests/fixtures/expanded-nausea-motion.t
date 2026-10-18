#include "expanded-nausea-trigger.t"
modify nauseaFirst durationSeconds = nil;
motionExposure: RpgExpandedNauseaMotion id = 'voyage-motion' profile = radiationProfile
    approved = true evidence = 'Continuing motion capable of causing motion sickness';
firstMotionHour: RpgExpandedNauseaMotionHour eventId = 'voyage-hour-one' profile = radiationProfile motion = motionExposure
    observedAt = 3600 approved = true evidence = 'One complete hour in continuing motion' episode = triggerRetching;
secondMotionHour: RpgExpandedNauseaMotionHour eventId = 'voyage-hour-two' profile = radiationProfile motion = motionExposure
    observedAt = 7200 approved = true evidence = 'A second complete hour in continuing motion';
modify RadiationTestAction
    exec(context)
    {
        local code = radiationInput.code;
        if (code == 60) { motionExposure.apply(); return nil; }
        if (code == 61) { motionExposure.assess(); return nil; }
        if (code == 62 || code == 68)
        {
            firstMotionHour.apply(); if (code == 68) throw new RpgError(); return nil;
        }
        if (code == 63) { secondMotionHour.apply(); return nil; }
        if (code == 65) { motionExposure.endEvidence = 'The vehicle stopped'; motionExposure.end(); return nil; }
        if (code == 66) { nauseaFirst.endEvidence = 'The nausea cause resolved'; nauseaFirst.end(); return nil; }
        if (code == 64)
        {
            event('test.nausea-motion'); eventValue(motionExposure.hours.length()); eventValue(motionExposure.nextCheckAt);
            eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds);
            eventValue(radiationProfile.retchingEpisode != nil ? 1 : 0); eventValue(radiationProfile.fatigue);
            eventValue(motionExposure.endedAt != nil ? 1 : 0); return nil;
        }
        return inherited(context);
    }
;
