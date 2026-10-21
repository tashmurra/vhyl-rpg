#include "expanded-initial-wardrobe.t"
wardrobePurchasedStatus: RpgExpandedStatus id = 'standing' owner = lifestyleBuyer culture = initialClothesCulture level = 1;
wardrobeOffice: RpgExpandedRank id = 'office' owner = lifestyleBuyer culture = initialClothesCulture
    institution = 'council' level = 3 admitted = true;
wardrobeStructure: RpgExpandedSocialStructure culture = initialClothesCulture;
modify lifestyleBuyer contributions = [wardrobePurchasedStatus,wardrobeOffice];
modify lifestyleWardrobePrice status = 2;
modify initialClothes applicableStatus = nil socialStructure = wardrobeStructure;
modify ExpandedTestAction
    exec(context)
    {
        local code = expandedInput.code;
        if (code == 15700)
        {
            event('test.wardrobe-standing'); eventValue(lifestyleBuyer.initialWardrobeStanding(initialClothesCulture,wardrobeStructure));
            eventValue(lifestyleWardrobe.cost); eventValue(initialClothes.assess().money); eventValue(lifestyleBuyer.money); return nil;
        }
        if (code == 15701) { wardrobePurchasedStatus.level = 2; wardrobeOffice.level = 6; return nil; }
        if (code == 15702 || code == 15703 || code == 15704)
        {
            if (code == 15702) lifestyleWardrobePrice.status = 1;
            if (code == 15703) initialClothes.applicableStatus = 2;
            if (code == 15704) wardrobeStructure.culture = 'other-city';
            try { initialClothes.assess(); }
            catch (RpgExpandedError error) { event('test.wardrobe-standing-reject'); eventValue(error.reason); }
            return nil;
        }
        return inherited(context);
    }
;
