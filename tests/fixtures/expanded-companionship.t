#include "expanded-learning-bar.t"
#include <vhyl-rpg-expanded-social.t>
companyTrait: RpgExpandedCompanionship approved = true;
modify bleedProfile traits = [companyTrait];
companyTwo: RpgLiteProfile;
companyThree: RpgLiteProfile;
companyFour: RpgLiteProfile;
companyFive: RpgLiteProfile;
companyFacts: RpgExpandedCompany subject = bleedProfile members = [bleedProfile]
    approved = true evidence = 'Authored current group, counting the subject';
companyContext: RpgLiteContext skill = learningSkill company = companyFacts;
companyReaction: RpgExpandedCompanionshipReactionContext
    subject = companyTwo observer = bleedProfile usualReaction = true approved = true
    evidence = 'The observer responds in their usual sociable manner'
;
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 4900)
        {
            event('test.company'); eventValue(companyTrait.creationCost()); eventValue(rpgLiteScore(bleedProfile,companyContext));
            eventValue(companyReaction.traitReactionModifier(companyTwo)); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 4901) { companyTrait.level = 2; return nil; }
        if (code == 4902) { companyFacts.members = [bleedProfile,companyTwo]; return nil; }
        if (code == 4903) { companyFacts.members = [bleedProfile,companyTwo,companyThree,companyFour]; return nil; }
        if (code == 4904) { companyFacts.members = [bleedProfile,companyTwo,companyThree,companyFour,companyFive]; return nil; }
        if (code == 4905) { companyReaction.usualReaction = nil; return nil; }
        if (code == 4906) { companyTrait.mitigated = true; return nil; }
        if (code == 4907) { companyContext.company = nil; return nil; }
        if (code == 4908)
        {
            event('test.company-error');
            try { rpgLiteCheck(bleedProfile,companyContext); eventValue('accepted'); }
            catch (RpgExpandedError error) { eventValue(error.reason); }
            eventValue(rpgRandom.draws); return nil;
        }
        return inherited(context);
    }
;
