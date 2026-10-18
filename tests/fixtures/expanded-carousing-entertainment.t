#include "expanded-reaction-preparation.t"
entertainmentProvider: RpgLiteProfile money = 0;
modify bleedProfile money = 50;
modify reactionPreparation skill = preparationCarousing reactionKind = 'general' entertainment = carousingEntertainment;
carousingEntertainment: RpgExpandedCarousingEntertainment id = 'refreshments' preparation = reactionPreparation
    payer = bleedProfile provider = entertainmentProvider price = 10 bonus = 3 available = true approved = true
    evidence = 'The author sets a ten-unit price and +3 for suitable entertainment provided to this audience';
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 2600)
        {
            event('test.entertainment'); eventValue(bleedProfile.money); eventValue(entertainmentProvider.money);
            eventValue(bleedProfile.entertainmentPurchases.length()); eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
        }
        if (code == 2601) { bleedProfile.money = 5; return nil; }
        if (code == 2602) { carousingEntertainment.bonus = 1; return nil; }
        if (code == 2603) { carousingEntertainment.available = nil; return nil; }
        return inherited(context);
    }
;
