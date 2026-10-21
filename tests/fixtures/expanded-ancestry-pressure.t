#include "expanded-ancestry-scores.t"
pressureAncestryFirst: RpgExpandedAncestryScoreTemplate
    id = 'deep-native' nativePressureHundredths = 200 approved = true evidence = 'Approved native environment';
pressureAncestrySecond: RpgExpandedAncestryScoreTemplate
    id = 'second-deep-native' nativePressureHundredths = 200 approved = true evidence = 'Same native environment';
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 8300)
        {
            ancestryState.profile = rpgExpandedCreateAncestryCharacter(ancestryPlain,
                [pressureAncestryFirst,pressureAncestrySecond],bleedRules); return nil;
        }
        if (code == 8301)
        {
            event('test.ancestry-pressure'); eventValue(ancestryState.profile.nativePressureHundredths);
            eventValue(rpgExpandedCharacterCost(ancestryState.profile,nil));
            eventValue(ancestryState.profile.ancestryScores.pressureOrigins.length());
            eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 8302)
        {
            pressureAncestrySecond.nativePressureHundredths = 300;
            event('test.ancestry-pressure-error');
            try { rpgExpandedCreateAncestryCharacter(ancestryPlain,[pressureAncestryFirst,pressureAncestrySecond],bleedRules); eventValue('accepted'); }
            catch (RpgExpandedError error) { eventValue(error.reason); }
            return nil;
        }
        if (code == 8303) { ancestryState.profile.nativePressureHundredths = 100; return nil; }
        if (code == 8304) { ancestryState.profile.ancestryScores.pressureOrigins = []; return nil; }
        if (code == 8305)
        {
            event('test.ancestry-pressure-error');
            try { rpgExpandedValidate(ancestryState.profile); eventValue('accepted'); }
            catch (RpgExpandedError error) { eventValue(error.reason); }
            return nil;
        }
        if (code == 8306) { pressureAncestryFirst.nativePressureHundredths = 300; return nil; }
        return inherited(context);
    }
;
