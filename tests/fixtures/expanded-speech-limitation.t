#include "expanded-learning-bar.t"
speechLimitation: RpgExpandedSpeechLimitation approved = true;
speechVoice: RpgLiteTrait id = 'voice' points = 10;
modify bleedProfile traits = [speechLimitation];
speechContext: RpgLiteContext skill = learningSkill requiresSpeech = true;
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 3800)
        {
            event('test.speech-preview'); eventValue(speechLimitation.creationCost());
            eventValue(rpgLiteScore(bleedProfile,speechContext)); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 3801)
        {
            local value = rpgLiteCheck(bleedProfile,speechContext);
            event('test.speech-check'); eventValue(value.reason); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 3802) { speechContext.requiresSpeech = nil; speechContext.requiresVocalization = true; return nil; }
        if (code == 3803) { speechLimitation.total = true; speechLimitation.points = -25; return nil; }
        if (code == 3804) { speechContext.requiresSpeech = nil; speechContext.requiresVocalization = nil; return nil; }
        if (code == 3805) { speechLimitation.mitigated = true; return nil; }
        if (code == 3806) { bleedProfile.traits = [speechLimitation,speechVoice]; return nil; }
        if (code == 3807) { speechVoice.id = 'stuttering'; return nil; }
        if (code == 3808)
        {
            event('test.speech-validation');
            try { bleedProfile.validateFeatures(); eventValue('valid'); }
            catch (RpgExpandedError error) { eventValue(error.reason); }
            return nil;
        }
        if (code == 3809)
        {
            event('test.speech-effort'); eventValue(bleedProfile.healthEffortReason('talk',nil,true,nil));
            return nil;
        }
        return inherited(context);
    }
;
