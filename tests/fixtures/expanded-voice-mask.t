#include "expanded-phantom-voices.t"
voiceMask: RpgExpandedVoiceSoundMask id = 'overwhelming-voices' occurrence = voiceOccurrence approved = true
    evidence = 'The author establishes that the voices drown out ordinary sound';
voiceMaskOtherStressor: object;
voiceMaskOtherEpisode: RpgExpandedPhantomVoiceOccurrence id = 'second-alarm' profile = bleedProfile
    stressor = voiceMaskOtherStressor approved = true evidence = 'A distinct stressful occurrence';
voiceMaskOther: RpgExpandedVoiceSoundMask id = 'other-mask' occurrence = voiceMaskOtherEpisode
    approved = true evidence = 'The second episode also masks sound';
voiceHearing: RpgLiteContext attribute = rpgPerception kind = 'hearing';
voiceSpeech: RpgLiteContext attribute = rpgIQ understandsSpeech = true;
voiceReading: RpgLiteContext attribute = rpgIQ understandsSpeech = true written = true;
voiceVisual: RpgLiteContext attribute = rpgIQ understandsSpeech = true auditoryInput = 'none';
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 10300)
        {
            bleedProfile.traits = [voiceTrait]; voiceTrait.level = 2; voiceTrait.points = -10;
            bleedInput.forcedRoll = 6; voiceOccurrence.resolve(); return nil;
        }
        if (code == 10301) { event('test.voice-mask-preview'); eventValue(voiceMask.assess().status); eventValue(rpgRandom.draws); return nil; }
        if (code == 10302 || code == 10303)
        {
            voiceMask.begin(); if (code == 10303) throw new RpgError(); return nil;
        }
        if (code == 10304)
        {
            event('test.voice-mask-state'); eventValue(voiceOccurrence.soundMasks.length());
            eventValue(bleedProfile.voiceSoundMasked() ? 1 : 0); eventValue(bleedProfile.timeElapsed); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 10305)
        {
            event('test.voice-mask-scores');
            foreach (local task in [voiceHearing,voiceSpeech,voiceReading,voiceVisual]) eventValue(rpgLiteScore(bleedProfile,task));
            local check = rpgLiteCheck(bleedProfile,voiceHearing); eventValue(check.reason); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 10306) { voiceMask.end(true,'Ordinary sounds are audible again'); return nil; }
        if (code == 10307) { voiceOccurrence.end(true,'The episode has ceased'); return nil; }
        if (code == 10308) { voiceTrait.mitigated = true; return nil; }
        if (code == 10309) { voiceMaskOtherEpisode.resolve(); voiceMaskOther.begin(); return nil; }
        return inherited(context);
    }
;
