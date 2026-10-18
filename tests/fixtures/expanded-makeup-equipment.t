#include "expanded-makeup.t"
#include <vhyl-rpg-expanded-equipment.t>
makeupKit: RpgExpandedToolkit id = 'stage-kit' quality = 'fine' baseCost = 100 techLevel = 8 weight = 100
    supportedSkills = [makeupCatalogue] approved = true evidence = 'Kit supports this theatrical presentation';
makeupKitAssessment: RpgExpandedToolkitAssessment toolkit = makeupKit profile = crossPhysician skill = makeupCatalogue
    items = [makeupKit] quality = 'fine' techLevel = 8 approved = true evidence = 'Tools adequate for this application';
modify makeupContextFixture toolkitAssessment = makeupKitAssessment;
modify crossPhysician equipment = [makeupKit];
makeupKitOwner: RpgExpandedProfile rules = healthRules;
makeupKitGrant: RpgExpandedEquipmentAccess id = 'stage-kit-permission' profile = crossPhysician owner = makeupKitOwner
    item = makeupKit skill = makeupCatalogue site = healthRoom approved = true evidence = 'Permission to use the backstage kit';
modify PhysicianFixtureAction
    exec(context)
    {
        local code = healthInput.code;
        if (code == 25800) { event('test.makeup-kit-score'); eventValue(rpgLiteScore(crossPhysician,makeupContextFixture)); return nil; }
        if (code == 25801) { makeupKit.storageLocation = healthRoom; return nil; }
        if (code == 25802) { makeupKit.techLevel = 5; makeupKitAssessment.techLevel = 5; makeupContextFixture.prosthetics = true; return nil; }
        if (code == 25803)
        { crossPhysician.equipment = []; makeupKitOwner.equipment = [makeupKit]; makeupKit.storageLocation = healthRoom;
          crossPhysician.equipmentSite = healthRoom; makeupKitAssessment.accessGrants = [makeupKitGrant]; return nil; }
        if (code == 25804) { makeupKitGrant.grant(); return nil; }
        if (code == 25805) { makeupKitGrant.revoke(); return nil; }
        return inherited(context);
    }
;
