/* Include after the expanded foundation. Source: full-2008, B15-B16 and B550. */

/** Extended whole-yard speed/range lookup, rounding up to the next row.
 * Numeric support is bounded to 100 million yards to prevent integer overflow. */
rpgExpandedRangeModifier(yards)
{
    rpgInteger(yards, 0, 100000000);
    if (yards <= 2) return 0;
    local row = 0; local factor = 1;
    while (factor <= 100000000)
    {
        foreach (local limit in [3, 5, 7, 10, 15, 20])
        {
            row += 1;
            if (yards <= limit * factor) return -row;
        }
        factor *= 10;
    }
    throw new RpgError();
}

/** Full-reference damage rows, with B15's full-ten-point progression above 100.
 * Missing intermediate rows between 40 and 100 remain explicitly unsupported. */
rpgExpandedDamageDice(strength, swing)
{
    rpgInteger(strength, 1, 1000);
    if (strength > 100) return [(swing ? 13 : 11) + (strength - 100) / 10, 0];
    if (strength <= 20) return rpgLiteDamageDice(strength, swing);
    local rows = [
        [21,2,0,4,-1],[22,2,0,4,0],[23,2,1,4,1],[24,2,1,4,2],
        [25,2,2,5,-1],[26,2,2,5,0],[27,3,-1,5,1],[28,3,-1,5,1],
        [29,3,0,5,2],[30,3,0,5,2],[31,3,1,6,-1],[32,3,1,6,-1],
        [33,3,2,6,0],[34,3,2,6,0],[35,4,-1,6,1],[36,4,-1,6,1],
        [37,4,0,6,2],[38,4,0,6,2],[39,4,1,7,-1],[40,4,1,7,-1],
        [45,5,0,7,1],[50,5,2,8,-1],[55,6,0,8,1],[60,7,-1,9,0],
        [65,7,1,9,2],[70,8,0,10,0],[75,8,2,10,2],[80,9,0,11,0],
        [85,9,2,11,2],[90,10,0,12,0],[95,10,2,12,2],[100,11,0,13,0]];
    foreach (local row in rows)
        if (row[1] == strength) return swing ? [row[4],row[5]] : [row[2],row[3]];
    rpgExpandedReject('unsupported-strength-row'); return nil;
}

/** B550 size modifier. Measure the relevant dimension in thirtieths of an inch
 * to preserve every printed fractional-inch boundary without floating point.
 * shape is 0 for ordinary, 1 elongated box, or 2 box/sphere/blob. */
rpgExpandedSizeModifier(dimensionTicks, shape)
{
    rpgInteger(dimensionTicks, 6, 1000000000); rpgInteger(shape, 0, 2);
    local thresholds = [6,10,15,20,30,45,60,90,150,240,360,540,720,1080,1620,2160];
    for (local index = 1; index <= thresholds.length(); index += 1)
        if (dimensionTicks <= thresholds[index]) return index - 16 + shape;
    /* All larger printed thresholds are whole yards. Round up before lookup. */
    return -rpgExpandedRangeModifier((dimensionTicks + 1079) / 1080) + shape;
}

/** B550 speed/range combination, with explicit author selection of speed use. */
rpgExpandedSpeedRangeModifier(yards, yardsPerSecond, includeSpeed)
{
    rpgInteger(yards, 0, 100000000); rpgInteger(yardsPerSecond, 0, 100000000);
    if (!includeSpeed) return rpgExpandedRangeModifier(yards);
    if (yardsPerSecond > 100000000 - yards) rpgExpandedReject('speed-range-limit');
    return rpgExpandedRangeModifier(yards + yardsPerSecond);
}

/** Authored task-specific equipment adequacy, B345. It describes the tools
 * actually available for this operation, not a permanent skill or item bonus. */
