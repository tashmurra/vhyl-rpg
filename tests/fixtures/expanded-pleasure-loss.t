#include "expanded-emotional-understanding.t"
pleasureLoss: RpgExpandedPleasureLoss approved = true;
pleasureObserver: RpgLiteProfile;
modify bleedProfile traits = [pleasureLoss];
modify masteryEncounter audience = pleasureObserver;
pleasureContext: RpgExpandedPleasureReactionContext subject = bleedProfile observer = pleasureObserver
    noticeable = true penalty = 3 approved = true evidence = 'The observer notices the lack of appreciation during a cultural gathering';
modify masteryAttempt socialContext = pleasureContext;
pleasureSkill: RpgLiteSkill;
modify BleedTestAction
    exec(actionContext)
    {
        local code = bleedInput.code;
        if (code == 3000)
        {
            event('test.pleasure-skills'); eventValue(pleasureLoss.creationCost());
            local context = new RpgLiteContext(); context.skill = pleasureSkill;
            foreach (local id in ['carousing','connoisseur','erotic-art','gambling','administration'])
            { pleasureSkill.id = id; eventValue(context.socialTraitModifier(bleedProfile)); }
            return nil;
        }
        if (code == 3001) { pleasureContext.noticeable = nil; return nil; }
        if (code == 3002) { pleasureContext.penalty = 1; return nil; }
        if (code == 3003) { pleasureContext.adverseResponse = 'rejection'; return nil; }
        if (code == 3004)
        {
            pleasureContext.adverseResponse = 'attack'; event('test.pleasure-violence');
            try { masteryAttempt.resolve(); eventValue('accepted'); }
            catch (RpgExpandedError error) { eventValue(error.reason); }
            return nil;
        }
        if (code == 3005) { pleasureLoss.mitigated = true; return nil; }
        if (code == 3006)
        {
            local value = pleasureContext.consequence(masteryEncounter.history[1][4]);
            event('test.pleasure-response'); eventValue(value.reason); return nil;
        }
        return inherited(actionContext);
    }
;
