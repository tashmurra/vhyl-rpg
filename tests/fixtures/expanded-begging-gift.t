#include "expanded-begging-hour.t"
#include <vhyl-rpg-expanded-equipment.t>
beggingGiftItem: RpgLiteItem id = 'warm-coat' weight = 300 quantity = 1;
beggingDonor: RpgExpandedProfile rules = healthRules equipment = [beggingGiftItem];
modify beggingHour criticalBonus = 'A resident gives a warm coat';
beggingGift: RpgExpandedBeggingGift id = 'coat-gift' hour = beggingHour seller = beggingDonor buyer = crossPhysician
    item = beggingGiftItem buyerAgrees = true sellerAgrees = true available = true permitted = true evidence = 'The resident hands over the coat';
beggingSecondGift: RpgExpandedBeggingGift id = 'second-coat-gift' hour = beggingHour seller = beggingDonor buyer = crossPhysician
    item = beggingGiftItem buyerAgrees = true sellerAgrees = true available = true permitted = true evidence = 'Another request against the same bonus';
modify PhysicianFixtureAction
    exec(context)
    {
        local code = healthInput.code;
        if (code == 24500 || code == 24501)
        { local value = beggingGift.transfer(); event('test.begging-gift'); eventValue(value.status); eventValue(value.reason);
          if (code == 24501) throw new RpgError(); return nil; }
        if (code == 24502)
        { event('test.begging-gift-state'); eventValue(holds(crossPhysician.equipment,beggingGiftItem) ? 1 : 0);
          eventValue(holds(beggingDonor.equipment,beggingGiftItem) ? 1 : 0); eventValue(crossPhysician.tradeReceipts.length());
          eventValue(crossPhysician.money); eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil; }
        if (code == 24503)
        { local value = beggingSecondGift.assess(); event('test.begging-gift'); eventValue(value.status); eventValue(value.reason); return nil; }
        if (code == 24504)
        {
            beggingHour.result.check.critical = 'success';
            try { beggingGift.assess(); }
            catch (RpgExpandedError error) { event('test.begging-gift-error'); eventValue(error.reason); }
            return nil;
        }
        return inherited(context);
    }
;