class RpgExpandedEquipmentAssessment: object
    quality = 'basic'
    allowWithoutEquipment = nil
    techLevel = nil
    missingItems = 0
    damagePenalty = 0
    assess(skill)
    {
        if (skill == nil || !skill.ofKind(RpgSkill)) rpgExpandedReject('equipment-skill-required');
        if (!holds(['none','improvised','basic','good','fine','best'], self.quality))
            rpgExpandedReject('equipment-quality');
        rpgInteger(self.missingItems, 0, 1000); rpgInteger(self.damagePenalty, 0, 3);
        if (self.techLevel != nil) rpgInteger(self.techLevel, 0, 12);
        local value = new RpgExpandedResult();
        local technological = skill.ofKind(RpgLiteSkill) && skill.techLevel != nil;
        if (self.quality == 'none' || self.quality == 'improvised')
        {
            if (self.missingItems != 0 || self.damagePenalty != 0)
                rpgExpandedReject('equipment-condition-inapplicable');
            if (self.quality == 'none' && !self.allowWithoutEquipment)
            { value.reason = 'equipment-required'; return value; }
            value.modifier = self.quality == 'none' ? (technological ? -10 : -5)
                : (technological ? -5 : -2);
        }
        else
        {
            local bonus = self.quality == 'good' ? 1 : self.quality == 'fine' ? 2 : 0;
            if (self.quality == 'best')
            {
                if (self.techLevel == nil) rpgExpandedReject('equipment-technology-required');
                bonus = self.techLevel / 2; if (bonus < 2) bonus = 2;
            }
            value.modifier = bonus - self.missingItems - self.damagePenalty;
        }
        value.status = 'ready'; return value;
    }
;

modify RpgLiteContext
    equipmentAssessment = nil
    equipmentUseModifier(profile)
    {
        if (self.equipmentAssessment == nil) return 0;
        if (!self.equipmentAssessment.ofKind(RpgExpandedEquipmentAssessment))
            rpgExpandedReject('equipment-assessment');
        local value = self.equipmentAssessment.assess(self.skill);
        return value.status == 'ready' ? value.modifier : nil;
    }
    unavailableReason(profile)
    {
        if (self.equipmentAssessment != nil)
        {
            if (!self.equipmentAssessment.ofKind(RpgExpandedEquipmentAssessment))
                rpgExpandedReject('equipment-assessment');
            local value = self.equipmentAssessment.assess(self.skill);
            if (value.status != 'ready') return value.reason;
        }
        return inherited(profile);
    }
;

/** Starting equipment price at the campaign technology level, full-2008 B27. */
rpgExpandedStartingEquipmentPrice(basePrice, itemTL, campaignTL)
{
    rpgInteger(basePrice, 0, 2147483647);
    rpgInteger(itemTL, 0, 12); rpgInteger(campaignTL, 0, 12);
    local price = basePrice;
    for (local level = campaignTL; level < itemTL; level += 1)
    {
        if (price > 1073741823) rpgExpandedReject('starting-equipment-price-limit');
        price *= 2;
    }
    return price;
}

/** Acquisition receipt; money is the nonnegative amount charged, not points. */
class RpgExpandedAcquisitionResult: RpgExpandedResult
    money = 0
    item = nil
;

/** One authored sale or issue of an existing physical item, B264-B267.
 * Availability and local permission are separate facts supplied by the world. */
class RpgExpandedAcquisition: object
    profile = nil
    item = nil
    mode = 'purchase'
    quote = nil
    startingPurchase = nil
    available = nil
    permitted = nil
    claimed = nil
    claimedProfile = nil
    claimedItem = nil
    authorizationReason() { return self.permitted ? nil : 'equipment-permission'; }
    assess()
    {
        if (self.profile == nil || !self.profile.ofKind(RpgExpandedProfile)
            || self.item == nil || !self.item.ofKind(RpgLiteItem))
            rpgExpandedReject('acquisition-target');
        if (!holds(['purchase','issue'], self.mode)) rpgExpandedReject('acquisition-mode');
        if (self.claimed && (self.profile != self.claimedProfile || self.item != self.claimedItem))
            rpgExpandedReject('acquisition-retargeted');
        local value = new RpgExpandedAcquisitionResult(); value.item = self.item;
        if (self.claimed) { value.status = 'reused'; return value; }
        rpgExpandedValidate(self.profile);
        rpgInteger(self.profile.money, 0, 2147483647);
        rpgInteger(self.item.quantity, 1, 1000000);
        rpgInteger(self.item.weight, 0, 2147483647 / self.item.quantity);
        rpgInteger(self.item.cost, 0, 2147483647);
        if (self.quote != nil) rpgInteger(self.quote, 0, 2147483647);
        if (self.startingPurchase)
        {
            if (self.mode != 'purchase' || self.quote != nil)
                rpgExpandedReject('starting-equipment-price-source');
            if (self.item.techLevel == nil) rpgExpandedReject('starting-equipment-technology-required');
            if (self.profile.creationComplete)
            { value.reason = 'starting-equipment-creation-only'; return value; }
        }
        if (self.mode == 'issue' && self.quote != nil && self.quote != 0)
            rpgExpandedReject('issued-equipment-price');
        if (!self.available) { value.reason = 'equipment-unavailable'; return value; }
        value.reason = self.authorizationReason();
        if (value.reason != nil) return value;
        for (local owner = firstObj(RpgProfile); owner != nil; owner = nextObj(owner,RpgProfile))
            if (owner.ofKind(RpgLiteProfile) && holds(owner.equipment,self.item))
            { value.reason = 'equipment-already-owned'; return value; }
        local price = self.mode == 'issue' ? 0 : self.quote == nil ? self.item.cost : self.quote;
        if (self.startingPurchase)
            price = rpgExpandedStartingEquipmentPrice(price,self.item.techLevel,self.profile.campaignTL);
        if (self.profile.money < price) { value.reason = 'equipment-unaffordable'; return value; }
        value.money = price; value.status = 'ready'; return value;
    }
    acquire()
    {
        local value = self.assess();
        if (value.status != 'ready') return value;
        self.profile.money -= value.money;
        self.profile.equipment = self.profile.equipment + [self.item];
        self.claimed = true; self.claimedProfile = self.profile; self.claimedItem = self.item;
        value.status = 'resolved'; return value;
    }
