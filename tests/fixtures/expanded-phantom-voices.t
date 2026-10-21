#include "expanded-observed-reactions.t"
voiceTrait: RpgExpandedPhantomVoices approved = true;
voiceStressor: object;
voiceOccurrence: RpgExpandedPhantomVoiceOccurrence id = 'alarm' profile = bleedProfile stressor = voiceStressor
    approved = true evidence = 'The author selects the alarming interruption as a stressful occurrence';
voiceDuplicate: RpgExpandedPhantomVoiceOccurrence id = 'same-alarm' profile = bleedProfile stressor = voiceStressor
    approved = true evidence = 'The same occurrence must not roll twice';
voiceObservation: RpgExpandedPhantomVoiceObservation id = 'heard-response' subject = bleedProfile observer = observedAudience
    occurrence = voiceOccurrence witnessedResponse = true typicalObserver = true approved = true
    evidence = 'The observer witnessed the subject answering an unheard voice';
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 10000) { bleedProfile.traits = [voiceTrait]; return nil; }
        if (code == 10001)
        {
            local copy = rpgExpandedTemplateTraits.copy(voiceTrait);
            event('test.voice-preview'); eventValue(voiceOccurrence.assess().status); eventValue(copy.creationCost());
            eventValue(copy != voiceTrait ? 1 : 0); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 10002 || code == 10003)
        {
            local value = voiceOccurrence.resolve(); event('test.voice-result'); eventValue(value.status);
            eventValue(value.roll); eventValue(value.occurred ? 1 : 0); eventValue(value.severity); eventValue(rpgRandom.draws);
            if (code == 10003) throw new RpgError(); return nil;
        }
        if (code == 10004)
        {
            event('test.voice-state'); eventValue(bleedProfile.phantomVoiceOccurrences.length());
            eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws);
            event('test.voice-times'); eventValue(voiceOccurrence.recordedAt); eventValue(voiceOccurrence.endedAt); return nil;
        }
        if (code == 10005)
        {
            voiceObservation.record(); event('test.voice-observation'); eventValue(voiceObservation.modifier()); return nil;
        }
        if (code == 10006)
        {
            local value = voiceOccurrence.end(true,'The author confirms that the voices have ceased');
            event('test.voice-ending'); eventValue(value.status); eventValue(voiceOccurrence.active() ? 1 : 0); return nil;
        }
        if (code == 10007)
        {
            event('test.voice-duplicate');
            try { voiceDuplicate.resolve(); eventValue('accepted'); }
            catch (RpgExpandedError error) { eventValue(error.reason); }
            eventValue(rpgRandom.draws); return nil;
        }
        if (code == 10008) { bleedInput.forcedRoll = 6; return nil; }
        if (code == 10009) { bleedInput.forcedRoll = 7; return nil; }
        if (code == 10010) { voiceTrait.level = 2; voiceTrait.points = -10; return nil; }
        if (code == 10011) { voiceTrait.level = 3; voiceTrait.points = -15; return nil; }
        if (code == 10012) { rpgSpendTime(7); return nil; }
        return inherited(context);
    }
;
