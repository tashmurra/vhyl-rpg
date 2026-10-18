#include "expanded-begging-traits.t"
appearanceTrait: RpgExpandedAppearance approved = true tier = 2;
appearanceReaction: RpgExpandedAppearanceReactionContext subject = crossPhysician observer = beggingObserver
    compatibleAppearance = true attracted = true approved = true evidence = 'Observer sees a compatible appearance';
modify crossPhysician traits = [appearanceTrait];
modify PhysicianFixtureAction
    exec(context)
    {
        local code = healthInput.code;
        if (code == 24700)
        { event('test.appearance'); eventValue(appearanceTrait.creationCost()); eventValue(rpgLiteReactionModifier(crossPhysician,appearanceReaction)); return nil; }
        if (code >= 24710 && code <= 24719) { appearanceTrait.tier = code-24715; return nil; }
        if (code == 24701) { appearanceReaction.attracted = nil; return nil; }
        if (code == 24702) { appearanceReaction.sameSex = true; appearanceReaction.otherReactionPenalties = -5; return nil; }
        if (code == 24703) { appearanceReaction.otherReactionPenalties = -4; return nil; }
        if (code == 24704) { appearanceTrait.presentation = 'androgynous'; return nil; }
        if (code == 24705) { appearanceTrait.presentation = 'impressive'; return nil; }
        if (code == 24706) { appearanceReaction.sees = nil; return nil; }
        if (code == 24707) { appearanceReaction.compatibleAppearance = nil; return nil; }
        if (code == 24708) { appearanceTrait.mitigated = true; return nil; }
        return inherited(context);
    }
;