;

modify RpgLiteItem
    /* Generic items require an authored level for starting-price calculations. */
    techLevel = nil
    /* nil means carried; a non-nil authored location means stored off-character. */
    storageLocation = nil
    usableBy(profile) { return self.storageLocation == nil; }
;

/** Move an owned item between carried state and an authored storage location.
 * Ownership remains in the same inventory; accessibility is an explicit fact. */
class RpgExpandedEquipmentStorage: object
    profile = nil
    item = nil
    destination = nil
    accessible = nil
    assess()
    {
        if (self.profile == nil || !self.profile.ofKind(RpgExpandedProfile)
            || self.item == nil || !self.item.ofKind(RpgLiteItem)
            || !holds(self.profile.equipment,self.item))
            rpgExpandedReject('storage-ownership');
        local value = new RpgExpandedAcquisitionResult(); value.item = self.item;
        if (self.item.storageLocation == self.destination) { value.status = 'reused'; return value; }
        if (!self.accessible) { value.reason = 'storage-inaccessible'; return value; }
        if (self.profile.dead || self.profile.unconscious)
        { value.reason = 'cannot-move-equipment'; return value; }
        value.status = 'ready'; return value;
    }
    move()
    {
        local value = self.assess();
        if (value.status != 'ready') return value;
        self.item.storageLocation = self.destination;
        self.item.worn = nil; self.item.ready = nil;
        for (local fighter = firstObj(RpgLiteFighter); fighter != nil; fighter = nextObj(fighter,RpgLiteFighter))
            if (fighter.profile == self.profile && fighter.aimWeapon == self.item)
            { fighter.aimSeconds = 0; fighter.aimTarget = nil; fighter.aimWeapon = nil; }
        value.status = 'resolved'; return value;
    }
;

modify RpgExpandedProfile
    tradeReceipts = []
;

/** Commit a quoted sale of one existing inventory item/bundle. Price is the
 * agreed whole-item price, not multiplied by the item's quantity. */
