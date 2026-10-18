#include "expanded-surgical-physiology.t"
diagnosisSkill: RpgExpandedDiagnosisSkill techLevel = 8;
diagnosisTraining: RpgTraining skill = diagnosisSkill points = 8;
modify surgicalHealer skills = [diagnosisTraining,surgicalPhysiologyTraining];
modify bleedInput forcedRoll = 3;
diagnosisCase: RpgExpandedDiagnosis id = 'assessment' caseId = 'initial-symptoms' examiner = surgicalHealer patient = bleedProfile
    skill = diagnosisSkill finding = 'The symptoms point to an internal injury' findingKind = 'hint'
    approved = true evidence = 'Finding is supportable at the examiner technology level with available evidence';
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 18900)
        { local value = diagnosisCase.assess(); event('test.diagnosis-score'); eventValue(value.status); eventValue(value.score); return nil; }
        if (code == 18901 || code == 18902)
        {
            local value = diagnosisCase.apply(); event('test.diagnosis-result'); eventValue(value.status);
            eventValue(value.finding); eventValue(value.findingKind);
            if (code == 18902) throw new RpgError(); return nil;
        }
        if (code == 18903) { diagnosisCase.obvious = true; diagnosisCase.skill = nil; return nil; }
        if (code == 18904)
        { diagnosisCase.equipmentModifier = 2; diagnosisCase.internalInjury = true; diagnosisCase.rarityModifier = -5; return nil; }
        if (code == 18905) { bleedInput.forcedRoll = 18; return nil; }
        if (code == 18906)
        {
            event('test.diagnosis-state'); eventValue(surgicalHealer.diagnoses.length()); eventValue(bleedProfile.injury);
            eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
        }
        if (code == 18907) { bleedProfile.dead = true; return nil; }
        return inherited(context);
    }
;
