#include "expanded-surgical-operation.t"
modify surgicalHealer skills = [surgicalTraining,surgicalAidTraining,surgicalPhysiologyTraining];
modify surgicalPhysiology specialty = 'river-folk';
modify surgicalConditions physiologyModifier = -3;
modify surgicalOperation physiology = 'similar' subjectSpecies = 'river-folk' physiologyCheck = surgicalPhysiologyCheck;
surgicalPhysiologyCheck: RpgExpandedPhysiologyCheck id = 'river-operation' profile = surgicalHealer subject = bleedProfile
    operation = surgicalOperation species = 'river-folk' skill = surgicalPhysiology approved = true evidence = 'Relevant patient physiology';
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 18800) { bleedInput.forcedRoll = 3; surgicalPhysiologyCheck.apply(); return nil; }
        if (code == 18801) { bleedInput.forcedRoll = 18; surgicalPhysiologyCheck.apply(); return nil; }
        if (code == 18802)
        {
            local value = surgicalOperation.prepareRoll(); event('test.surgical-physiology');
            eventValue(value.status); eventValue(value.reason); eventValue(value.score);
            eventValue(surgicalConditions.physiologyModifier); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 18803) { surgicalOperation.physiology = 'machine'; return nil; }
        if (code == 18804)
        {
            surgicalOperation.subjectSpecies = 'other';
            try { surgicalOperation.prepareRoll(); }
            catch (RpgExpandedError error) { event('test.surgical-physiology-error'); eventValue(error.reason); }
            return nil;
        }
        return inherited(context);
    }
;
