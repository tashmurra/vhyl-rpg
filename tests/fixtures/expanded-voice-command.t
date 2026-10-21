#include "expanded-phantom-voices.t"
voiceCommandToken: object;
voiceCommand: RpgExpandedVoiceCommand id = 'destroy-evidence' occurrence = voiceOccurrence command = voiceCommandToken
    instruction = 'Destroy the expedition evidence' underStress = true approved = true
    evidence = 'The author selects resistance to this command during the stressful alarm';
voiceCommandDuplicate: RpgExpandedVoiceCommand id = 'same-command' occurrence = voiceOccurrence command = voiceCommandToken
    instruction = 'Destroy the expedition evidence' underStress = true approved = true
    evidence = 'The same command cannot be rerolled under another identifier';
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 10200)
        {
            bleedProfile.traits = [voiceTrait]; voiceTrait.level = 3; voiceTrait.points = -15;
            bleedInput.forcedRoll = 6; voiceOccurrence.resolve(); bleedInput.forcedRoll = 10; return nil;
        }
        if (code == 10201)
        {
            local value = voiceCommand.assess(); event('test.voice-command-preview'); eventValue(value.status);
            eventValue(value.reason); eventValue(value.score); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 10202 || code == 10203)
        {
            local value = voiceCommand.resolve(); event('test.voice-command-result'); eventValue(value.status);
            eventValue(value.resisted ? 1 : 0); eventValue(value.check == nil ? nil : value.check.roll);
            eventValue(rpgRandom.draws); if (code == 10203) throw new RpgError(); return nil;
        }
        if (code == 10204)
        {
            event('test.voice-command-state'); eventValue(voiceOccurrence.commands.length());
            eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 10205) { bleedInput.forcedRoll = 11; return nil; }
        if (code == 10206) { voiceCommand.underStress = nil; return nil; }
        if (code == 10207) { voiceCommand.intoxicated = true; return nil; }
        if (code == 10208)
        {
            event('test.voice-command-duplicate');
            try { voiceCommandDuplicate.resolve(); eventValue('accepted'); }
            catch (RpgExpandedError error) { eventValue(error.reason); }
            eventValue(rpgRandom.draws); return nil;
        }
        if (code == 10209) { voiceOccurrence.end(true,'The episode has ended'); return nil; }
        if (code == 10210) { voiceTrait.mitigated = true; return nil; }
        return inherited(context);
    }
;
