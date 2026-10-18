#include "expanded-interrogation.t"
#include <vhyl-rpg-expanded-traits.t>
questionCompanyTrait: RpgExpandedCompanionship level = 2 approved = true;
modify questionActor traits = [questionCompanyTrait];
questionCompany: RpgExpandedCompany subject = questionActor members = [questionActor,bleedProfile]
    approved = true evidence = 'The author identifies the current company for this interaction';
modify questionRequest company = questionCompany;
modify rpgLedger
    afterAdvance(previous)
    {
        inherited(previous);
        if (bleedInput.code == 5001) questionCompany.members = [questionActor,bleedHealer];
        return nil;
    }
;
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 5000)
        { local value = questionRequest.assess(); event('test.company-question'); eventValue(value.actorScore); eventValue(rpgRandom.draws); return nil; }
        if (code == 5001) { questionRequest.apply(); return nil; }
        return inherited(context);
    }
;
