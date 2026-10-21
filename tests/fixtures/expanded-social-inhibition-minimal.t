#include "expanded-carousing-entertainment.t"
#include <vhyl-rpg-expanded-traits.t>
minimalInhibition: RpgExpandedSocialInhibition approved = true level = 3;
modify bleedProfile traits = [minimalInhibition] skills = [];
modify BleedTestAction
    exec(context)
    {
        if (bleedInput.code == 2810)
        { event('test.social-learning-minimal'); eventValue(bleedProfile.skillLearningReason(preparationCarousing)); return nil; }
        return inherited(context);
    }
;
