#include "expanded-social-inhibition.t"
emotionalDeficit: RpgExpandedEmotionalUnderstandingDeficit approved = true;
emotionalDuplicate: RpgExpandedEmotionalUnderstandingDeficit approved = true;
emotionalEmpathy: RpgLiteTrait id = 'empathy' points = 15;
modify bleedProfile traits = [emotionalDeficit];
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 2900)
        {
            event('test.emotional-understanding'); eventValue(emotionalDeficit.creationCost());
            eventValue(rpgLiteScore(bleedProfile,reactionPreparation.context()));
            eventValue(bleedProfile.skillLearningReason(preparationCarousing)); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 2901) { bleedProfile.traits = [emotionalDeficit,socialInhibition]; return nil; }
        if (code == 2902) { emotionalDeficit.mitigated = true; return nil; }
        if (code == 2903) { emotionalDeficit.active = nil; return nil; }
        if (code == 2904 || code == 2905)
        {
            bleedProfile.traits = [emotionalDeficit,code == 2904 ? emotionalEmpathy : emotionalDuplicate];
            event('test.emotional-definition');
            try { rpgExpandedValidate(bleedProfile); eventValue('accepted'); }
            catch (RpgExpandedError error) { eventValue(error.reason); }
            return nil;
        }
        if (code == 2906) { preparationAdmin.requiresEmotionalUnderstanding = true; return nil; }
        if (code == 2907) { preparationCarousing.requiresEmotionalUnderstanding = true; return nil; }
        return inherited(context);
    }
;
