#include "expanded-technique-context.t"
modify purchaseTechnique cinematic = true;
techniqueTrainingPermission: RpgExpandedMartialTraining
    approved = true prerequisiteEvidence = 'Approved advanced martial instruction'
;
techniqueRequirement: RpgExpandedPrerequisite kind = 'trait' traitId = 'advanced-martial-training';
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 3600)
        {
            event('test.technique-eligibility');
            try { eventValue(rpgLiteScore(bleedProfile,techniqueContext)); }
            catch (RpgExpandedError error) { eventValue(error.reason); }
            eventValue(rpgRandom.draws); eventValue(bleedProfile.unspentPoints); return nil;
        }
        if (code == 3601) { bleedRules.cinematicTechniquePolicy = 'restricted'; return nil; }
        if (code == 3602) { bleedRules.cinematicTechniquePolicy = 'unrestricted'; return nil; }
        if (code == 3603)
        {
            purchaseTechnique.cinematicRequirement = techniqueRequirement; purchaseTechnique.cinematicApproved = true;
            purchaseTechnique.cinematicEvidence = 'The selected training covers this action'; return nil;
        }
        if (code == 3604) { bleedProfile.traits = [learningBar,techniqueTrainingPermission]; return nil; }
        if (code == 3605)
        {
            purchaseTechnique.id = 'paired-weapon-attack'; purchaseTechnique.penalty = -4;
            purchaseTechnique.ordinaryPistolException = true;
            learningSkill.id = 'guns'; learningSkill.attribute = rpgDX; learningSkill.difficulty = 0;
            learningSkill.defaultPenalty = -4; learningSkill.specialty = 'pistol'; learningSkill.techLevel = 3;
            return nil;
        }
        if (code == 3606) { learningSkill.specialty = 'rifle'; return nil; }
        return inherited(context);
    }
;
