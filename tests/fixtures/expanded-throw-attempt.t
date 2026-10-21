#include "expanded-held-throw.t"
throwOccurrence: object;
catchProfile: RpgExpandedProfile rules = bleedRules;
modify heldThrow target = 'area';
throwAttempt: RpgExpandedThrowAttempt id = 'stone-pass' request = heldThrow occurrence = throwOccurrence recipient = catchProfile;
throwDuplicate: RpgExpandedThrowAttempt id = 'repeated-stone-pass' request = heldThrow occurrence = throwOccurrence recipient = catchProfile;
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 1170)
        {
            local value = throwAttempt.assess(); event('test.throw-preview'); eventValue(value.status);
            eventValue(value.reason); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 1171 || code == 1172)
        { throwAttempt.resolve(); if (code == 1172) throw new RpgError(); return nil; }
        if (code == 1173)
        {
            event('test.throw-owned'); eventValue(bleedProfile.throwAttempts.length());
            eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds);
            eventValue(throwAttempt.result != nil && throwAttempt.result.allowed ? 1 : 0);
            local check = throwAttempt.result == nil ? nil : throwAttempt.result.check;
            eventValue(check == nil ? nil : check.score); eventValue(check == nil ? nil : check.roll); return nil;
        }
        if (code == 1174)
        {
            event('test.throw-duplicate');
            try { eventValue(throwDuplicate.resolve().status); }
            catch (RpgExpandedError error) { eventValue(error.reason); }
            return nil;
        }
        if (code == 1175)
        {
            local value = throwAttempt.assessCatch(catchProfile,10,true); event('test.recorded-catch');
            eventValue(value.status); eventValue(value.reason); eventValue(value.score);
            eventValue(value.throwBonus); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 1176) { bleedProfile.injury = 10; bleedInput.forcedRoll = 11; return nil; }
        if (code == 1177)
        {
            event('test.throw-binding');
            try { eventValue(throwAttempt.resolve().status); }
            catch (RpgExpandedError error) { eventValue(error.reason); }
            return nil;
        }
        if (code == 1178) { heldThrow.target = 'specific'; return nil; }
        return inherited(context);
    }
;
