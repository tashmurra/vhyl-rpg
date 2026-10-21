#include "expanded-first-aid-physiology.t"
aidKit: RpgExpandedToolkit id = 'aid-kit' quality = 'fine' baseCost = 20 techLevel = 8 weight = 100
    supportedSkills = [crossAidSkill] approved = true evidence = 'Supplies suitable for this treatment';
aidTools: RpgExpandedToolkitAssessment toolkit = aidKit profile = crossHealer skill = crossAidSkill
    items = [aidKit] quality = 'fine' techLevel = 8 approved = true evidence = 'Supplies accessible for treatment';
modify aidRequest equipmentAssessment = aidTools;
modify crossHealer equipment = [aidKit];
modify AidFixtureAction
    exec(context)
    {
        local code = healthInput.code;
        if (code == 19900) { crossHealer.equipment = []; return nil; }
        if (code == 19901) { aidKit.storageLocation = healthRoom; return nil; }
        if (code == 19902) { aidKit.techLevel = 9; aidTools.techLevel = 9; return nil; }
        if (code == 19903) { aidKit.techLevel = 12; aidTools.techLevel = 12; return nil; }
        if (code == 19904)
        {
            aidTools.evidence = 'Changed assessment';
            try { aidRequest.assess(); }
            catch (RpgExpandedError error) { event('test.aid-tools-error'); eventValue(error.reason); }
            return nil;
        }
        return inherited(context);
    }
;