class RpgExpandedTradeTransfer: object
    id = nil
    buyer = nil
    seller = nil
    item = nil
    price = 0
    buyerAgrees = nil
    sellerAgrees = nil
    available = nil
    permitted = nil
    claimed = nil
    boundBuyer = nil
    boundSeller = nil
    boundItem = nil
    boundId = nil
    authorizationReason() { return self.permitted ? nil : 'trade-permission'; }
    assess()
    {
        if (self.id == nil || self.buyer == nil || !self.buyer.ofKind(RpgExpandedProfile)
            || self.seller == nil || !self.seller.ofKind(RpgExpandedProfile) || self.buyer == self.seller
            || self.item == nil || !self.item.ofKind(RpgLiteItem))
            rpgExpandedReject('trade-transfer-target');
        if (self.claimed && (self.buyer != self.boundBuyer || self.seller != self.boundSeller
            || self.item != self.boundItem || self.id != self.boundId)) rpgExpandedReject('trade-transfer-retargeted');
        local value = new RpgExpandedAcquisitionResult(); value.item = self.item;
        foreach (local receipt in self.buyer.tradeReceipts)
            if (receipt[1] == self.id)
            {
                if (receipt[2] != self.seller || receipt[3] != self.item) rpgExpandedReject('trade-transfer-id-conflict');
                value.status = 'reused'; return value;
            }
        rpgExpandedValidate(self.buyer); rpgExpandedValidate(self.seller);
        rpgInteger(self.price,0,2147483647);
        rpgInteger(self.buyer.money,0,2147483647); rpgInteger(self.seller.money,0,2147483647);
        rpgInteger(self.item.quantity,1,1000000); rpgInteger(self.item.weight,0,2147483647 / self.item.quantity);
        if (!self.buyerAgrees || !self.sellerAgrees) { value.reason = 'trade-agreement'; return value; }
        if (!self.available) { value.reason = 'trade-item-unavailable'; return value; }
        value.reason = self.authorizationReason(); if (value.reason != nil) return value;
        local owners = 0;
        for (local profile = firstObj(RpgProfile); profile != nil; profile = nextObj(profile,RpgProfile))
            if (profile.ofKind(RpgLiteProfile))
                foreach (local entry in profile.equipment)
                    if (entry == self.item)
                    {
                        if (profile != self.seller) { value.reason = 'trade-item-ownership'; return value; }
                        owners += 1;
                    }
        if (owners != 1) { value.reason = 'trade-item-ownership'; return value; }
        if (self.buyer.money < self.price) { value.reason = 'trade-funds'; return value; }
        if (self.seller.money > 2147483647 - self.price) rpgExpandedReject('trade-money-limit');
        value.money = self.price; value.status = 'ready'; return value;
    }
    transfer()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        local remaining = [];
        foreach (local entry in self.seller.equipment) if (entry != self.item) remaining = remaining + [entry];
        self.seller.equipment = remaining; self.buyer.equipment = self.buyer.equipment + [self.item];
        self.buyer.money -= value.money; self.seller.money += value.money;
        self.item.storageLocation = nil; self.item.worn = nil; self.item.ready = nil;
        for (local fighter = firstObj(RpgLiteFighter); fighter != nil; fighter = nextObj(fighter,RpgLiteFighter))
            if (fighter.aimWeapon == self.item)
            { fighter.aimSeconds = 0; fighter.aimTarget = nil; fighter.aimWeapon = nil; }
        self.buyer.tradeReceipts = self.buyer.tradeReceipts + [[self.id,self.seller,self.item,value.money]];
        self.claimed = true; self.boundBuyer = self.buyer; self.boundSeller = self.seller;
        self.boundItem = self.item; self.boundId = self.id;
        value.status = 'resolved'; return value;
    }
;

/** Prepared forced drop from knockdown, full-2008 B420. Item identities remain
 * in the owner's inventory; storageLocation makes them no longer carried. */
class RpgExpandedKnockdownDrop: RpgExpandedResult
    profile = nil
    destination = nil
    items = []
    committed = nil
    commit()
    {
        if (self.committed) return 'reused';
        if (self.status != 'ready' || self.profile == nil || self.destination == nil)
            rpgExpandedReject('knockdown-drop-unprepared');
        foreach (local item in self.items)
            if (!holds(self.profile.equipment,item) || item.storageLocation != nil || item.worn)
                rpgExpandedReject('knockdown-drop-item-changed');
        foreach (local item in self.items)
        {
            item.storageLocation = self.destination; item.ready = nil;
            for (local fighter = firstObj(RpgLiteFighter); fighter != nil; fighter = nextObj(fighter,RpgLiteFighter))
                if (fighter.profile == self.profile && fighter.aimWeapon == item)
                { fighter.aimSeconds = 0; fighter.aimTarget = nil; fighter.aimWeapon = nil; }
        }
        self.committed = true; return 'resolved';
    }
;

modify RpgExpandedProfile
    prepareKnockdownDrop(destination)
    {
        local items = [];
        foreach (local item in self.equipment)
            if (item.ready && !item.worn)
            {
                if (!item.ofKind(RpgLiteItem) || item.storageLocation != nil)
                    rpgExpandedReject('knockdown-drop-item-changed');
                items = items + [item];
            }
        if (items.length() == 0) return nil;
        local value = new RpgExpandedKnockdownDrop(); value.profile = self;
        value.destination = destination; value.items = items;
        if (destination == nil) { value.reason = 'knockdown-drop-destination-required'; return value; }
        value.status = 'ready'; return value;
    }
;
