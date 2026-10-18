#include "expanded-coughing.t"
paralysisEpisode: RpgExpandedParalysis id = 'paralyzed' profile = bleedProfile durationSeconds = 60
    positionAssessed = true balanced = nil approved = true evidence = 'An original effect paralyzes an unbalanced standing patient';
paralysisMental: RpgExpandedActionGate id = 'mental-power' profile = bleedProfile mentalAbility = true
    evidence = 'An already defined mental ability requires neither speech nor movement';
paralysisAction: RpgExpandedActionGate id = 'ordinary-action' profile = bleedProfile evidence = 'An ordinary physical action';
paralysisTalk: RpgExpandedEffort id = 'speech' profile = bleedProfile purpose = 'talk' evidence = 'An attempt to speak';
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 450) { paralysisEpisode.assess(); return nil; }
        if (code == 451 || code == 452)
        { paralysisEpisode.apply(); if (code == 452) throw new RpgError(); return nil; }
        if (code == 453)
        {
            local check = new RpgLiteContext(); check.attribute = rpgDX;
            event('test.paralysis'); eventValue(bleedProfile.paralyzed() ? 1 : 0);
            eventValue(bleedProfile.unconscious ? 1 : 0); eventValue(bleedProfile.posture);
            eventValue(rpgLiteScore(bleedProfile,check)); check.attribute = rpgIQ;
            eventValue(rpgLiteScore(bleedProfile,check)); eventValue(bleedProfile.healthDefensePenalty());
            eventValue(rpgLiteCanAct(bleedProfile,nil) ? 1 : 0); eventValue(rpgLiteCanAct(bleedProfile,true) ? 1 : 0);
            eventValue(bleedProfile.effortHistory.length()); eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 454) { paralysisMental.apply(); return nil; }
        if (code == 455) { paralysisAction.apply(); return nil; }
        if (code == 456) { paralysisTalk.apply(); return nil; }
        if (code == 457) { paralysisMental.requiresSpeech = true; return nil; }
        if (code == 458) { paralysisEpisode.balanced = true; return nil; }
        if (code == 459) { paralysisEpisode.positionAssessed = nil; return nil; }
        return inherited(context);
    }
;
