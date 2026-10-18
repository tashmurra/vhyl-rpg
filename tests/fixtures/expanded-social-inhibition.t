#include "expanded-carousing-entertainment.t"
#include <vhyl-rpg-expanded-skills.t>
#include <vhyl-rpg-expanded-traits.t>
socialInhibition: RpgExpandedSocialInhibition approved = true level = 1;
socialInhibitionDuplicate: RpgExpandedSocialInhibition approved = true level = 1;
modify bleedProfile traits = [socialInhibition];
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 2800)
        {
            event('test.social-inhibition'); eventValue(socialInhibition.creationCost());
            eventValue(rpgLiteScore(bleedProfile,reactionPreparation.context()));
            eventValue(bleedProfile.skillLearningReason(preparationCarousing)); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 2801) { socialInhibition.level = 2; return nil; }
        if (code == 2802) { socialInhibition.level = 3; bleedProfile.skills = []; return nil; }
        if (code == 2803) { socialInhibition.mitigated = true; return nil; }
        if (code == 2804) { socialInhibition.active = nil; return nil; }
        if (code == 2805) { bleedProfile.traits = [socialInhibition,socialInhibitionDuplicate]; return nil; }
        if (code == 2806 || code == 2807)
        {
            if (code == 2807) socialInhibition.level = 3;
            event('test.social-inhibition-error');
            try { rpgLiteScore(bleedProfile,reactionPreparation.context()); eventValue('accepted'); }
            catch (RpgExpandedError error) { eventValue(error.reason); }
            return nil;
        }
        if (code == 2808)
        {
            local context = new RpgLiteContext(); context.skill = preparationAdmin;
            event('test.social-inhibition-unaffected'); eventValue(rpgLiteScore(bleedProfile,context)); return nil;
        }
        return inherited(context);
    }
;
