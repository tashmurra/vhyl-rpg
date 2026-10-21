#include "expanded-fear-stress.t"
startlingVoices: RpgExpandedPhantomVoiceOccurrence id = 'startling-voices' profile = fearProfile stressor = fearOccurrence
    approved = true evidence = 'An authored stressful moment calls for a voice occurrence check';
startlingCue: object;
startlingContext: RpgExpandedVoiceFearContext profile = fearProfile voiceOccurrence = startlingVoices cue = startlingCue
    approved = true evidence = 'The active disturbing voices suddenly sound immediately behind the character';
voiceFear: RpgExpandedFearEvent id = 'voice-fear' context = startlingContext occurrence = startlingCue;
modify FearTestAction
    exec(context)
    {
        local code = fearInput.code;
        if (code == 540)
        { eventVoices.level = 2; eventVoices.points = -10; fearProfile.traits = [eventVoices];
          fearEventInput.initialRoll = 6; fearEventInput.tableRoll = 11; return nil; }
        if (code == 541) { startlingVoices.resolve(); return nil; }
        if (code == 542 || code == 545) { voiceFear.resolve(); if (code == 545) throw new RpgError(); return nil; }
        if (code == 543)
        { event('test.voice-fear'); eventValue(fearProfile.phantomVoiceOccurrences.length()); eventValue(fearProfile.fearEvents.length());
          eventValue(voiceFear.result == nil ? nil : voiceFear.result.row); eventValue(rpgRandom.draws); return nil; }
        if (code == 544) { startlingVoices.end(true,'The voices cease before a fear cue is presented'); return nil; }
        return inherited(context);
    }
;
