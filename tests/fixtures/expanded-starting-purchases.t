#include "expanded.t"
startingBuyer: RpgExpandedProfile rules = expandedRules campaignTL = 3 contributions = [startingFortune];
startingFortune: RpgExpandedWealth owner = startingBuyer wealthLevel = 'comfortable';
startingAllocation: RpgExpandedWealthAllocation profile = startingBuyer wealth = startingFortune;
startingKit: RpgLiteItem id = 'imported-kit' cost = 100 techLevel = 4;
startingSecondKit: RpgLiteItem id = 'costly-kit' cost = 250 techLevel = 3;
startingIssuedKit: RpgLiteItem id = 'issued-kit' cost = 6000 techLevel = 9;
startingSale: RpgExpandedAcquisition profile = startingBuyer item = startingKit available = true permitted = true startingPurchase = true;
startingSecondSale: RpgExpandedAcquisition profile = startingBuyer item = startingSecondKit available = true permitted = true startingPurchase = true;
startingIssue: RpgExpandedAcquisition profile = startingBuyer item = startingIssuedKit available = true permitted = true mode = 'issue';
modify ExpandedTestAction
    exec(context)
    {
        local code = expandedInput.code;
        if (code == 15000 || code == 15001)
        { startingAllocation.allocate(); startingSale.acquire(); if (code == 15001) throw new RpgError(); return nil; }
        if (code == 15002)
        {
            event('test.starting-purchase-state'); eventValue(startingBuyer.money); eventValue(startingBuyer.equipment.length());
            eventValue(startingAllocation.total); eventValue(startingAllocation.cash); eventValue(startingAllocation.settledAssets);
            eventValue(rpgRandom.draws); return nil;
        }
        if (code == 15003)
        { local value = startingSecondSale.acquire(); event('test.starting-second-sale'); eventValue(value.status); eventValue(value.reason); return nil; }
        if (code == 15004) { startingIssue.acquire(); return nil; }
        if (code == 15005) { startingFortune.wealthLevel = 'wealthy'; startingAllocation.allocate(); return nil; }
        if (code == 15006 || code == 15007)
        {
            if (code == 15006) startingAllocation.mobile = true;
            else startingAllocation.cash = 999;
            try { startingAllocation.assess(); }
            catch (RpgExpandedError error) { event('test.starting-binding'); eventValue(error.reason); } return nil;
        }
        return inherited(context);
    }
;
