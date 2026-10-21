#include "expanded-paleontology-assessment.t"
fossilLab: RpgExpandedToolkit id = 'fossil-lab' quality = 'fine' baseCost = 100 techLevel = 8 weight = 100
    supportedSkills = [fossilSkill] approved = true evidence = 'Laboratory facilities support microscopic fossil dating';
fossilLabAssessment: RpgExpandedLaboratoryAssessment toolkit = fossilLab profile = crossPhysician skill = fossilSkill
    items = [fossilLab] quality = 'fine' techLevel = 8 approved = true evidence = 'Facilities adequate for this specimen';
modify fossilSkill specialty = 'microscopic';
modify fossilContext task = 'age' laboratoryEquipment = fossilLabAssessment;
modify crossPhysician equipment = [fossilLab];
modify paleontologyAssessment finding = 'The fossil is approximately two million years old'
    evidence = 'Dating evidence supports this approximate age';
fossilLabOwner: RpgExpandedProfile;
fossilLabGrant: RpgExpandedEquipmentAccess id = 'fossil-lab-access' profile = crossPhysician owner = fossilLabOwner
    item = fossilLab skill = fossilSkill site = healthRoom approved = true evidence = 'Permission to use this laboratory';
modify PhysicianFixtureAction
    exec(context)
    {
        local code = healthInput.code;
        if (code == 22200) { crossPhysician.equipment = []; return nil; }
        if (code == 22201) { fossilLab.techLevel = 9; fossilLabAssessment.techLevel = 9; return nil; }
        if (code == 22202) { fossilLab.techLevel = 12; fossilLabAssessment.techLevel = 12; return nil; }
        if (code == 22203) { fossilContext.task = 'recognition'; return nil; }
        if (code == 22204 || code == 22205)
        {
            if (code == 22204) fossilContext.equipmentTL = 8;
            else fossilLabAssessment.evidence = 'Changed adequacy';
            try { paleontologyAssessment.assess(); }
            catch (RpgExpandedError error) { event('test.fossil-equipment-error'); eventValue(error.reason); }
            return nil;
        }
        if (code == 22206)
        { crossPhysician.equipment = []; fossilLabOwner.equipment = [fossilLab]; fossilLab.storageLocation = healthRoom;
          crossPhysician.equipmentSite = healthRoom; fossilLabAssessment.accessGrants = [fossilLabGrant]; return nil; }
        if (code == 22207) { fossilLabGrant.grant(); return nil; }
        if (code == 22208) { fossilLabGrant.revoke(); return nil; }
        return inherited(context);
    }
;
