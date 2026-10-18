#include "expanded-template-isolation.t"
nativePressureState: object profile = nil;
nativePressureFirst: RpgExpandedTemplate nativePressureHundredths = 200;
nativePressureSecond: RpgExpandedTemplate nativePressureHundredths = 200;
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 8200) { nativePressureState.profile = nativePressureFirst.create(bleedRules); return nil; }
        if (code == 8201)
        {
            nativePressureState.profile = rpgExpandedCombineTemplates([nativePressureFirst,nativePressureSecond],bleedRules,100,50);
            return nil;
        }
        if (code == 8202)
        {
            nativePressureSecond.nativePressureHundredths = 100;
            event('test.native-pressure-error');
            try { rpgExpandedCombineTemplates([nativePressureFirst,nativePressureSecond],bleedRules,100,50); eventValue('accepted'); }
            catch (RpgExpandedError error) { eventValue(error.reason); }
            return nil;
        }
        if (code == 8203)
        {
            selectionPackage.nativePressureHundredths = 200;
            nativePressureState.profile = selectionInput.create(bleedRules); return nil;
        }
        if (code == 8204)
        {
            event('test.native-pressure-template'); eventValue(nativePressureState.profile.nativePressureHundredths);
            eventValue(rpgExpandedCharacterCost(nativePressureState.profile,nil));
            eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 8205) { nativePressureState.profile.nativePressureHundredths = 300; return nil; }
        return inherited(context);
    }
;
