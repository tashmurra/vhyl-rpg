#include "expanded-motion-trait.t"
motionGeneral: RpgExpandedSkill id = 'driving' attribute = rpgDX difficulty = 1 defaultPenalty = -5;
motionOptionalGeneral: RpgExpandedSkill id = 'authored-vehicle-operation' attribute = rpgIQ difficulty = 1 vehicleOperationClass = 1;
modify ExpandedTestAction
    exec(context)
    {
        local code = expandedInput.code;
        if (code == 16400)
        {
            event('test.motion-catalogue');
            foreach (local id in ['bicycling','boating','driving','piloting','submarine'])
            {
                local skill = rpgLiteMakeSkill(id,nil,nil);
                eventValue(skill.vehicleOperationClassification()); eventValue(motionHero.motionSkillLearningReason(skill));
            }
            local navigation = rpgLiteMakeSkill('navigation',3,'land');
            eventValue(navigation.vehicleOperationClassification()); eventValue(motionHero.motionSkillLearningReason(navigation));
            return nil;
        }
        if (code == 16401 || code == 16402)
        {
            local skill = rpgExpandedOptionalSpecialty(motionOptionalGeneral,'operation-local','local-routes',true);
            if (code == 16402) skill.vehicleOperationClass = 0;
            event('test.motion-specialty');
            try { eventValue(motionHero.motionSkillLearningReason(skill)); }
            catch (RpgExpandedError error) { eventValue(error.reason); }
            return nil;
        }
        if (code == 16403)
        {
            motionGeneral.vehicleOperationClass = 0; event('test.motion-class-conflict');
            try { motionGeneral.vehicleOperationClassification(); eventValue(nil); }
            catch (RpgExpandedError error) { eventValue(error.reason); }
            return nil;
        }
        return inherited(context);
    }
;
