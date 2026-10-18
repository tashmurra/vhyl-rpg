#include "expanded-carousing-entertainment.t"
interruptedAudience: object;
modify rpgLedger
    afterAdvance(previous)
    {
        inherited(previous);
        if (bleedInput.code == 2700) masteryEncounter.audience = interruptedAudience;
        if (bleedInput.code == 2701) secondReaction.resolve();
        if (bleedInput.code == 2702) carousingEntertainment.price = 11;
        if (bleedInput.code == 2703) reactionPreparation.entertainment = nil;
        if (bleedInput.code == 2704) entertainmentProvider.money = 2147483647;
        return nil;
    }
;
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code >= 2700 && code <= 2704) { reactionPreparation.resolve(); return nil; }
        if (code == 2705)
        {
            event('test.social-interruption'); eventValue(masteryEncounter.audience == masteryAudience ? 1 : 0);
            eventValue(reactionPreparation.entertainment == carousingEntertainment ? 1 : 0);
            eventValue(carousingEntertainment.price); eventValue(masteryEncounter.history.length());
            eventValue(masteryEncounter.preparationHistory.length()); return nil;
        }
        return inherited(context);
    }
;
