#include "expanded-first-aid-physiology.t"
aidDiagnosisSkill: RpgExpandedDiagnosisSkill techLevel = 8;
aidDiagnosisTraining: RpgTraining skill = aidDiagnosisSkill points = 4;
modify crossHealer skills = [crossAidTraining,crossPhysiologyTraining,aidDiagnosisTraining];
aidExaminer: RpgExpandedProfile rules = healthRules iq = 12 techLevel = 8 skills = [aidDiagnosisTraining];
aidDiagnosis: RpgExpandedDiagnosis id = 'aid-examination' caseId = 'unusual-wound' examiner = crossHealer patient = aidPatient
    skill = aidDiagnosisSkill finding = 'The unusual wound can be treated using the identified procedure' findingKind = 'diagnosis'
    approved = true evidence = 'The examination supports this treatment finding';
aidConsultation: RpgExpandedDiagnosticConsultation id = 'aid-consultation' diagnosis = aidDiagnosis recipient = crossHealer
    received = true understood = true evidence = 'The examiner explained the finding and the healer understood it';
modify aidRequest unusualProblem = true problemEvidence = 'The injury requires an identified procedure' diagnosisCaseId = 'unusual-wound';
modify AidFixtureAction
    exec(context)
    {
        local code = healthInput.code;
        if (code == 19800) { aidRequest.diagnosis = aidDiagnosis; return nil; }
        if (code == 19801) { aidDiagnosis.apply(); return nil; }
        if (code == 19802) { aidDiagnosis.findingKind = 'hint'; return nil; }
        if (code == 19803) { rpgRandom.crossRoll = 18; return nil; }
        if (code == 19804) { aidDiagnosis.examiner = aidExaminer; aidRequest.diagnosisConsultation = aidConsultation; return nil; }
        if (code == 19805) { aidConsultation.deliver(); return nil; }
        if (code == 19806)
        {
            aidRequest.diagnosisCaseId = 'another-case';
            try { aidRequest.assess(); }
            catch (RpgExpandedError error) { event('test.aid-diagnosis-error'); eventValue(error.reason); }
            return nil;
        }
        return inherited(context);
    }
;
