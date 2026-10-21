#include "expanded-surgical-operation.t"
mortalCare: RpgExpandedMortalCare id = 'trauma' patient = bleedProfile approved = true
    evidence = 'Current observed mortal condition requiring stabilization';
mortalStabilization: RpgExpandedMortalStabilization id = 'stabilize-one' patient = bleedProfile
    assessment = surgicalAssessment care = mortalCare approved = true procedureEvidence = 'One-hour mortal stabilization';
mortalStabilizationNext: RpgExpandedMortalStabilization id = 'stabilize-two' patient = bleedProfile
    assessment = surgicalAssessment care = mortalCare approved = true procedureEvidence = 'Second attempt on the same mortal condition';
mortalRollInput: object rolls = [];
modify rpgRandom
    roll()
    {
        if (mortalRollInput.rolls.length() > 0)
        {
            local value = mortalRollInput.rolls[1]; local rest = [];
            for (local index = 2; index <= mortalRollInput.rolls.length(); index += 1) rest = rest + [mortalRollInput.rolls[index]];
            mortalRollInput.rolls = rest; self.draws += 3; return value;
        }
        return inherited();
    }
;
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 170)
        {
            bleedProfile.injury = 80; bleedProfile.mortal = true; bleedProfile.unconscious = true;
            mortalRollInput.rolls = [10,10,7,11]; surgicalOperationInput.fixedDie = 4; mortalCare.open(); return nil;
        }
        if (code == 171) { mortalStabilization.start(); return nil; }
        if (code == 172) { rpgSpendTime(3600); return nil; }
        if (code == 173 || code == 174)
        { mortalStabilization.complete(); if (code == 174) throw new RpgError(); return nil; }
        if (code == 175)
        {
            event('test.mortal-stabilization'); eventValue(bleedProfile.mortal ? 1 : 0);
            eventValue(bleedProfile.ht); eventValue(bleedProfile.injury); eventValue(mortalCare.failedAttempts());
            eventValue(mortalCare.closedAt); eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 176) { mortalRollInput.rolls = [10,10,11]; return nil; }
        if (code == 177) { mortalRollInput.rolls = [10,10,8,10]; mortalStabilizationNext.start(); return nil; }
        if (code == 178) { mortalStabilizationNext.complete(); return nil; }
        if (code == 179)
        {
            local value = mortalStabilizationNext.prepareRoll();
            event('test.mortal-score'); eventValue(value.score); return nil;
        }
        if (code == 180) { bleedProfile.injury = 160; return nil; }
        if (code == 181) { bleedProfile.injury = 200; return nil; }
        if (code == 182) { mortalStabilization.assessCompletion(); return nil; }
        if (code == 183) { mortalRollInput.rolls = [10,10,7,18]; return nil; }
        if (code == 184)
        {
            event('test.mortal-complication'); eventValue(mortalStabilization.result.healthLost);
            eventValue(mortalStabilization.result.complicationReviewRequired ? 1 : 0); return nil;
        }
        return inherited(context);
    }
;
