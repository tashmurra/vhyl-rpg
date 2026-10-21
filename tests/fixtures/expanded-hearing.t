#include "expanded-vision.t"
hearingContextFixture: RpgExpandedHearingContext sound = 'ordinary-speech' ordinaryHearingAvailable = true ordinaryFrequency = true
    approved = true evidence = 'An ordinary conversation at the selected table distance in a quiet space';
modify PhysicianFixtureAction
    exec(context)
    {
        local code = healthInput.code;
        if (code == 27300)
        { event('test.hearing-score'); eventValue(rpgLiteScore(crossPhysician,hearingContextFixture)); eventValue(rpgRandom.draws); return nil; }
        if (code == 27301) { hearingContextFixture.distanceSteps = 3; return nil; }
        if (code == 27302) { hearingContextFixture.distanceSteps = -2; return nil; }
        if (code == 27303) { hearingContextFixture.ambientModifier = -2; return nil; }
        if (code == 27304) { crossPhysician.traits = [rpgLiteMakeTrait('acute-hearing',2,nil)]; return nil; }
        if (code == 27305) { crossPhysician.traits = [rpgLiteMakeTrait('hard-of-hearing',1,nil)]; return nil; }
        if (code == 27306) { hearingContextFixture.ordinaryFrequency = nil; return nil; }
        if (code == 27307) { hearingContextFixture.ordinaryHearingAvailable = nil; return nil; }
        if (code == 27308)
        { hearingContextFixture.understandsSpeech = true; rpgLiteScore(crossPhysician,hearingContextFixture); return nil; }
        if (code >= 27310 && code <= 27321)
        {
            local sounds = ['rustling','quiet-speech','ordinary-speech','light-traffic','loud-speech','busy-office',
                'ordinary-traffic','moderate-amplified-music','heavy-traffic','jet-departure','very-loud-amplified-music','extreme-amplified-sound'];
            local value = rpgExpandedHearingDistance(sounds[code-27309],hearingContextFixture.distanceSteps);
            event('test.hearing-distance'); eventValue(value.quarterYardsNumerator); eventValue(value.quarterYardsDenominator);
            eventValue(value.modifier); return nil;
        }
        return inherited(context);
    }
;
