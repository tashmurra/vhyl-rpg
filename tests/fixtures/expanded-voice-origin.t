#include "expanded-phantom-voices.t"
voiceOrigin: RpgExpandedVoiceOrigin profile = bleedProfile trait = voiceTrait origin = 'possession'
    approved = true evidence = 'Private author confirmation of the supernatural origin';
voiceBuyoffBasis: RpgExpandedBuyoffBasis owner = bleedProfile trait = voiceTrait originalBonus = 5 approved = true
    evidence = 'The original five-point award and the approved cure justify this buyoff';
voiceCure: RpgExpandedVoiceExorcism origin = voiceOrigin successful = true approved = true
    evidence = 'The author confirms the successful exorcism through the campaign procedure';
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 10400)
        {
            bleedProfile.traits = [voiceTrait]; bleedProfile.buyoffBases = [voiceBuyoffBasis];
            bleedProfile.developmentOpen = true; bleedProfile.earnedPoints = 8; bleedProfile.unspentPoints = 8;
            voiceOrigin.record(); bleedInput.forcedRoll = 6; voiceOccurrence.resolve(); return nil;
        }
        if (code == 10401)
        {
            event('test.voice-origin'); eventValue(voiceOrigin.assessPsychotherapy().reason);
            local value = voiceCure.assess(); eventValue(value.status); eventValue(value.reason); eventValue(value.points);
            eventValue(rpgRandom.draws); return nil;
        }
        if (code == 10402 || code == 10403)
        {
            local value = voiceCure.apply(); event('test.voice-cure'); eventValue(value.status); eventValue(value.points);
            if (code == 10403) throw new RpgError(); return nil;
        }
        if (code == 10404)
        {
            event('test.voice-cure-state'); eventValue(bleedProfile.traits.length()); eventValue(bleedProfile.unspentPoints);
            eventValue(voiceOccurrence.active() ? 1 : 0); eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 10405) { bleedProfile.unspentPoints = 4; return nil; }
        if (code == 10406) { bleedProfile.developmentOpen = nil; return nil; }
        if (code == 10407) { voiceBuyoffBasis.approved = nil; return nil; }
        if (code == 10408) { voiceOrigin.origin = 'psychological'; return nil; }
        return inherited(context);
    }
;
