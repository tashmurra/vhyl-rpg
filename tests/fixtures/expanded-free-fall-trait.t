#include "expanded-free-fall.t"
#include <vhyl-rpg-expanded-traits.t>
freeFallTrait: RpgExpandedFreeFallSusceptibility approved = true scope = 'regular-space-travel';
freeFallSkill: RpgExpandedSkill id = 'free-fall' attribute = rpgDX difficulty = 1 defaultPenalty = -5;
freeFallTraining: RpgExpandedTraining skill = freeFallSkill points = 1;
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 9200) { bleedProfile.traits = [freeFallTrait]; return nil; }
        if (code == 9201)
        {
            event('test.free-fall-trait'); eventValue(freeFallTrait.creationCost());
            eventValue(bleedProfile.freeFallSusceptible(true) ? 1 : 0);
            eventValue(bleedProfile.skillLearningReason(freeFallSkill)); return nil;
        }
        if (code == 9202)
        {
            local copy = rpgExpandedTemplateTraits.copy(freeFallTrait);
            event('test.free-fall-trait-copy'); eventValue(copy != freeFallTrait ? 1 : 0);
            eventValue(copy.creationCost()); eventValue(copy.scope); return nil;
        }
        if (code == 9203)
        {
            bleedProfile.skills = [freeFallTraining]; event('test.free-fall-learning');
            try { rpgExpandedValidate(bleedProfile); eventValue('accepted'); }
            catch (RpgExpandedError error) { eventValue(error.reason); }
            bleedProfile.skills = []; return nil;
        }
        if (code == 9204) { freeFallTrait.mitigated = true; return nil; }
        if (code == 9205)
        {
            freeFallTrait.scope = nil; event('test.free-fall-campaign');
            try { freeFallTrait.creationCost(); eventValue('accepted'); }
            catch (RpgExpandedError error) { eventValue(error.reason); }
            freeFallTrait.scope = 'regular-space-travel'; return nil;
        }
        if (code == 9206)
        {
            event('test.free-fall-trait-binding');
            try { freeFall.validateReceipt(); eventValue('accepted'); }
            catch (RpgExpandedError error) { eventValue(error.reason); }
            return nil;
        }
        return inherited(context);
    }
;
