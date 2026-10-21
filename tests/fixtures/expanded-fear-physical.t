#include "expanded-fear-event-traits.t"
physicalPain: RpgExpandedPainSensitivity approved = true;
physicalWound: RpgExpandedPersistentWound approved = true;
physicalSpeech: RpgExpandedSpeechLimitation approved = true;
physicalAward: RpgExpandedFearPhysicalAcquisition id = 'physical' eventId = 'apparition' profile = fearProfile
    approved = true evidence = 'The incident caused the selected lasting physical changes';
modify FearTestAction
    exec(context)
    {
        local code = fearInput.code;
        if (code >= 470 && code <= 472)
        {
            fearProfile.creationComplete = true; fearProfile.disadvantageLimit = 0;
            fearProfile.earnedPoints = 9; fearProfile.unspentPoints = 7;
            if (code == 470) { physicalAward.tableTotal = 24; physicalAward.purchases = [physicalSpeech]; }
            if (code == 471) { physicalAward.tableTotal = 36; physicalAward.purchases = [physicalSpeech,physicalWound]; }
            if (code == 472) { physicalAward.tableTotal = 37; physicalAward.purchases = [physicalPain,physicalSpeech,physicalWound]; }
            return nil;
        }
        if (code == 473 || code == 474) { physicalAward.apply(); if (code == 474) throw new RpgError(); return nil; }
        if (code == 475)
        {
            event('test.fear-physical'); eventValue(fearProfile.traits.length()); eventValue(fearProfile.postCreationDisadvantageAllowance());
            eventValue(fearProfile.speechLimitationLevel()); eventValue(fearProfile.injury); eventValue(fearProfile.developmentRevision);
            eventValue(fearProfile.earnedPoints); eventValue(fearProfile.unspentPoints); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 476) { physicalAward.purchases = [physicalWound]; physicalAward.apply(); return nil; }
        if (code == 477)
        { local c = new RpgLiteContext(); c.attribute = rpgIQ; c.requiresSpeech = true;
          event('test.fear-physical-speech'); eventValue(fearProfile.healthCheckReason(c)); return nil; }
        return inherited(context);
    }
;
