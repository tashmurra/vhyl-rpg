#include "expanded.t"
motionTrait: RpgExpandedMotionSusceptibility approved = true;
motionHero: RpgExpandedProfile rules = expandedRules traits = [motionTrait];
motionDriving: RpgExpandedSkill id = 'driving' vehicleOperationClass = 1;
motionHistory: RpgExpandedSkill id = 'history' vehicleOperationClass = 0;
motionUnknown: RpgExpandedSkill id = 'authored-skill';
motionTraining: RpgExpandedTraining skill = motionDriving points = 1;
modify ExpandedTestAction
    exec(context)
    {
        local code = expandedInput.code;
        if (code == 16100)
        {
            event('test.motion-trait'); eventValue(motionTrait.creationCost()); eventValue(motionHero.motionSusceptible(true));
            eventValue(motionHero.skillLearningReason(motionDriving)); eventValue(motionHero.skillLearningReason(motionHistory));
            eventValue(motionHero.skillLearningReason(motionUnknown)); return nil;
        }
        if (code == 16101)
        {
            local copy = rpgExpandedTemplateTraits.copy(motionTrait); event('test.motion-template');
            eventValue(copy != motionTrait); eventValue(copy.creationCost()); return nil;
        }
        if (code == 16102) { motionTrait.mitigated = true; return nil; }
        if (code == 16103)
        {
            motionHero.skills = [motionTraining]; event('test.motion-training');
            try { rpgExpandedValidate(motionHero); eventValue('accepted'); }
            catch (RpgExpandedError error) { eventValue(error.reason); }
            motionHero.skills = []; return nil;
        }
        return inherited(context);
    }
;
