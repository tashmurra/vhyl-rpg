#include "expanded-surgical-assessment.t"
modify bleedRules bleeding = nil;
modify bleedProfile maxHP = 40;
surgicalOperation: RpgExpandedSurgicalOperation id = 'procedure' patient = bleedProfile
    assessment = surgicalAssessment durationSeconds = 60 approved = true
    procedureEvidence = 'Authored one-minute non-amputation procedure; success grants no HP';
surgicalOperationOther: RpgExpandedSurgicalOperation id = 'other' patient = bleedProfile
    assessment = surgicalAssessment durationSeconds = 60 approved = true
    procedureEvidence = 'A separate operation cannot overlap this procedure';
surgicalOperationInput: object fixedDie = 0;
modify rpgRandom
    die()
    {
        if (surgicalOperationInput.fixedDie != 0) { self.draws += 1; return surgicalOperationInput.fixedDie; }
        return inherited();
    }
;
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 120) { surgicalOperation.start(); return nil; }
        if (code == 121) { surgicalOperation.assessCompletion(); return nil; }
        if (code == 122 || code == 123)
        {
            surgicalOperation.complete(); if (code == 123) throw new RpgError(); return nil;
        }
        if (code == 124) { surgicalOperation.interrupt(); return nil; }
        if (code == 125)
        {
            event('test.surgical-operation'); eventValue(surgicalOperation.startedAt);
            eventValue(surgicalOperation.completedAt); eventValue(bleedProfile.surgicalOperations.length());
            eventValue(bleedProfile.injury); eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws);
            eventValue(surgicalOperation.result == nil ? nil : surgicalOperation.result.reason);
            eventValue(surgicalOperation.result == nil ? nil : surgicalOperation.result.succeeded); return nil;
        }
        if (code == 126) { bleedInput.forcedRoll = 17; surgicalOperationInput.fixedDie = 4; return nil; }
        if (code == 127) { surgicalOperationOther.start(); return nil; }
        if (code == 128) { surgicalConditions.techLevel = 4; return nil; }
        if (code == 129) { surgicalOperation.assess(); return nil; }
        if (code == 130) { surgicalOperation.durationSeconds = 120; return nil; }
        if (code == 131) { surgicalConditions.earlyAntisepsis = true; return nil; }
        if (code == 132) { bleedRules.bleeding = true; return nil; }
        return inherited(context);
    }
;
