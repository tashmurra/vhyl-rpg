#include "expanded-coins.t"
purchaseTender: RpgExpandedCoinTender acquisition = marketAcquisition coins = [[coinStack,6]] cash = 1 approved = true
    evidence = 'Merchant accepts six silver coins and one unit from the existing abstract purse';
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 14800)
        { bleedProfile.money = 25; coinWithdrawal.quantity = 6; marketAcquisition.coinTender = purchaseTender; return nil; }
        if (code == 14801)
        { bleedProfile.money = 1001; coinWithdrawal.quantity = 250; return nil; }
        if (code == 14802)
        {
            event('test.coin-purchase-state'); eventValue(bleedProfile.money); eventValue(coinStack.quantity);
            eventValue(coinStack.faceValue()); eventValue(bleedProfile.equipment.length());
            eventValue(holds(bleedProfile.equipment,marketItem) ? 1 : 0); eventValue(purchaseTender.recorded ? 1 : 0);
            eventValue(rpgRandom.draws); return nil;
        }
        if (code == 14803) { purchaseTender.approved = nil; return nil; }
        if (code == 14804) { purchaseTender.cash = 0; return nil; }
        if (code == 14805)
        {
            purchaseTender.cash = 2;
            try { marketAcquisition.assess(); }
            catch (RpgExpandedError error) { event('test.coin-purchase-reject'); eventValue(error.reason); } return nil;
        }
        return inherited(context);
    }
;
