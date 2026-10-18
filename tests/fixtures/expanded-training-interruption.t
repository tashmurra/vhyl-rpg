#include "expanded-learning-bar.t"
modify learningBar mitigated = true;
interruptedEquipmentType: object;
modify rpgLedger
    afterAdvance(previous)
    {
        inherited(previous);
        local code = bleedInput.code;
        if (code == 3700) learningStudy.mode = 'job';
        if (code == 3701) learningStudy.permitted = nil;
        if (code == 3702 || code == 3713) learningBar.mitigated = nil;
        if (code == 3703) learningTraining.points = 2;
        if (code == 3704) self.seconds += 1;
        if (code == 3710) learningFamiliarity.equipmentType = interruptedEquipmentType;
        if (code == 3711) learningFamiliarity.recognized = true;
        if (code == 3712) learningFamiliarity.available = nil;
        if (code == 3714) bleedProfile.unconscious = true;
        return nil;
    }
;
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code >= 3700 && code <= 3704 || code == 3720 || code == 3724)
        {
            local value = learningStudy.advance(code == 3724 ? 1 : 3600);
            event('test.training-session'); eventValue(value.status); return nil;
        }
        if (code >= 3710 && code <= 3714 || code == 3721)
        {
            local value = learningFamiliarity.advance(3600);
            event('test.training-session'); eventValue(value.status); return nil;
        }
        if (code == 3722)
        {
            event('test.training-interruption-state'); eventValue(learningStudy.credit);
            eventValue(learningStudy.mode); eventValue(learningStudy.permitted ? 1 : 0);
            eventValue(learningTraining.points); eventValue(learningFamiliarity.practicedSeconds);
            eventValue(learningFamiliarity.equipmentType == learningEquipment ? 1 : 0);
            eventValue(learningFamiliarity.recognized ? 1 : 0); eventValue(learningFamiliarity.available ? 1 : 0);
            eventValue(learningBar.mitigated ? 1 : 0); eventValue(bleedProfile.unconscious ? 1 : 0);
            eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 3723) { rpgLedger.seconds = 86399; return nil; }
        return inherited(context);
    }
;
