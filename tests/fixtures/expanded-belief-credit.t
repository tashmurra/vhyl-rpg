#include "expanded-fixed-beliefs.t"
beliefCreditFinalization: RpgExpandedCharacterFinalization id = 'belief-credit-finalization' profile = bleedProfile
    approved = true evidence = 'Author allocated forty points across the beliefs';
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 11500)
        {
            bleedProfile.traits = [beliefOne,beliefTwo,beliefThree,beliefFour]; beliefFour.creditedPoints = 0;
            bleedProfile.disadvantageLimit = 40; return nil;
        }
        if (code == 11501)
        {
            event('test.belief-credit'); eventValue(rpgExpandedCharacterCost(bleedProfile,nil));
            eventValue(rpgExpandedCharacterCost(bleedProfile,true)); eventValue(beliefFour.creationCost());
            eventValue(bleedProfile.fixedBeliefReactionLevel(beliefFour)); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 11502 || code == 11503)
        { beliefCreditFinalization.apply(); if (code == 11503) throw new RpgError(); return nil; }
        if (code == 11504)
        {
            event('test.belief-credit-basis'); eventValue(bleedProfile.buyoffBases.length());
            eventValue(bleedProfile.disadvantageBuyoffCost(beliefFour)); return nil;
        }
        if (code == 11505) { beliefOne.creditedPoints = 9; return nil; }
        if (code == 11506)
        {
            local copy = rpgExpandedTemplateTraits.copy(beliefFour);
            event('test.belief-credit-copy'); eventValue(copy.creationCost()); eventValue(copy.level); eventValue(copy.creditedPoints); return nil;
        }
        return inherited(context);
    }
;
