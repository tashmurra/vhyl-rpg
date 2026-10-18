#include "expanded-diagnosis-surgery.t"
consultingTraining: RpgTraining skill = diagnosisSkill points = 8;
consultingExaminer: RpgExpandedProfile rules = bleedRules iq = 14 techLevel = 8 skills = [consultingTraining];
modify diagnosisCase examiner = consultingExaminer;
clinicalConsultation: RpgExpandedDiagnosticConsultation id = 'case-report' diagnosis = diagnosisCase recipient = surgicalHealer
    received = true understood = true evidence = 'Surgeon received and understood the examiner report for this patient';
modify surgicalOperation diagnosisConsultation = clinicalConsultation;
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 19200 || code == 19201)
        {
            local value = clinicalConsultation.deliver(); event('test.consultation-result'); eventValue(value.status); eventValue(value.reason);
            if (code == 19201) throw new RpgError(); return nil;
        }
        if (code == 19202) { clinicalConsultation.understood = nil; return nil; }
        if (code == 19203)
        {
            event('test.consultation-state'); eventValue(surgicalHealer.diagnosticConsultations.length());
            eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
        }
        return inherited(context);
    }
;
