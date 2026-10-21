#include "expanded-surgical-operation.t"
repairArm: RpgExpandedBodyPart id = 'left' profile = bleedProfile;
repairOtherArm: RpgExpandedBodyPart id = 'right' profile = bleedProfile;
modify bleedProfile bodyParts = [repairArm,repairOtherArm];
repairWound: RpgExpandedWound id = 'lasting-arm' profile = bleedProfile amount = 21
    location = 'arm' bodyPart = repairArm;
repairDuration: RpgExpandedCripplingDuration wound = repairWound combatEnded = true;
lastingRepair: RpgExpandedLastingRepair id = 'arm-repair' patient = bleedProfile assessment = surgicalAssessment
    duration = repairDuration approved = true procedureEvidence = 'Repair the recorded lasting arm injury'
    remainingMonthNumerator = 7 remainingMonthDenominator = 2 weekSeconds = 60
    calendarEvidence = 'At completion 3.5 months remain; this fixture campaign uses sixty-second weeks';
repairMonth: RpgExpandedRecoveryMonth duration = repairDuration ordinal = 1 calendarId = 'fixture'
    boundaryId = 'first' reached = true evidence = 'Old monthly schedule must no longer recover this injury';
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 140)
        {
            surgicalOperationInput.fixedDie = 4; bleedInput.forcedRoll = 10; repairWound.apply();
            bleedInput.forcedRoll = 11; repairDuration.apply(); bleedInput.forcedRoll = 10; return nil;
        }
        if (code == 141) { lastingRepair.start(); return nil; }
        if (code == 142) { rpgSpendTime(7200); return nil; }
        if (code == 143 || code == 144)
        { lastingRepair.complete(); if (code == 144) throw new RpgError(); return nil; }
        if (code == 145) { rpgSpendTime(210); return nil; }
        if (code == 146 || code == 147)
        { lastingRepair.recover(); if (code == 147) throw new RpgError(); return nil; }
        if (code == 148) { bleedInput.forcedRoll = 18; return nil; }
        if (code == 149) { bleedInput.forcedRoll = 11; return nil; }
        if (code == 150)
        {
            event('test.lasting-repair'); eventValue(repairDuration.result.duration); eventValue(repairArm.disabled ? 1 : 0);
            eventValue(lastingRepair.recoversAt); eventValue(lastingRepair.recoveredAt);
            eventValue(bleedProfile.injury); eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 151) { lastingRepair.assess(); return nil; }
        if (code == 152) { rpgSpendTime(211); return nil; }
        if (code == 153) { repairMonth.apply(); return nil; }
        if (code == 154) { lastingRepair.remainingMonthNumerator = 9; return nil; }
        return inherited(context);
    }
;
