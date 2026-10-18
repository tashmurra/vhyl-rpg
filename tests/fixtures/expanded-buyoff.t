#include "expanded-compelled-aid.t"
modify aidTrait selfControlRating = 6;
modify bleedProfile earnedPoints = 100 unspentPoints = 100 developmentOpen = true buyoffBases = [aidBuyoff];
aidBuyoff: RpgExpandedBuyoffBasis owner = bleedProfile trait = aidTrait originalBonus = 30
    approved = true evidence = 'The original award was thirty points; the authored development permits removal';
buyoffReservation: object active = nil;
modify bleedProfile
    developmentSpendingReason() { return buyoffReservation.active ? 'reserved' : inherited(); }
;
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 5200 || code == 5201)
        {
            event('test.buyoff'); eventValue(rpgLiteBuyOff(bleedProfile,aidTrait) ? 1 : 0);
            if (code == 5201) throw new RpgError(); return nil;
        }
        if (code == 5202)
        { event('test.buyoff-state'); eventValue(bleedProfile.unspentPoints); eventValue(holds(bleedProfile.traits,aidTrait) ? 1 : 0); return nil; }
        if (code == 5203) { buyoffReservation.active = true; return nil; }
        if (code == 5204) { bleedProfile.buyoffBases = []; return nil; }
        if (code == 5205) { bleedProfile.unspentPoints = 29; return nil; }
        if (code == 5206) { aidTrait.selfControlRating = 12; return nil; }
        return inherited(context);
    }
;
