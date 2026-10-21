#include "expanded-market-offers.t"
coinConvention: RpgExpandedCoinage approved = true evidence = 'Campaign adopts the optional silver standard and twentyfold gold ratio';
coinStack: RpgExpandedCoinStock id = 'travel-coins' coinage = coinConvention;
coinWithdrawal: RpgExpandedCoinExchange id = 'withdraw' profile = bleedProfile stock = coinStack quantity = 250
    approved = true evidence = 'The character has access to an issuer exchanging existing funds for these coins';
coinPartialDeposit: RpgExpandedCoinExchange id = 'partial' profile = bleedProfile stock = coinStack direction = 'deposit' quantity = 5
    approved = true evidence = 'The recipient accepts five coins at adopted face value';
coinFinalDeposit: RpgExpandedCoinExchange id = 'final' profile = bleedProfile stock = coinStack direction = 'deposit' quantity = 245
    approved = true evidence = 'The recipient accepts all remaining coins at face value';
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 14700) { bleedProfile.money = 1000; return nil; }
        if (code == 14701)
        { local value = coinWithdrawal.assess(); event('test.coin-preview'); eventValue(value.status); eventValue(value.money); return nil; }
        if (code == 14702 || code == 14703)
        { coinWithdrawal.apply(); if (code == 14703) throw new RpgError(); return nil; }
        if (code == 14704)
        {
            event('test.coin-state'); eventValue(bleedProfile.money); eventValue(coinStack.quantity); eventValue(coinStack.faceValue());
            eventValue(coinStack.weightHundredths()); eventValue(bleedProfile.equipment.length());
            eventValue(bleedProfile.coinExchanges.length()); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 14705) { coinPartialDeposit.apply(); return nil; }
        if (code == 14706) { coinFinalDeposit.apply(); return nil; }
        if (code == 14707) { coinStack.metal = 'gold'; coinWithdrawal.quantity = 10; coinFinalDeposit.quantity = 5; return nil; }
        if (code == 14708)
        {
            coinConvention.goldRatio = 21;
            try { coinWithdrawal.assess(); }
            catch (RpgExpandedError error) { event('test.coin-reject'); eventValue(error.reason); } return nil;
        }
        return inherited(context);
    }
;
