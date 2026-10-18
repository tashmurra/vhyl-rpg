#include "expanded-appearance-template.t"
distinctiveSpecies: object;
distinctivePurchase: RpgExpandedDistinctiveFeatures approved = true level = 2 species = distinctiveSpecies
    description = 'Glowing eyes and luminous hair' origin = 'A documented laboratory accident';
modify crossPhysician traits = [distinctivePurchase];
distinctiveDisguise: RpgLiteSkill id = 'disguise';
distinctiveShadowing: RpgLiteSkill id = 'shadowing';
distinctiveOwnContext: RpgExpandedDistinctiveContext subject = crossPhysician skill = distinctiveDisguise
    approved = true evidence = 'The disguise is attempted among people without these features';
distinctiveOtherContext: RpgExpandedDistinctiveContext subject = crossPhysician purpose = 'follow'
    approved = true evidence = 'The pursuer can use the visible features to follow the subject';
modify PhysicianFixtureAction
    exec(context)
    {
        local code = healthInput.code;
        if (code == 25300)
        { event('test.distinctive'); eventValue(distinctivePurchase.creationCost());
          eventValue(distinctiveOwnContext.socialTraitModifier(crossPhysician));
          eventValue(distinctiveOtherContext.socialTraitModifier(beggingObserver)); eventValue(rpgRandom.draws); return nil; }
        if (code == 25301) { distinctivePurchase.level = 5; return nil; }
        if (code == 25302) { distinctiveOwnContext.sharedByCrowd = true; distinctiveOtherContext.sharedByCrowd = true; return nil; }
        if (code == 25303) { distinctivePurchase.mitigated = true; return nil; }
        if (code == 25304) { distinctiveOwnContext.purpose = 'shadowing'; distinctiveOwnContext.skill = distinctiveShadowing;
            distinctiveOtherContext.purpose = 'identify'; return nil; }
        if (code == 25305)
        { local copy = rpgExpandedCopyTemplateTrait(distinctivePurchase); event('test.distinctive-copy');
          eventValue(copy != distinctivePurchase ? 1 : 0); eventValue(copy.creationCost());
          eventValue(rpgExpandedTemplateOptionsEqual(copy,distinctivePurchase) ? 1 : 0); return nil; }
        if (code == 25306)
        {
            distinctivePurchase.origin = nil;
            try { distinctivePurchase.creationCost(); }
            catch (RpgExpandedError error) { event('test.distinctive-error'); eventValue(error.reason); }
            return nil;
        }
        return inherited(context);
    }
;
