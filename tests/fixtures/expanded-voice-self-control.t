#include "expanded-phantom-voices.t"
voiceControlTrait: RpgExpandedDisadvantage id = 'stressful-behavior' points = -5 controlled = true
    approved = true selfControlRating = 6;
voiceControlTrigger: RpgExpandedSelfControlTrigger id = 'stress-response' profile = bleedProfile trait = voiceControlTrait
    trigger = 'alarm-response' evidence = 'The author confirms this behavior is caused by the stressful alarm';
voiceControlInput: object rolls = [];
modify rpgRandom
    roll()
    {
        if (voiceControlInput.rolls.length() > 0)
        {
            local result = voiceControlInput.rolls[1]; local remaining = [];
            for (local index = 2; index <= voiceControlInput.rolls.length(); index += 1)
                remaining = remaining + [voiceControlInput.rolls[index]];
            voiceControlInput.rolls = remaining; self.draws += 3; return result;
        }
        return inherited();
    }
;
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 10100) { bleedProfile.traits = [voiceTrait,voiceControlTrait]; voiceControlInput.rolls = [10,6]; return nil; }
        if (code == 10101) { voiceControlTrigger.stressRelation = 'stress-related'; return nil; }
        if (code == 10102)
        {
            local value = voiceControlTrigger.assess(); event('test.voice-control-preview');
            eventValue(value.status); eventValue(value.reason); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 10103 || code == 10104)
        {
            local value = voiceControlTrigger.resolve(); event('test.voice-control-result');
            eventValue(value.status); eventValue(value.check == nil ? nil : value.check.roll);
            eventValue(rpgRandom.draws); if (code == 10104) throw new RpgError(); return nil;
        }
        if (code == 10105)
        {
            local occurrence = voiceControlTrigger.phantomVoiceOccurrence;
            event('test.voice-control-state'); eventValue(bleedProfile.selfControlTriggers.length());
            eventValue(bleedProfile.phantomVoiceOccurrences.length()); eventValue(voiceControlTrigger.active ? 1 : 0);
            eventValue(occurrence == nil ? nil : occurrence.result.roll);
            eventValue(occurrence == nil ? 0 : occurrence.active() ? 1 : 0); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 10106) { voiceControlTrigger.stressRelation = 'unrelated'; return nil; }
        if (code == 10107) { voiceControlInput.rolls = [6,6]; return nil; }
        if (code == 10108) { voiceControlTrigger.giveIn = true; return nil; }
        if (code == 10109) { voiceTrait.mitigated = true; return nil; }
        if (code == 10110) { voiceControlInput.rolls = [10,7]; return nil; }
        if (code == 10111)
        {
            bleedRules.pointFundedSelfControl = true; bleedProfile.earnedPoints = 1; bleedProfile.unspentPoints = 1;
            voiceControlTrigger.buySuccess = true; return nil;
        }
        if (code == 10112 || code == 10113 || code == 10114)
        {
            event('test.voice-direct');
            try
            {
                local value = code == 10114 ? rpgLiteFright(bleedProfile,0)
                    : rpgLiteSelfControl(bleedProfile,voiceControlTrait,0,code == 10113);
                eventValue(value.status);
            }
            catch (RpgExpandedError error) { eventValue(error.reason); }
            eventValue(rpgRandom.draws); return nil;
        }
        if (code == 10115) { bleedProfile.traits = [voiceControlTrait]; return nil; }
        return inherited(context);
    }
;
