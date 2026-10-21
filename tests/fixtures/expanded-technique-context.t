#include "expanded-technique-purchase.t"
#include <vhyl-rpg-expanded-equipment.t>
techniqueTools: RpgExpandedEquipmentAssessment quality = 'fine';
techniqueContext: RpgExpandedTechniqueContext technique = purchaseTechnique skill = learningSkill;
techniqueChild: RpgExpandedTechnique
    id = 'child-action' owner = bleedProfile parentTechnique = purchaseTechnique penalty = -1
;
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 3500)
        {
            event('test.technique-context'); eventValue(rpgLiteScore(bleedProfile,techniqueContext));
            eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
        }
        if (code == 3501 || code == 3502)
        {
            local value = rpgLiteCheck(bleedProfile,techniqueContext);
            event('test.technique-check'); eventValue(value.score); eventValue(value.outcome); eventValue(rpgRandom.draws);
            if (code == 3502) throw new RpgError(); return nil;
        }
        if (code == 3503) { techniqueContext.equipmentAssessment = techniqueTools; return nil; }
        if (code == 3504) { techniqueContext.familiarity = learningFamiliarity; return nil; }
        if (code == 3505) { bleedProfile.shock = 2; techniqueContext.darkness = 1; return nil; }
        if (code == 3506) { techniqueContext.modifier = 3; return nil; }
        if (code == 3507) { techniqueTools.quality = 'none'; return nil; }
        if (code == 3508) { techniqueContext.skill = bleedAidSkill; return nil; }
        if (code == 3509) { techniqueContext.fixedBase = 10; return nil; }
        if (code == 3510)
        {
            event('test.technique-context-error');
            try { rpgLiteCheck(bleedProfile,techniqueContext); eventValue('accepted'); }
            catch (RpgExpandedError error) { eventValue(error.reason); }
            eventValue(rpgRandom.draws); return nil;
        }
        if (code == 3511)
        { techniqueContext.technique = techniqueChild; bleedProfile.contributions = [purchaseTechnique,techniqueChild]; return nil; }
        return inherited(context);
    }
;
