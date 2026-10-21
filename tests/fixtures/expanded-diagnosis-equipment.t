#include "expanded-diagnosis.t"
#include <vhyl-rpg-expanded-equipment.t>
diagnosticKit: RpgExpandedToolkit id = 'diagnostic-kit' quality = 'fine' baseCost = 20 techLevel = 8 weight = 100
    supportedSkills = [diagnosisSkill] approved = true evidence = 'Portable diagnostic instruments adequate for this case';
diagnosticEquipment: RpgExpandedToolkitAssessment toolkit = diagnosticKit profile = surgicalHealer skill = diagnosisSkill
    items = [diagnosticKit] quality = 'fine' techLevel = 8 approved = true evidence = 'Instruments available for the examination';
modify diagnosisCase equipmentAssessment = diagnosticEquipment;
modify surgicalHealer equipment = [diagnosticKit];
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 19000) { surgicalHealer.equipment = []; return nil; }
        if (code == 19001) { diagnosticKit.storageLocation = bleedRoom; return nil; }
        if (code == 19002) { diagnosisCase.equipmentModifier = 2; return nil; }
        if (code == 19003)
        {
            try
            {
                local value = diagnosisCase.apply(); event('test.diagnostic-tools-result'); eventValue(value.status); eventValue(value.reason);
            }
            catch (RpgExpandedError error) { event('test.diagnostic-tools-error'); eventValue(error.reason); }
            return nil;
        }
        return inherited(context);
    }
;
