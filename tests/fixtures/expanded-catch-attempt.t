#include "expanded-throw-release.t"
catchArm: RpgExpandedBodyPart id = 'catch-arm' kind = 'arm' profile = catchProfile;
catchHand: RpgExpandedBodyPart id = 'catch-hand' kind = 'hand' parent = catchArm profile = catchProfile;
catchOtherArm: RpgExpandedBodyPart id = 'other-arm' kind = 'arm' profile = catchProfile;
catchOtherHand: RpgExpandedBodyPart id = 'other-hand' kind = 'hand' parent = catchOtherArm profile = catchProfile;
modify catchProfile bodyParts = [catchArm,catchHand,catchOtherArm,catchOtherHand];
catchFighter: RpgLiteFighter profile = catchProfile;
catchAttempt: RpgExpandedCatchAttempt id = 'stone-catch' flight = throwRelease fighter = catchFighter
    hand = catchHand waiting = true aware = true approved = true
    evidence = 'The recipient waits with an empty primary hand for the visible deliberate pass';
catchDuplicate: RpgExpandedCatchAttempt id = 'duplicate-catch' flight = throwRelease fighter = catchFighter
    hand = catchHand waiting = true aware = true approved = true evidence = 'Same pass';
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 1260)
        { local value = catchAttempt.assess(); event('test.catch-preview'); eventValue(value.status); eventValue(value.reason); return nil; }
        if (code == 1261 || code == 1262)
        { catchAttempt.resolve(); if (code == 1262) throw new RpgError(); return nil; }
        if (code == 1263)
        {
            event('test.catch-state'); eventValue(catchProfile.catchAttempts.length());
            eventValue(catchFighter.parries); eventValue(catchFighter.offParries);
            eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds);
            eventValue(catchAttempt.result == nil ? nil : (catchAttempt.result.caught ? 1 : 0)); return nil;
        }
        if (code == 1264) { catchAttempt.waiting = nil; return nil; }
        if (code == 1265) { catchHand.disabled = true; return nil; }
        if (code == 1266) { catchFighter.parries = 1; return nil; }
        if (code == 1267) { catchFighter.concentration = 1; return nil; }
        if (code == 1268)
        {
            event('test.catch-duplicate');
            try { catchDuplicate.resolve(); eventValue('accepted'); }
            catch (RpgExpandedError error) { eventValue(error.reason); }
            return nil;
        }
        return inherited(context);
    }
;

catchCapture: RpgExpandedCatchCapture receipt = catchAttempt;
catchCaptureDuplicate: RpgExpandedCatchCapture receipt = catchAttempt;
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 1270 || code == 1271)
        { catchCapture.apply(); if (code == 1271) throw new RpgError(); return nil; }
        if (code == 1272)
        {
            event('test.catch-inventory'); eventValue(bleedProfile.equipment.length());
            eventValue(catchProfile.equipment.length()); eventValue(catchProfile.loadHundredths());
            eventValue(throwStone.ready ? 1 : 0); eventValue(throwStone.thrownFlight != nil ? 1 : 0);
            eventValue(holds(throwStone.bodySupports,catchHand) ? 1 : 0);
            eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
        }
        if (code == 1273)
        { local value = catchCapture.assess(); event('test.capture-preview'); eventValue(value.status); eventValue(value.reason); return nil; }
        if (code == 1274)
        { event('test.capture-duplicate'); eventValue(catchCaptureDuplicate.apply().reason); return nil; }
        return inherited(context);
    }
;
