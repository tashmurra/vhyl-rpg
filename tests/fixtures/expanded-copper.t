#include "expanded-coin-purchases.t"
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 14900)
        {
            bleedProfile.money = 25; coinStack.metal = 'copper'; coinWithdrawal.quantity = 25;
            coinConvention.copperWeightThousandths = 5;
            coinConvention.copperWeightEvidence = 'Synthetic fixture convention: each copper coin weighs five thousandths of a pound';
            purchaseTender.coins = [[coinStack,25]]; purchaseTender.cash = 0; marketAcquisition.coinTender = purchaseTender; return nil;
        }
        if (code == 14901)
        {
            event('test.copper-mass');
            foreach (local quantity in [1,2,3,25])
            {
                local stock = new RpgExpandedCoinStock(); stock.id = 'mass-probe'; stock.coinage = coinConvention;
                stock.metal = 'copper'; stock.quantity = quantity; eventValue(stock.weightHundredths());
            }
            return nil;
        }
        if (code == 14902 || code == 14903)
        {
            coinConvention.copperWeightThousandths = code == 14902 ? nil : 6;
            try { coinWithdrawal.assess(); }
            catch (RpgExpandedError error) { event('test.copper-reject'); eventValue(error.reason); } return nil;
        }
        return inherited(context);
    }
;
