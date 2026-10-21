#include "expanded-begging-traits.t"
appearancePurchase: RpgExpandedAppearance approved = true tier = 2;
appearanceReaction: RpgExpandedAppearanceReactionContext subject = crossPhysician observer = beggingObserver
    compatibleAppearance = true attracted = true approved = true evidence = 'Observer sees a compatible appearance';
modify crossPhysician traits = [appearancePurchase];
modify PhysicianFixtureAction
    exec(context)
    {
        local code = healthInput.code;
        if (code == 24700)
        { event('test.appearance'); eventValue(appearancePurchase.creationCost()); eventValue(rpgLiteReactionModifier(crossPhysician,appearanceReaction)); return nil; }
        if (code >= 24710 && code <= 24719) { appearancePurchase.tier = code-24715; return nil; }
        if (code == 24701) { appearanceReaction.attracted = nil; return nil; }
        if (code == 24702) { appearanceReaction.sameSex = true; appearanceReaction.otherReactionPenalties = -5; return nil; }
        if (code == 24703) { appearanceReaction.otherReactionPenalties = -4; return nil; }
        if (code == 24704) { appearancePurchase.presentation = 'androgynous'; return nil; }
        if (code == 24705) { appearancePurchase.presentation = 'impressive'; return nil; }
        if (code == 24706) { appearanceReaction.sees = nil; return nil; }
        if (code == 24707) { appearanceReaction.compatibleAppearance = nil; return nil; }
        if (code == 24708) { appearancePurchase.mitigated = true; return nil; }
        if (code == 24720) { appearancePurchase.universal = true; return nil; }
        if (code == 24721) { appearancePurchase.standardized = true; return nil; }
        if (code == 24722) { appearanceReaction.sameCulture = nil; return nil; }
        if (code == 24723)
        {
            appearancePurchase.standardized = true; appearancePurchase.tier = 1;
            try { appearancePurchase.creationCost(); }
            catch (RpgExpandedError error) { event('test.appearance-error'); eventValue(error.reason); }
            return nil;
        }
        return inherited(context);
    }
;
