#include "expanded-reaction-preparation.t"
#include <vhyl-rpg-expanded-traits.t>
preparationCompanyTrait: RpgExpandedCompanionship level = 2 approved = true;
modify bleedProfile traits = [preparationCompanyTrait];
preparationCompanion: RpgLiteProfile;
preparationCompany: RpgExpandedCompany subject = bleedProfile members = [bleedProfile,bleedHealer]
    approved = true evidence = 'The author identifies company during the administrative task';
modify reactionPreparation company = preparationCompany;
modify rpgLedger
    afterAdvance(previous)
    {
        inherited(previous);
        if (bleedInput.code == 5010) preparationCompany.members = [bleedProfile,preparationCompanion];
        return nil;
    }
;
modify BleedTestAction
    exec(context)
    {
        if (bleedInput.code == 5010) { reactionPreparation.resolve(); return nil; }
        return inherited(context);
    }
;
