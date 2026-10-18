#include "expanded-diagnosis.t"
modify surgicalHealer skills = [surgicalTraining,surgicalAidTraining,diagnosisTraining,surgicalPhysiologyTraining];
modify surgicalConditions physiologyModifier = 0 diagnosed = nil;
modify surgicalOperation physiology = 'authored' physiologyCheck = nil diagnosis = diagnosisCase diagnosisCaseId = 'initial-symptoms';
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 19100) { diagnosisCase.findingKind = 'diagnosis'; return nil; }
        if (code == 19101)
        {
            local value = surgicalOperation.prepareRoll(); event('test.diagnosis-surgery');
            eventValue(value.status); eventValue(value.reason); eventValue(value.score);
            eventValue(surgicalConditions.diagnosed); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 19102 || code == 19103)
        {
            if (code == 19102) surgicalOperation.diagnosisCaseId = 'unrelated-case';
            else diagnosisCase.result.findingKind = 'diagnosis';
            try { surgicalOperation.prepareRoll(); }
            catch (RpgExpandedError error) { event('test.diagnosis-surgery-error'); eventValue(error.reason); }
            return nil;
        }
        return inherited(context);
    }
;
