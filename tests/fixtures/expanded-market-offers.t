#include "expanded-digging-equipment.t"
marketPlace: object;
marketItem: RpgLiteItem id = 'field-kit' cost = 20 weight = 100;
marketQuote: RpgExpandedMarketOffer id = 'local-kit-offer' item = marketItem market = marketPlace baselinePrice = 20 price = 25
    approved = true evidence = 'A local shortage increases this merchant offer above the normal baseline';
marketAcquisition: RpgExpandedAcquisition profile = bleedProfile item = marketItem marketOffer = marketQuote available = true permitted = true;
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 14600)
        { local value = marketAcquisition.assess(); event('test.market-preview'); eventValue(value.status); eventValue(value.reason); eventValue(value.money); return nil; }
        if (code == 14601 || code == 14602)
        { marketAcquisition.acquire(); if (code == 14602) throw new RpgError(); return nil; }
        if (code == 14603)
        {
            event('test.market-state'); eventValue(bleedProfile.money); eventValue(bleedProfile.equipment.length());
            eventValue(marketItem.cost); eventValue(marketQuote.baselinePrice); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 14604) { marketQuote.currency = 'foreign-unit'; return nil; }
        if (code == 14605) { marketQuote.approved = nil; return nil; }
        if (code == 14606) { marketItem.cost = 50; return nil; }
        if (code == 14607 || code == 14608)
        {
            if (code == 14607) marketQuote.price = 1;
            else marketAcquisition.quote = 1;
            try { marketAcquisition.assess(); }
            catch (RpgExpandedError error) { event('test.market-reject'); eventValue(error.reason); } return nil;
        }
        return inherited(context);
    }
;
