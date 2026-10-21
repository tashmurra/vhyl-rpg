#include "expanded-breathing-recovery.t"
recoveryHeldBreath: RpgExpandedBreathReserve id = 'held-during-rest' profile = airPatient evidence = 'Holding breath without fresh air';
modify AirFixtureAction
    exec(context)
    {
        local code = airInput.code;
        if (code == 18100) { recoveryHeldBreath.start(); return nil; }
        if (code == 18101) { airPatient.hunger = 5; return nil; }
        if (code >= 18102 && code <= 18104)
        {
            if (code == 18102) breathingRest.completedAt += 1;
            if (code == 18103) breathingRest.result.recovered += 1;
            if (code == 18104) airPatient.breathingRecoveries = [breathingRest,breathingRest];
            try { airPatient.validateFeatures(); }
            catch (RpgExpandedError error) { event('test.breathing-history-error'); eventValue(error.reason); }
            return nil;
        }
        if (code == 18105)
        {
            try { breathingRest.apply(); }
            catch (RpgExpandedError error) { event('test.breathing-restriction'); eventValue(error.reason); }
            return nil;
        }
        return inherited(context);
    }
;
recoveryClockGate: object enabled = nil;
modify rpgLedger
    validateAdvance(seconds)
    {
        inherited(seconds);
        if (recoveryClockGate.enabled && seconds > 0) rpgExpandedReject('fixture-recovery-clock-boundary');
        return nil;
    }
;
modify AirFixtureAction
    exec(context)
    {
        if (airInput.code == 18106) { recoveryClockGate.enabled = true; return nil; }
        return inherited(context);
    }
;
