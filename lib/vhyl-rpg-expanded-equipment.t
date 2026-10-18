/* Include after the expanded foundation. Source: full-2008, B15-B16 and B550. */

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
    assessFor(profile,skill) { return self.assess(skill); }
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
        local value = self.equipmentAssessment.assessFor(profile,self.skill);
        return value.status == 'ready' ? value.modifier : nil;
    }
    unavailableReason(profile)
    {
        if (self.equipmentAssessment != nil)
        {
            if (!self.equipmentAssessment.ofKind(RpgExpandedEquipmentAssessment))
                rpgExpandedReject('equipment-assessment');
            local value = self.equipmentAssessment.assessFor(profile,self.skill);
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
    marketOffer = nil
    coinTender = nil
    boundCoinTender = nil
    boundMarketOffer = nil
    boundMarketFacts = nil
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
        if (self.claimed)
        {
            if (self.coinTender != self.boundCoinTender) rpgExpandedReject('acquisition-tender-retargeted');
            if (self.coinTender != nil) self.coinTender.validateReceipt(self);
            if (self.marketOffer != self.boundMarketOffer) rpgExpandedReject('acquisition-market-retargeted');
            if (self.marketOffer != nil)
            {
                local facts = self.marketOffer.definition() + [self.mode,self.quote,self.startingPurchase];
                if (self.boundMarketFacts == nil || facts.length() != self.boundMarketFacts.length())
                    rpgExpandedReject('acquisition-market-binding');
                for (local index = 1; index <= facts.length(); index += 1)
                    if (facts[index] != self.boundMarketFacts[index]) rpgExpandedReject('acquisition-market-binding');
            }
            value.status = 'reused'; return value;
        }
        rpgExpandedValidate(self.profile);
        rpgInteger(self.profile.money, 0, 2147483647);
        self.item.validateAcquisition();
        rpgInteger(self.item.quantity, 1, 1000000);
        rpgInteger(self.item.weight, 0, 2147483647 / self.item.quantity);
        rpgInteger(self.item.cost, 0, 2147483647);
        if (self.quote != nil) rpgInteger(self.quote, 0, 2147483647);
        if (self.marketOffer != nil)
        {
            if (!self.marketOffer.ofKind(RpgExpandedMarketOffer) || self.mode != 'purchase'
                || self.quote != nil || self.startingPurchase) rpgExpandedReject('acquisition-market-price-source');
            value.reason = self.marketOffer.assess(self.profile,self.item);
            if (value.reason != nil) return value;
        }
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
        if (self.marketOffer != nil) price = self.marketOffer.price;
        if (self.startingPurchase)
            price = rpgExpandedStartingEquipmentPrice(price,self.item.techLevel,self.profile.campaignTL);
        if (self.coinTender == nil)
        { if (self.profile.money < price) { value.reason = 'equipment-unaffordable'; return value; } }
        else
        {
            if (self.mode != 'purchase' || !self.coinTender.ofKind(RpgExpandedCoinTender))
                rpgExpandedReject('acquisition-tender-definition');
            value.reason = self.coinTender.assess(self,price); if (value.reason != nil) return value;
        }
        value.money = price; value.status = 'ready'; return value;
    }
    acquire()
    {
        local value = self.assess();
        if (value.status != 'ready') return value;
        self.boundMarketOffer = self.marketOffer;
        if (self.marketOffer != nil) self.boundMarketFacts = self.marketOffer.definition() + [self.mode,self.quote,self.startingPurchase];
        self.boundCoinTender = self.coinTender;
        if (self.coinTender == nil) self.profile.money -= value.money;
        else self.coinTender.commitPayment(self,value.money);
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
    thrownFlight = nil
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
        if (self.item.thrownFlight != nil) { value.reason = 'equipment-in-flight'; return value; }
        if (self.item.sharedCarry != nil) { value.reason = 'equipment-in-shared-carry'; return value; }
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
        self.profile.onEquipmentUnavailable(self.item,'storage-change');
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
        if (self.item.thrownFlight != nil) { value.reason = 'equipment-in-flight'; return value; }
        if (self.item.sharedCarry != nil) { value.reason = 'equipment-in-shared-carry'; return value; }
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
        self.seller.onEquipmentUnavailable(self.item,'transferred');
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
    allowWorn = nil
    commit()
    {
        if (self.committed) return 'reused';
        if (self.status != 'ready' || self.profile == nil || !self.profile.ofKind(RpgExpandedProfile)
            || self.destination == nil)
            rpgExpandedReject('knockdown-drop-unprepared');
        foreach (local item in self.items)
            if (item == nil || !item.ofKind(RpgLiteItem) || !holds(self.profile.equipment,item)
                || item.storageLocation != nil || item.worn && !self.allowWorn)
                rpgExpandedReject('knockdown-drop-item-changed');
        foreach (local item in self.items)
        {
            item.storageLocation = self.destination; item.ready = nil;
            if (self.allowWorn) item.worn = nil;
            self.profile.onEquipmentDropped(item);
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


modify RpgExpandedProfile
    prepareForcedDrop(items, destination)
    {
        if (items.length() == 0) return nil;
        local value = new RpgExpandedKnockdownDrop(); value.profile = self;
        value.destination = destination; value.items = items; value.allowWorn = true;
        foreach (local item in items)
            if (item == nil || !item.ofKind(RpgLiteItem) || !holds(self.equipment,item)
                || item.storageLocation != nil) rpgExpandedReject('forced-drop-item');
        if (destination == nil) { value.reason = 'forced-drop-destination-required'; return value; }
        value.status = 'ready'; return value;
    }
;

/** B289 physical digging tools. Material is a separate authored fact, not inferred from TL. */
class RpgExpandedDiggingTool: RpgLiteItem
    toolKind = 'shovel'
    cost = 12
    weight = 600
    techLevel = 1
    legalityClass = 4
    diggingMaterial = nil
    materialEvidence = nil
    validateAcquisition()
    {
        if (!holds(['pickaxe','shovel'],self.toolKind) || self.quantity != 1 || self.legalityClass != 4
            || self.cost != (self.toolKind == 'pickaxe' ? 15 : 12)
            || self.weight != (self.toolKind == 'pickaxe' ? 800 : 600)
            || self.techLevel != (self.toolKind == 'pickaxe' ? 2 : 1)) rpgExpandedReject('digging-tool-catalogue');
        return nil;
    }
    diggingUseReason(role,material)
    {
        self.validateAcquisition();
        if (role != (self.toolKind == 'pickaxe' ? 'pick' : 'shovel')) return 'digging-tool-role';
        if (!holds(['metal','wood','improvised'],self.diggingMaterial)
            || self.materialEvidence == nil || self.materialEvidence == '') return 'digging-tool-material-evidence';
        if (material != self.diggingMaterial) return 'digging-tool-material-mismatch';
        return nil;
    }
;
rpgExpandedDiggingTool(id,kind)
{
    if (id == nil || id == '' || !holds(['pickaxe','shovel'],kind)) rpgExpandedReject('digging-tool-definition');
    local item = new RpgExpandedDiggingTool(); item.id = id; item.toolKind = kind;
    if (kind == 'pickaxe') { item.cost = 15; item.weight = 800; item.techLevel = 2; }
    item.validateAcquisition(); return item;
}

modify RpgExpandedProfile
    liftingReceipts = []
;
/** Pick up one already owned, stored item outside combat. Storage is not a second inventory. */
class RpgExpandedEquipmentLift: RpgExpandedLiftIdentity
    id = nil
    profile = nil
    item = nil
    sourceLocation = nil
    mode = 'two-hands'
    skillAttempt = nil
    failedAttemptSeconds = nil
    failureTimingEvidence = nil
    accessible = nil
    freeHands = 0
    hands = []
    approved = nil
    evidence = nil
    result = nil
    boundDefinition = nil
    startedAt = nil
    completedAt = nil
    definition()
    { return [self.id,self.profile,self.item,self.sourceLocation,self.mode,self.accessible,
        self.freeHands,self.approved,self.evidence,self.skillAttempt,self.failedAttemptSeconds,self.failureTimingEvidence,self.hands.length()] + self.hands; }
    liftingDefinition()
    { return self.definition() + [self.item.weightHundredths(),self.profile.basicLiftHundredths()]; }
    skillPreparationReason()
    {
        if (self.result != nil) return 'lifting-already-completed';
        local value = self.assess();
        return value.status == 'ready' || holds(['lifting-capacity','lifting-skill-unresolved'],value.reason)
            ? nil : value.reason;
    }
    prepare()
    {
        local value = new RpgExpandedResult();
        if (!self.approved || !self.accessible || self.evidence == nil || self.evidence == '')
        { value.reason = 'lifting-author-facts'; return value; }
        if (self.item.thrownFlight != nil) { value.reason = 'equipment-in-flight'; return value; }
        if (self.item.sharedCarry != nil) { value.reason = 'equipment-in-shared-carry'; return value; }
        if (!holds(self.profile.equipment,self.item))
        { value.reason = 'lifting-item-ownership'; return value; }
        if (self.item.storageLocation != self.sourceLocation)
        { value.reason = 'lifting-item-location'; return value; }
        if (!holds(['one-hand','two-hands'],self.mode)) rpgExpandedReject('lifting-pickup-mode');
        local required = self.mode == 'one-hand' ? 1 : 2;
        rpgInteger(self.freeHands,0,100);
        if (self.freeHands < required) { value.reason = 'lifting-free-hands'; return value; }
        value.reason = self.profile.liftingHandsReason(self.hands,required);
        if (value.reason == nil) value.reason = self.profile.reservedLiftingHandsReason(self.hands);
        if (value.reason != nil) return value;
        if (self.profile.dead || self.profile.unconscious || self.profile.mortal || self.profile.stunned
            || self.profile.mentalStun || self.profile.hp() <= 0 || self.profile.fp() <= 0
            || self.profile.voluntaryMovementUnavailable()
            || self.profile.healthEffortReason('action',nil,nil,true) != nil)
        { value.reason = 'lifting-actor-unavailable'; return value; }
        rpgInteger(self.item.weight,1,1000000); rpgInteger(self.item.quantity,1,100);
        if (self.profile.loadHundredths() + self.item.weightHundredths() > self.profile.basicLiftHundredths() * 10)
        { value.reason = 'lifting-overload-execution-required'; return value; }
        return self.skillAttempt == nil
            ? rpgExpandedLiftingRules.assess(self.profile.basicLiftHundredths(),self.item.weightHundredths(),self.mode)
            : rpgExpandedLiftingRules.assessWithSkill(self,self.skillAttempt);
    }
    assess()
    {
        if (self.id == nil || self.id == '' || self.profile == nil || !self.profile.ofKind(RpgExpandedProfile)
            || self.item == nil || !self.item.ofKind(RpgLiteItem) || !holds(self.profile.equipment,self.item)
            || self.sourceLocation == nil) rpgExpandedReject('lifting-definition');
        if (self.result != nil)
        {
            local current = self.definition();
            if (current.length() != self.boundDefinition.length()) rpgExpandedReject('lifting-binding');
            for (local index = 1; index <= current.length(); index += 1)
                if (current[index] != self.boundDefinition[index]) rpgExpandedReject('lifting-binding');
            if (!holds(self.profile.liftingReceipts,self)) rpgExpandedReject('lifting-history');
            local reused = new RpgExpandedResult(); reused.status = 'reused'; return reused;
        }
        foreach (local prior in self.profile.liftingReceipts)
            if (prior.id == self.id) rpgExpandedReject('lifting-duplicate');
        local value = self.prepare();
        if (value.status == 'ready')
        { rpgInteger(rpgLedger.seconds,0,2147483647-value.seconds); rpgLedger.validateAdvance(value.seconds); }
        return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status == 'reused') return self.result;
        if (value.status != 'ready') return value;
        local definition = self.definition(); local start = rpgLedger.seconds;
        local weight = self.item.weightHundredths(); local lift = self.profile.basicLiftHundredths();
        rpgSpendTime(value.seconds);
        local current = self.definition();
        if (current.length() != definition.length()) rpgExpandedReject('lifting-interrupted');
        for (local index = 1; index <= current.length(); index += 1)
            if (current[index] != definition[index]) rpgExpandedReject('lifting-interrupted');
        local after = self.prepare();
        if (after.status != 'ready' || after.seconds != value.seconds || rpgLedger.seconds != start + value.seconds
            || self.item.weightHundredths() != weight || self.profile.basicLiftHundredths() != lift)
            rpgExpandedReject('lifting-conditions-changed');
        self.item.storageLocation = nil; self.item.ready = nil; self.item.worn = nil;
        self.startedAt = start; self.completedAt = rpgLedger.seconds; self.boundDefinition = definition;
        self.profile.liftingReceipts = self.profile.liftingReceipts + [self];
        value.pickedUp = true; value.status = 'resolved'; self.result = value; return value;
    }
;

modify RpgExpandedEquipmentLift
    /** Failure timing is explicit author adjudication; B353 does not specify it. */
    assessAttempt()
    {
        local value = self.assess();
        if (value.status == 'reused' || self.skillAttempt == nil) return value;
        if (value.status != 'ready' && !holds(['lifting-skill-unresolved','lifting-capacity'],value.reason)) return value;
        if (self.failedAttemptSeconds == nil || self.failureTimingEvidence == nil || self.failureTimingEvidence == '')
        { local blocked = new RpgExpandedResult(); blocked.reason = 'lifting-failure-timing-required'; return blocked; }
        rpgInteger(self.failedAttemptSeconds,1,86400);
        local skillValue = self.skillAttempt.assess();
        if (!holds(['ready','reused'],skillValue.status)) return skillValue;
        local seconds = self.item.weightHundredths() <= self.profile.basicLiftHundredths()
            ? 1 : self.mode == 'one-hand' ? 2 : 4;
        local maximum = seconds > self.failedAttemptSeconds ? seconds : self.failedAttemptSeconds;
        rpgInteger(rpgLedger.seconds,0,2147483647-maximum);
        rpgLedger.validateAdvance(seconds); rpgLedger.validateAdvance(self.failedAttemptSeconds);
        local ready = new RpgExpandedResult(); ready.status = 'ready'; return ready;
    }
    attempt()
    {
        local preparation = self.assessAttempt();
        if (preparation.status == 'reused') return self.result;
        if (preparation.status != 'ready') return preparation;
        if (self.skillAttempt == nil) return self.apply();
        self.skillAttempt.resolve();
        local value = self.assess();
        if (value.status == 'ready') return self.apply();
        if (value.reason != 'lifting-capacity') rpgExpandedReject('lifting-attempt-changed');
        local definition = self.liftingDefinition(); local start = rpgLedger.seconds;
        rpgSpendTime(self.failedAttemptSeconds);
        local current = self.liftingDefinition();
        if (current.length() != definition.length()) rpgExpandedReject('lifting-interrupted');
        for (local index = 1; index <= current.length(); index += 1)
            if (current[index] != definition[index]) rpgExpandedReject('lifting-interrupted');
        local after = self.prepare();
        if (after.reason != 'lifting-capacity' || rpgLedger.seconds != start + self.failedAttemptSeconds)
            rpgExpandedReject('lifting-conditions-changed');
        self.startedAt = start; self.completedAt = rpgLedger.seconds; self.boundDefinition = self.definition();
        self.profile.liftingReceipts = self.profile.liftingReceipts + [self];
        value.seconds = self.failedAttemptSeconds; value.pickedUp = nil;
        value.status = 'resolved'; self.result = value; return value;
    }
;

modify RpgLiteItem
    sharedCarry = nil
;
modify RpgExpandedProfile
    sharedCarries = []
    loadHundredths()
    {
        local total = inherited();
        foreach (local carry in self.sharedCarries)
            if (carry.endedAt == nil) total += carry.shareFor(self);
        return total;
    }
    healthEffortReason(purpose,mentalAbility,speech,movement)
    {
        foreach (local carry in self.sharedCarries)
            if (carry.endedAt == nil && movement) return 'shared-carry-action-adapter-required';
        return inherited(purpose,mentalAbility,speech,movement);
    }
;

/** One owned object, distinct physical shares; members: [profile, weight, freeHands, hands]. */
class RpgExpandedSharedCarry: object
    id = nil
    owner = nil
    item = nil
    sourceLocation = nil
    members = []
    mode = 'two-hands'
    approved = nil
    evidence = nil
    startedAt = nil
    endedAt = nil
    boundDefinition = nil
    boundWeight = nil
    result = nil
    endDestination = nil
    endEvidence = nil
    endSeconds = nil
    definition()
    {
        local value = [self.id,self.owner,self.item,self.sourceLocation,self.mode,self.approved,self.evidence,self.members.length()];
        foreach (local row in self.members)
        {
            if (row.length() != 4) rpgExpandedReject('shared-carry-member');
            value = value + [row[1],row[2],row[3],row[4].length()] + row[4];
        }
        return value;
    }
    validateReceipt()
    {
        local current = self.definition();
        if (self.result == nil || current.length() != self.boundDefinition.length()) rpgExpandedReject('shared-carry-binding');
        for (local index = 1; index <= current.length(); index += 1)
            if (current[index] != self.boundDefinition[index]) rpgExpandedReject('shared-carry-binding');
        foreach (local row in self.members)
            if (!holds(row[1].sharedCarries,self)) rpgExpandedReject('shared-carry-history');
        if (self.endedAt == nil && (self.item.sharedCarry != self || self.item.storageLocation != self
            || !holds(self.owner.equipment,self.item) || self.item.weightHundredths() != self.boundWeight))
            rpgExpandedReject('shared-carry-item-changed');
        return nil;
    }
    shareFor(profile)
    {
        self.validateReceipt(); if (self.endedAt != nil) return 0;
        foreach (local row in self.members) if (row[1] == profile) return row[2];
        rpgExpandedReject('shared-carry-participant');
    }
    prepare()
    {
        if (self.id == nil || self.id == '' || self.owner == nil || !self.owner.ofKind(RpgExpandedProfile)
            || self.item == nil || !self.item.ofKind(RpgLiteItem) || self.sourceLocation == nil)
            rpgExpandedReject('shared-carry-definition');
        if (self.result != nil)
        { self.validateReceipt(); local value = new RpgExpandedResult(); value.status = 'reused'; return value; }
        self.definition(); local blocked = new RpgExpandedResult();
        if (self.item.thrownFlight != nil) { blocked.reason = 'equipment-in-flight'; return blocked; }
        if (self.item.sharedCarry != nil || self.item.storageLocation != self.sourceLocation)
        { blocked.reason = 'shared-carry-location'; return blocked; }
        local owners = 0;
        for (local profile = firstObj(RpgLiteProfile); profile != nil; profile = nextObj(profile,RpgLiteProfile))
            foreach (local entry in profile.equipment)
                if (entry == self.item)
                { if (profile != self.owner) rpgExpandedReject('shared-carry-owner'); owners += 1; }
        if (owners != 1) rpgExpandedReject('shared-carry-owner');
        rpgInteger(self.item.weight,1,1000000); rpgInteger(self.item.quantity,1,100);
        if (!holds(['one-hand','two-hands'],self.mode)) rpgExpandedReject('shared-carry-mode');
        local required = self.mode == 'one-hand' ? 1 : 2;
        foreach (local row in self.members)
        {
            if (row[1] == nil || !row[1].ofKind(RpgExpandedProfile)) rpgExpandedReject('shared-carry-member');
            rpgInteger(row[3],0,100);
            if (row[3] < required) { blocked.reason = 'shared-carry-free-hands'; return blocked; }
            blocked.reason = row[1].liftingHandsReason(row[4],required);
            if (blocked.reason == nil) blocked.reason = row[1].reservedLiftingHandsReason(row[4]);
            if (blocked.reason != nil) return blocked;
            foreach (local prior in row[1].sharedCarries)
                if (prior.id == self.id) rpgExpandedReject('shared-carry-duplicate');
        }
        return rpgExpandedSharedCarryRules.assess(self);
    }
    assess()
    {
        local value = self.prepare();
        if (value.status == 'ready')
        { rpgInteger(rpgLedger.seconds,0,2147483647-value.seconds); rpgLedger.validateAdvance(value.seconds); }
        return value;
    }
    lift()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        local definition = self.definition(); local weight = self.item.weightHundredths(); local start = rpgLedger.seconds;
        rpgSpendTime(value.seconds); local after = self.prepare(); local current = self.definition();
        if (after.status != 'ready' || after.seconds != value.seconds || current.length() != definition.length()
            || self.item.weightHundredths() != weight || rpgLedger.seconds != start + value.seconds)
            rpgExpandedReject('shared-carry-interrupted');
        for (local index = 1; index <= current.length(); index += 1)
            if (current[index] != definition[index]) rpgExpandedReject('shared-carry-interrupted');
        self.boundDefinition = definition; self.boundWeight = weight; self.startedAt = start;
        self.item.storageLocation = self; self.item.sharedCarry = self; self.item.ready = nil; self.item.worn = nil;
        foreach (local row in self.members) row[1].sharedCarries = row[1].sharedCarries + [self];
        value.status = 'resolved'; self.result = value; return value;
    }
    loweringReason()
    {
        foreach (local row in self.members)
        {
            local profile = row[1];
            if (profile.dead || profile.unconscious || profile.mortal || profile.stunned || profile.mentalStun
                || profile.hp() <= 0 || profile.fp() <= 0 || profile.voluntaryMovementUnavailable()
                || profile.healthEffortReason('action',nil,nil,nil) != nil)
                return 'shared-carry-lowering-worker';
            local reason = profile.liftingHandsReason(row[4],self.mode == 'one-hand' ? 1 : 2);
            if (reason != nil) return reason;
        }
        return nil;
    }
    lower(destination,seconds,evidence)
    {
        self.validateReceipt(); local value = new RpgExpandedResult();
        if (self.endedAt != nil)
        {
            if (destination != self.endDestination || seconds != self.endSeconds || evidence != self.endEvidence)
                rpgExpandedReject('shared-carry-lowering-binding');
            value.status = 'reused'; return value;
        }
        if (destination == nil || destination == self || evidence == nil || evidence == '')
        { value.reason = 'shared-carry-lowering-facts'; return value; }
        value.reason = self.loweringReason(); if (value.reason != nil) return value;
        rpgInteger(seconds,1,86400); rpgInteger(rpgLedger.seconds,0,2147483647-seconds);
        rpgLedger.validateAdvance(seconds); local start = rpgLedger.seconds; rpgSpendTime(seconds);
        self.validateReceipt(); if (rpgLedger.seconds != start+seconds || self.loweringReason() != nil
            || self.pendingSupportLoss())
            rpgExpandedReject('shared-carry-interrupted');
        self.endedAt = rpgLedger.seconds; self.endDestination = destination; self.endEvidence = evidence; self.endSeconds = seconds;
        self.item.storageLocation = destination; self.item.sharedCarry = nil;
        value.status = 'resolved'; return value;
    }
;

modify RpgExpandedSharedCarry
    emergencyRelease = nil
;
/** Explicit loss-of-support response. The author resolves whole-load and impact consequences. */
class RpgExpandedSharedCarryRelease: object
    carry = nil
    member = nil
    cause = nil
    destination = nil
    wholeLoadDrops = nil
    evidence = nil
    impactResolved = nil
    impactEvidence = nil
    completedAt = nil
    boundDefinition = nil
    definition()
    { return [self.carry,self.member,self.cause,self.destination,self.wholeLoadDrops,self.evidence,
        self.impactResolved,self.impactEvidence]; }
    assess()
    {
        if (self.carry == nil || !self.carry.ofKind(RpgExpandedSharedCarry)
            || self.member == nil || !self.member.ofKind(RpgExpandedProfile)
            || self.destination == nil || self.destination == self.carry)
            rpgExpandedReject('shared-release-definition');
        self.carry.validateReceipt(); local value = new RpgExpandedResult();
        if (self.completedAt != nil)
        {
            local current = self.definition();
            for (local index = 1; index <= current.length(); index += 1)
                if (current[index] != self.boundDefinition[index]) rpgExpandedReject('shared-release-binding');
            if (self.carry.emergencyRelease != self || self.carry.endedAt != self.completedAt
                || self.carry.endDestination != self.destination) rpgExpandedReject('shared-release-history');
            value.status = 'reused'; return value;
        }
        if (self.carry.endedAt != nil) { value.reason = 'shared-release-already-ended'; return value; }
        local found = nil;
        foreach (local row in self.carry.members) if (row[1] == self.member) found = row;
        if (found == nil) rpgExpandedReject('shared-release-member');
        if (!self.wholeLoadDrops || self.evidence == nil || self.evidence == '')
        { value.reason = 'shared-release-arrangement'; return value; }
        if (!self.impactResolved || self.impactEvidence == nil || self.impactEvidence == '')
        { value.reason = 'shared-release-impact-unresolved'; return value; }
        if (!holds(['unconscious','dead','disabled-support','knockdown'],self.cause))
            rpgExpandedReject('shared-release-cause');
        local applies = self.cause == 'unconscious' ? self.member.unconscious
            : self.cause == 'dead' ? self.member.dead
            : self.cause == 'knockdown' ? self.member.posture == 'lying' && self.member.stunned
            : self.member.liftingHandsReason(found[4],self.carry.mode == 'one-hand' ? 1 : 2) == 'lifting-hand-disabled';
        if (!applies && !self.carry.hasSupportLoss(self.member,self.cause))
        { value.reason = 'shared-release-cause-absent'; return value; }
        value.status = 'ready'; return value;
    }
    release()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        self.boundDefinition = self.definition(); self.completedAt = rpgLedger.seconds;
        self.carry.endedAt = self.completedAt; self.carry.endDestination = self.destination;
        self.carry.endEvidence = self.evidence; self.carry.endSeconds = 0; self.carry.emergencyRelease = self;
        self.carry.item.storageLocation = self.destination; self.carry.item.sharedCarry = nil;
        value.status = 'resolved'; return value;
    }
;


modify RpgExpandedSharedCarry
    supportLosses = []
    hasSupportLoss(profile,cause)
    {
        foreach (local row in self.supportLosses) if (row[1] == profile && row[2] == cause) return true;
        return nil;
    }
    noteSupportLoss(profile,cause)
    {
        if (self.result == nil || self.endedAt != nil || self.hasSupportLoss(profile,cause)) return nil;
        local member = nil;
        foreach (local row in self.members) if (row[1] == profile) member = true;
        if (!member) rpgExpandedReject('shared-support-loss-member');
        self.supportLosses = self.supportLosses + [[profile,cause,rpgLedger.seconds]]; return nil;
    }
    pendingSupportLoss()
    {
        if (self.result == nil || self.endedAt != nil) return nil;
        if (self.supportLosses.length() > 0) return true;
        foreach (local row in self.members)
        {
            local profile = row[1];
            if (profile.dead || profile.unconscious || profile.posture == 'lying' && profile.stunned
                || profile.liftingHandsReason(row[4],self.mode == 'one-hand' ? 1 : 2) == 'lifting-hand-disabled') return true;
        }
        return nil;
    }
;
modify RpgExpandedProfile
    onUnconscious()
    {
        inherited();
        foreach (local carry in self.sharedCarries) carry.noteSupportLoss(self,self.dead ? 'dead' : 'unconscious');
        return nil;
    }
    onKnockdown()
    {
        inherited();
        foreach (local carry in self.sharedCarries) carry.noteSupportLoss(self,'knockdown');
        return nil;
    }
    onBodySupportLost(part)
    {
        inherited(part);
        foreach (local carry in self.sharedCarries)
            if (carry.endedAt == nil)
                foreach (local row in carry.members)
                    if (row[1] == self)
                        foreach (local hand in row[4])
                            if (hand == part || hand.parent == part) carry.noteSupportLoss(self,'disabled-support');
        return nil;
    }
;
modify rpgLedger
    validateAdvance(seconds)
    {
        inherited(seconds);
        if (seconds > 0)
            for (local carry = firstObj(RpgExpandedSharedCarry); carry != nil; carry = nextObj(carry,RpgExpandedSharedCarry))
                if (carry.pendingSupportLoss()) rpgExpandedReject('shared-support-loss-unresolved');
        return nil;
    }
;


modify RpgExpandedProfile
    supportReserved(part)
    {
        foreach (local carry in self.sharedCarries)
            if (carry.endedAt == nil)
            {
                carry.validateReceipt();
                foreach (local row in carry.members)
                    if (row[1] == self)
                    {
                        if (part == nil || row[4].length() == 0) return true;
                        foreach (local hand in row[4])
                            if (hand == part || hand.parent == part || part.parent == hand.parent) return true;
                    }
            }
        return inherited(part);
    }
    reservedLiftingHandsReason(hands)
    {
        if (hands.length() == 0 && self.supportReserved(nil)) return 'lifting-shared-support-unmapped';
        foreach (local hand in hands) if (self.supportReserved(hand)) return 'lifting-shared-support-occupied';
        return inherited(hands);
    }
;

modify RpgExpandedProfile
    thrownReleases = []
;
/** Inventory stage of a throw. Storage becomes this owned in-flight record;
 * the object remains in exactly one owner's inventory until a later transfer. */
class RpgExpandedThrownRelease: RpgExpandedThrowFlightReceipt
    id = nil
    receipt = nil
    result = nil
    boundId = nil
    boundReceipt = nil
    settlement = nil
    assess()
    {
        if (self.id == nil || self.id == '' || self.receipt == nil || !self.receipt.ofKind(RpgExpandedThrowReceipt))
            rpgExpandedReject('thrown-release-definition');
        local value = self.receipt.releaseAssessment(); if (value.status != 'ready') return value;
        if (self.result != nil)
        {
            if (self.id != self.boundId || self.receipt != self.boundReceipt
                || !holds(value.profile.thrownReleases,self)) rpgExpandedReject('thrown-release-binding');
            if (self.settlement == nil && (value.item.thrownFlight != self || value.item.storageLocation != self))
                rpgExpandedReject('thrown-release-location-changed');
            value.status = 'reused'; return value;
        }
        foreach (local prior in value.profile.thrownReleases)
            if (prior.id == self.id || prior.receipt == self.receipt) rpgExpandedReject('thrown-release-duplicate');
        if (value.item.thrownFlight != nil || value.item.sharedCarry != nil || value.item.storageLocation != nil
            || !value.item.ready || value.item.worn || value.item.quantity != 1 || value.item.weightHundredths() != value.weight)
        { value.status = 'blocked'; value.reason = 'thrown-release-item-changed'; return value; }
        local owners = 0;
        for (local owner = firstObj(RpgLiteProfile); owner != nil; owner = nextObj(owner,RpgLiteProfile))
            foreach (local item in owner.equipment)
                if (item == value.item)
                {
                    if (owner != value.profile) rpgExpandedReject('thrown-release-owner');
                    owners += 1;
                }
        if (owners != 1) rpgExpandedReject('thrown-release-owner');
        return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status == 'reused') return self.result;
        if (value.status != 'ready') return value;
        value.item.storageLocation = self; value.item.thrownFlight = self;
        value.item.ready = nil; value.item.worn = nil;
        value.profile.onEquipmentUnavailable(value.item,'thrown');
        for (local fighter = firstObj(RpgLiteFighter); fighter != nil; fighter = nextObj(fighter,RpgLiteFighter))
            if (fighter.aimWeapon == value.item)
            { fighter.aimSeconds = 0; fighter.aimTarget = nil; fighter.aimWeapon = nil; }
        self.boundId = self.id; self.boundReceipt = self.receipt; self.result = value;
        value.profile.thrownReleases = value.profile.thrownReleases + [self]; value.status = 'resolved'; return value;
    }
;
/** Author-selected resting location after the throw's mechanical consequences
 * have been resolved. This stage does not adjudicate damage or a successful catch. */
class RpgExpandedThrowLanding: object
    release = nil
    destination = nil
    consequencesResolved = nil
    evidence = nil
    boundDefinition = nil
    result = nil
    definition() { return [self.release,self.destination,self.consequencesResolved,self.evidence]; }
    assess()
    {
        if (self.release == nil || !self.release.ofKind(RpgExpandedThrownRelease) || self.destination == nil
            || dataType(self.destination) != TypeObject || self.destination == self.release)
            rpgExpandedReject('throw-landing-definition');
        local value = self.release.assess();
        if (value.status != 'reused') { value.status = 'blocked'; value.reason = 'throw-landing-not-released'; return value; }
        value.status = 'blocked';
        if (self.result != nil)
        {
            local current = self.definition();
            for (local index = 1; index <= current.length(); index += 1)
                if (current[index] != self.boundDefinition[index]) rpgExpandedReject('throw-landing-binding');
            if (self.release.settlement != self) rpgExpandedReject('throw-landing-history');
            value.status = 'reused'; return value;
        }
        if (self.release.settlement != nil) rpgExpandedReject('throw-landing-already-settled');
        if (!self.consequencesResolved || self.evidence == nil || self.evidence == '')
        { value.reason = 'throw-landing-consequences-required'; return value; }
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status == 'reused') return self.result;
        if (value.status != 'ready') return value;
        value.item.storageLocation = self.destination; value.item.thrownFlight = nil;
        self.boundDefinition = self.definition(); self.release.settlement = self; self.result = value;
        value.status = 'resolved'; return value;
    }
;
modify rpgLedger
    validateAdvance(seconds)
    {
        inherited(seconds);
        if (seconds > 0)
            for (local profile = firstObj(RpgExpandedProfile); profile != nil; profile = nextObj(profile,RpgExpandedProfile))
                foreach (local release in profile.thrownReleases)
                    if (release.settlement == nil) rpgExpandedReject('throw-flight-settlement-required');
        return nil;
    }
;


modify RpgExpandedThrownRelease
    flightAssessment()
    {
        local value = self.assess();
        if (value.status != 'reused') { value.status = 'blocked'; value.reason = 'catch-flight-not-released'; return value; }
        if (self.settlement != nil) { value.status = 'blocked'; value.reason = 'catch-flight-settled'; return value; }
        value.throwReceipt = self.receipt; value.status = 'ready'; return value;
    }
;

/** Settle a successful catch without rolling or charging another action. */
class RpgExpandedCatchCapture: object
    receipt = nil
    result = nil
    boundReceipt = nil
    assess()
    {
        if (self.receipt == nil || !self.receipt.ofKind(RpgExpandedCatchReceipt))
            rpgExpandedReject('catch-capture-definition');
        local caught = self.receipt.captureAssessment(); if (caught.status != 'ready') return caught;
        if (caught.flight == nil || !caught.flight.ofKind(RpgExpandedThrownRelease))
            rpgExpandedReject('catch-capture-release');
        if (self.result != nil)
        {
            if (self.receipt != self.boundReceipt || caught.flight.settlement != self)
                rpgExpandedReject('catch-capture-binding');
            caught.status = 'reused'; return caught;
        }
        local value = caught.flight.flightAssessment(); if (value.status != 'ready') return value;
        if (value.recipient != caught.recipient) rpgExpandedReject('catch-capture-recipient');
        value.status = 'blocked';
        if (value.item.quantity != 1 || value.item.weightHundredths() != value.weight)
        { value.reason = 'catch-capture-item-changed'; return value; }
        if (caught.recipient.dead || caught.recipient.unconscious || caught.recipient.healthBlocksDefense())
        { value.reason = 'catch-capture-recipient-unavailable'; return value; }
        value.reason = caught.recipient.catchHandReason(caught.hand); if (value.reason != nil) return value;
        local owners = 0;
        for (local owner = firstObj(RpgLiteProfile); owner != nil; owner = nextObj(owner,RpgLiteProfile))
            foreach (local item in owner.equipment)
                if (item == value.item)
                {
                    if (owner != value.profile) rpgExpandedReject('catch-capture-owner');
                    owners += 1;
                }
        if (owners != 1) rpgExpandedReject('catch-capture-owner');
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status == 'reused') return self.result;
        if (value.status != 'ready') return value;
        local caught = self.receipt.captureAssessment(); local remaining = [];
        foreach (local item in value.profile.equipment) if (item != value.item) remaining = remaining + [item];
        value.profile.equipment = remaining;
        caught.recipient.equipment = caught.recipient.equipment + [value.item];
        value.item.storageLocation = nil; value.item.thrownFlight = nil;
        value.item.bodySupports = [caught.hand]; value.item.ready = true; value.item.worn = nil;
        caught.flight.settlement = self; self.boundReceipt = self.receipt; self.result = value;
        value.profile.onEquipmentUnavailable(value.item,'transferred');
        value.status = 'resolved'; return value;
    }
;

/** B195 and B345: author identifies the available fishing method and tools. */
class RpgExpandedFishingTools: RpgExpandedForageTools
    equipmentAssessment = nil
    approved = nil
    evidence = nil
    definition()
    {
        if (self.equipmentAssessment == nil || !self.equipmentAssessment.ofKind(RpgExpandedEquipmentAssessment))
            rpgExpandedReject('fishing-equipment-definition');
        local tools = self.equipmentAssessment;
        return [tools,self.approved,self.evidence,tools.quality,tools.allowWithoutEquipment,
            tools.techLevel,tools.missingItems,tools.damagePenalty];
    }
    assessFor(skill)
    {
        self.definition();
        if (!self.approved || self.evidence == nil || self.evidence == '')
        { local value = new RpgExpandedResult(); value.reason = 'fishing-equipment-facts'; return value; }
        return self.equipmentAssessment.assess(skill);
    }
    configure(context)
    { context.equipmentAssessment = self.equipmentAssessment; return context; }
;

modify RpgExpandedProfile
    forageHarvests = []
;
/** Claim the positive meal yield of one owned forage roll into a fresh inventory stack. */
class RpgExpandedForageHarvest: object
    id = nil
    profile = nil
    source = nil
    stock = nil
    approved = nil
    evidence = nil
    result = nil
    boundDefinition = nil
    definition()
    { return [self.id,self.profile,self.source,self.stock,self.stock.id,self.stock.weight,self.stock.cost,self.approved,self.evidence]; }
    assess()
    {
        if (self.id == nil || self.id == '' || self.profile == nil || !self.profile.ofKind(RpgExpandedProfile)
            || self.source == nil || !self.source.ofKind(RpgExpandedForageYieldReceipt)
            || self.stock == nil || !self.stock.ofKind(RpgExpandedFoodStock)) rpgExpandedReject('forage-harvest-definition');
        local definition = self.definition(); local value = new RpgExpandedResult();
        local harvestYield = self.source.availableYield();
        if (harvestYield.status != 'ready') { value.reason = harvestYield.reason; return value; }
        if (self.result != nil)
        {
            for (local index = 1; index <= definition.length(); index += 1)
                if (definition[index] != self.boundDefinition[index]) rpgExpandedReject('forage-harvest-binding');
            if (self.source.creditedHarvest != self || self.stock.gatheredFrom != self.source
                || !holds(self.profile.forageHarvests,self)) rpgExpandedReject('forage-harvest-history');
            value.status = 'reused'; return value;
        }
        if (self.source.creditedHarvest != nil) rpgExpandedReject('forage-harvest-duplicate-source');
        foreach (local prior in self.profile.forageHarvests)
            if (prior.id == self.id) rpgExpandedReject('forage-harvest-duplicate');
        if (!self.approved || self.evidence == nil || self.evidence == '')
        { value.reason = 'forage-harvest-transfer-facts'; return value; }
        if (harvestYield.meals < 1) { value.reason = 'forage-harvest-no-food'; return value; }
        rpgInteger(harvestYield.meals,1,2);
        if (self.stock.id == nil || self.stock.id == '' || self.stock.quantity != 0 || self.stock.gatheredFrom != nil)
            rpgExpandedReject('forage-harvest-fresh-stock-required');
        rpgInteger(self.stock.weight,0,2147483647 / harvestYield.meals); rpgInteger(self.stock.cost,0,2147483647);
        for (local owner = firstObj(RpgLiteProfile); owner != nil; owner = nextObj(owner,RpgLiteProfile))
            if (holds(owner.equipment,self.stock)) rpgExpandedReject('forage-harvest-stock-owned');
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status == 'reused') return self.result;
        if (value.status != 'ready') return value;
        self.boundDefinition = self.definition(); self.stock.quantity = self.source.availableYield().meals;
        self.stock.gatheredFrom = self.source; self.stock.foodKind = self.source.foodKind(); self.profile.equipment = self.profile.equipment + [self.stock];
        self.source.creditedHarvest = self; self.profile.forageHarvests = self.profile.forageHarvests + [self];
        self.result = value; value.status = 'resolved'; return value;
    }
;

/** Concrete authored fire interval. Extinguishing records when coverage ended. */
class RpgExpandedSmokingFire: object
    id = nil
    litAt = 0
    fuelUntil = 0
    evidence = nil
    extinguishedAt = nil
    definition() { return [self.id,self.litAt,self.fuelUntil,self.evidence]; }
    covers(start, finish)
    {
        if (self.id == nil || self.id == '' || self.evidence == nil || self.evidence == '')
            rpgExpandedReject('smoking-fire-facts');
        rpgInteger(self.litAt,0,2147483647); rpgInteger(self.fuelUntil,self.litAt,2147483647);
        return start >= self.litAt && finish <= self.fuelUntil
            && (self.extinguishedAt == nil || self.extinguishedAt >= finish);
    }
    extinguish()
    { if (self.extinguishedAt == nil) self.extinguishedAt = rpgLedger.seconds; return nil; }
;
modify RpgExpandedProfile
    smokingBatches = []
;
/** B427 whole-stack smoking; author supplies duration and preparation conditions. */
class RpgExpandedSmokingBatch: object
    id = nil
    profile = nil
    stock = nil
    fire = nil
    seconds = nil
    approved = nil
    evidence = nil
    startedAt = nil
    dueAt = nil
    endedAt = nil
    cancelled = nil
    boundDefinition = nil
    boundQuantity = nil
    definition()
    { return [self.id,self.profile,self.stock,self.stock.foodKind,self.fire,self.seconds,self.approved,self.evidence] + self.fire.definition(); }
    validateBinding()
    {
        local current = self.definition();
        for (local index = 1; index <= current.length(); index += 1)
            if (current[index] != self.boundDefinition[index]) rpgExpandedReject('smoking-batch-binding');
        if (!holds(self.profile.smokingBatches,self)) rpgExpandedReject('smoking-batch-history');
        return nil;
    }
    supplyReason()
    {
        if (!holds(self.profile.equipment,self.stock) || self.stock.quantity < 1) return 'smoking-food-unavailable';
        local owners = 0;
        for (local owner = firstObj(RpgLiteProfile); owner != nil; owner = nextObj(owner,RpgLiteProfile))
            if (holds(owner.equipment,self.stock)) owners += 1;
        if (owners != 1) rpgExpandedReject('smoking-food-ownership');
        return nil;
    }
    assess()
    {
        if (self.id == nil || self.id == '' || self.profile == nil || !self.profile.ofKind(RpgExpandedProfile)
            || self.stock == nil || !self.stock.ofKind(RpgExpandedFoodStock)
            || self.fire == nil || !self.fire.ofKind(RpgExpandedSmokingFire)) rpgExpandedReject('smoking-batch-definition');
        local value = new RpgExpandedResult();
        if (self.startedAt != nil)
        { self.validateBinding(); value.status = 'reused'; return value; }
        if (!self.approved || self.evidence == nil || self.evidence == '')
        { value.reason = 'smoking-preparation-facts'; return value; }
        if (!holds(['fish','meat'],self.stock.foodKind)) { value.reason = 'smoking-food-kind'; return value; }
        rpgInteger(self.seconds,1,86400); rpgInteger(rpgLedger.seconds,0,2147483647-self.seconds);
        rpgInteger(self.stock.quantity,1,1000000);
        if (self.stock.preserved || self.stock.smokingBatch != nil) { value.reason = 'smoking-food-already-processed'; return value; }
        value.reason = self.supplyReason(); if (value.reason != nil) return value;
        if (!self.fire.covers(rpgLedger.seconds,rpgLedger.seconds+self.seconds)) { value.reason = 'smoking-fire-coverage'; return value; }
        foreach (local prior in self.profile.smokingBatches)
            if (prior.id == self.id) rpgExpandedReject('smoking-batch-duplicate');
        value.status = 'ready'; return value;
    }
    start()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        self.boundDefinition = self.definition(); self.boundQuantity = self.stock.quantity;
        self.startedAt = rpgLedger.seconds; self.dueAt = self.startedAt+self.seconds;
        self.stock.smokingBatch = self; self.profile.smokingBatches = self.profile.smokingBatches + [self];
        value.status = 'resolved'; return value;
    }
    assessCompletion()
    {
        self.assess(); local value = new RpgExpandedResult();
        if (self.startedAt == nil) { value.reason = 'smoking-not-started'; return value; }
        if (self.endedAt != nil) { value.status = 'reused'; return value; }
        if (self.stock.smokingBatch != self || self.stock.quantity != self.boundQuantity) rpgExpandedReject('smoking-food-changed');
        value.reason = self.supplyReason(); if (value.reason != nil) return value;
        if (!self.fire.covers(self.startedAt,self.dueAt)) { value.reason = 'smoking-fire-interrupted'; return value; }
        if (rpgLedger.seconds < self.dueAt) { value.reason = 'smoking-not-ready'; return value; }
        value.status = 'ready'; return value;
    }
    complete()
    {
        local value = self.assessCompletion(); if (value.status != 'ready') return value;
        self.stock.preserved = true; self.stock.readyToEat = true; self.stock.preparationEvidence = self.evidence;
        self.stock.smokingBatch = nil; self.endedAt = rpgLedger.seconds; value.status = 'resolved'; return value;
    }
    cancel()
    {
        local value = self.assess(); if (self.startedAt == nil) { value.status = 'blocked'; value.reason = 'smoking-not-started'; return value; }
        if (self.endedAt != nil) return value;
        if (self.stock.smokingBatch != self) rpgExpandedReject('smoking-food-changed');
        self.stock.smokingBatch = nil; self.endedAt = rpgLedger.seconds; self.cancelled = true;
        value.status = 'resolved'; return value;
    }
;

/** B223-B224 ordinary wilderness conditions, including weather and task equipment. */
class RpgExpandedWildernessTools: RpgExpandedFishingTools
    planet = nil
    terrain = nil
    weatherPenalty = 0
    definition() { return inherited() + [self.planet,self.terrain,self.weatherPenalty]; }
    assessFor(skill)
    {
        local value = inherited(skill); if (value.status != 'ready') return value;
        rpgInteger(self.weatherPenalty,-5,0);
        if (skill.id != 'survival' || !skill.expandedForageDefaultsReady())
            rpgExpandedReject('wilderness-expanded-survival-required');
        local facts = skill.foragingDefinition();
        if (facts.length() < 1 || self.planet != facts[1] || self.terrain != skill.specialty)
        { value.status = 'blocked'; value.reason = 'wilderness-specialty-mismatch'; }
        return value;
    }
    configure(context)
    { inherited(context); context.modifier += self.weatherPenalty; return context; }
;


modify RpgExpandedProfile
    moneyUnit = 'campaign-unit'
;
/** B264 authored local offer, preserving catalogue baseline independently. */
class RpgExpandedMarketOffer: object
    id = nil
    item = nil
    market = nil
    currency = 'campaign-unit'
    baselinePrice = nil
    price = nil
    approved = nil
    evidence = nil
    definition()
    {
        return [self.id,self.item,self.market,self.currency,self.baselinePrice,self.price,self.approved,self.evidence];
    }
    assess(profile,item)
    {
        if (self.id == nil || self.id == '' || self.item != item || self.market == nil || self.currency == nil || self.currency == '')
            rpgExpandedReject('market-offer-definition');
        rpgInteger(self.baselinePrice,0,2147483647); rpgInteger(self.price,0,2147483647);
        if (self.baselinePrice != item.cost) rpgExpandedReject('market-offer-baseline');
        if (self.currency != profile.moneyUnit) return 'market-offer-currency';
        if (!self.approved || self.evidence == nil || self.evidence == '') return 'market-offer-evidence-required';
        return nil;
    }
;

/** B264 optional coin convention. Gold's approximate ratio requires campaign adoption. */
class RpgExpandedCoinage: object
    currency = 'campaign-unit'
    goldRatio = 20
    copperWeightThousandths = nil
    copperWeightEvidence = nil
    approved = nil
    evidence = nil
    definition() { return [self.currency,self.goldRatio,self.copperWeightThousandths,self.copperWeightEvidence,self.approved,self.evidence]; }
    validate()
    {
        if (self.currency == nil || self.currency == '' || !self.approved || self.evidence == nil || self.evidence == '')
            rpgExpandedReject('coinage-campaign-convention');
        rpgInteger(self.goldRatio,1,1000); return nil;
    }
    denomination(metal)
    {
        self.validate();
        if (metal == 'copper') return 1;
        if (metal == 'silver') return 4;
        if (metal == 'gold') return 4 * self.goldRatio;
        rpgExpandedReject('coinage-metal-weight-unsupported');
    }
    weightThousandths(metal)
    {
        self.validate();
        if (holds(['silver','gold'],metal)) return 4;
        if (metal != 'copper') rpgExpandedReject('coinage-metal-weight-unsupported');
        if (self.copperWeightThousandths == nil || self.copperWeightEvidence == nil || self.copperWeightEvidence == '')
            rpgExpandedReject('coinage-copper-weight-required');
        rpgInteger(self.copperWeightThousandths,1,1000000); return self.copperWeightThousandths;
    }
;
/** Quantity counts coins; cash value is not simultaneously held in profile.money. */
class RpgExpandedCoinStock: RpgLiteItem
    coinage = nil
    metal = 'silver'
    quantity = 0
    definition()
    {
        if (self.id == nil || self.id == '' || self.coinage == nil || !self.coinage.ofKind(RpgExpandedCoinage))
            rpgExpandedReject('coin-stock-convention');
        return [self.id,self.coinage,self.metal] + self.coinage.definition();
    }
    validateQuantity(quantity)
    {
        self.definition(); local unit = self.coinage.denomination(self.metal);
        local mass = self.coinage.weightThousandths(self.metal);
        rpgInteger(quantity,0,1000000); rpgInteger(quantity,0,2147483647 / unit);
        rpgInteger(quantity,0,2147483638 / mass); return nil;
    }
    faceValue()
    {
        self.validateQuantity(self.quantity); return self.quantity * self.coinage.denomination(self.metal);
    }
    weightHundredths()
    {
        self.faceValue();
        /* Ceiling stack mass to the engine's 0.01 lb unit. */
        return (self.quantity * self.coinage.weightThousandths(self.metal) + 9) / 10;
    }
    validateAcquisition() { rpgExpandedReject('coin-stock-exchange-required'); }
;
modify RpgExpandedProfile
    coinExchanges = []
;
/** Author-confirmed conversion between existing abstract funds and physical coin. */
class RpgExpandedCoinExchange: object
    id = nil
    profile = nil
    stock = nil
    direction = 'withdraw'
    quantity = nil
    approved = nil
    evidence = nil
    recorded = nil
    boundDefinition = nil
    boundMoney = nil
    definition()
    {
        return [self.id,self.profile,self.stock,self.direction,self.quantity,self.approved,self.evidence] + self.stock.definition();
    }
    assess()
    {
        local value = new RpgExpandedAcquisitionResult();
        if (self.id == nil || self.id == '' || self.profile == nil || !self.profile.ofKind(RpgExpandedProfile)
            || self.stock == nil || !self.stock.ofKind(RpgExpandedCoinStock)) rpgExpandedReject('coin-exchange-definition');
        if (self.recorded)
        {
            if (!holds(self.profile.coinExchanges,self)) rpgExpandedReject('coin-exchange-history');
            local facts = self.definition();
            if (self.boundDefinition == nil || facts.length() != self.boundDefinition.length()) rpgExpandedReject('coin-exchange-binding');
            for (local index = 1; index <= facts.length(); index += 1)
                if (facts[index] != self.boundDefinition[index]) rpgExpandedReject('coin-exchange-binding');
            value.status = 'reused'; return value;
        }
        if (self.boundDefinition != nil || self.boundMoney != nil) rpgExpandedReject('coin-exchange-uncommitted');
        if (!holds(['withdraw','deposit'],self.direction)) rpgExpandedReject('coin-exchange-direction');
        rpgExpandedValidate(self.profile); self.stock.faceValue();
        local denomination = self.stock.coinage.denomination(self.stock.metal);
        rpgInteger(self.quantity,1,1000000); rpgInteger(self.quantity,1,2147483647 / denomination);
        value.money = self.quantity * denomination; value.item = self.stock;
        rpgInteger(self.profile.money,0,2147483647);
        if (self.stock.coinage.currency != self.profile.moneyUnit) { value.reason = 'coin-exchange-currency'; return value; }
        local owner = nil;
        for (local candidate = firstObj(RpgLiteProfile); candidate != nil; candidate = nextObj(candidate,RpgLiteProfile))
            foreach (local item in candidate.equipment)
                if (item == self.stock)
                { if (owner != nil) rpgExpandedReject('coin-stock-shared'); owner = candidate; }
        if (self.direction == 'withdraw')
        {
            if (owner != nil || self.stock.quantity != 0) rpgExpandedReject('coin-withdraw-fresh-stock');
            self.stock.validateQuantity(self.quantity);
            if (self.profile.money < value.money) { value.reason = 'coin-exchange-insufficient-funds'; return value; }
        }
        else
        {
            if (owner != self.profile || self.stock.quantity < self.quantity) rpgExpandedReject('coin-deposit-ownership');
            if (self.profile.money > 2147483647 - value.money) rpgExpandedReject('coin-deposit-money-limit');
        }
        if (!self.stock.usableBy(self.profile) || self.stock.thrownFlight != nil || self.stock.sharedCarry != nil)
        { value.reason = 'coin-stock-inaccessible'; return value; }
        if (!self.approved || self.evidence == nil || self.evidence == '')
        { value.reason = 'coin-exchange-world-facts-required'; return value; }
        foreach (local prior in self.profile.coinExchanges) if (prior.id == self.id) rpgExpandedReject('coin-exchange-duplicate-id');
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        self.boundDefinition = self.definition(); self.boundMoney = value.money;
        if (self.direction == 'withdraw')
        {
            self.profile.money -= value.money; self.stock.quantity = self.quantity;
            self.profile.equipment = self.profile.equipment + [self.stock];
        }
        else
        {
            self.profile.money += value.money; self.stock.quantity -= self.quantity;
            if (self.stock.quantity == 0)
            {
                local kept = []; foreach (local item in self.profile.equipment) if (item != self.stock) kept = kept + [item];
                self.profile.equipment = kept;
            }
        }
        self.recorded = true; self.profile.coinExchanges = self.profile.coinExchanges + [self];
        value.status = 'resolved'; return value;
    }
;


/** Exact coin/cash tender for one acquisition; no implicit bank conversion or change. */
class RpgExpandedCoinTender: object
    acquisition = nil
    /* [owned coin stack, number of coins tendered] */
    coins = []
    cash = 0
    approved = nil
    evidence = nil
    recorded = nil
    boundDefinition = nil
    boundPrice = nil
    definition()
    {
        local facts = [self.acquisition,self.acquisition.profile,self.acquisition.item,self.cash,self.approved,self.evidence,self.coins.length()];
        foreach (local row in self.coins) facts = facts + row + row[1].definition();
        return facts;
    }
    validateReceipt(acquisition)
    {
        if (!self.recorded || self.acquisition != acquisition || acquisition.coinTender != self)
            rpgExpandedReject('coin-tender-receipt');
        local facts = self.definition();
        if (self.boundDefinition == nil || facts.length() != self.boundDefinition.length()) rpgExpandedReject('coin-tender-binding');
        for (local index = 1; index <= facts.length(); index += 1)
            if (facts[index] != self.boundDefinition[index]) rpgExpandedReject('coin-tender-binding');
        return nil;
    }
    assess(acquisition,price)
    {
        if (self.recorded || self.boundDefinition != nil || self.boundPrice != nil) rpgExpandedReject('coin-tender-already-used');
        if (self.acquisition != acquisition || acquisition.coinTender != self) rpgExpandedReject('coin-tender-acquisition');
        local profile = acquisition.profile; rpgInteger(self.cash,0,price);
        local total = self.cash; local seen = [];
        foreach (local row in self.coins)
        {
            if (row.length() != 2 || row[1] == nil || !row[1].ofKind(RpgExpandedCoinStock) || holds(seen,row[1]))
                rpgExpandedReject('coin-tender-stack');
            local stock = row[1]; stock.faceValue(); rpgInteger(row[2],1,stock.quantity);
            if (!holds(profile.equipment,stock)) rpgExpandedReject('coin-tender-ownership');
            local owners = 0;
            for (local owner = firstObj(RpgLiteProfile); owner != nil; owner = nextObj(owner,RpgLiteProfile))
                foreach (local item in owner.equipment) if (item == stock) owners += 1;
            if (owners != 1) rpgExpandedReject('coin-tender-shared');
            if (stock.coinage.currency != profile.moneyUnit) return 'coin-tender-currency';
            if (!stock.usableBy(profile) || stock.thrownFlight != nil || stock.sharedCarry != nil) return 'coin-tender-inaccessible';
            local unit = stock.coinage.denomination(stock.metal);
            rpgInteger(row[2],1,(2147483647 - total) / unit); total += row[2] * unit;
            seen = seen + [stock];
        }
        if (total != price) return 'coin-tender-exact-price-required';
        if (profile.money < self.cash) return 'equipment-unaffordable';
        if (!self.approved || self.evidence == nil || self.evidence == '') return 'coin-tender-acceptance-required';
        return nil;
    }
    /** Internal commit after the acquisition has assessed item, permission and price. */
    commitPayment(acquisition,price)
    {
        local reason = self.assess(acquisition,price); if (reason != nil) rpgExpandedReject(reason);
        self.boundDefinition = self.definition(); self.boundPrice = price;
        local profile = acquisition.profile; profile.money -= self.cash;
        foreach (local row in self.coins)
        {
            local stock = row[1]; stock.quantity -= row[2];
            if (stock.quantity == 0)
            {
                local kept = []; foreach (local item in profile.equipment) if (item != stock) kept = kept + [item];
                profile.equipment = kept;
            }
        }
        self.recorded = true; return nil;
    }
;


/** B345 adequacy bound to one owner's actual available task equipment. */
class RpgExpandedOwnedEquipmentAssessment: RpgExpandedEquipmentAssessment
    profile = nil
    skill = nil
    items = []
    approved = nil
    evidence = nil
    assessFor(profile,skill)
    {
        if (profile != self.profile) rpgExpandedReject('owned-equipment-context-owner');
        return self.assess(skill);
    }
    assess(skill)
    {
        if (self.profile == nil || !self.profile.ofKind(RpgExpandedProfile) || self.skill != skill)
            rpgExpandedReject('owned-equipment-task');
        local value = inherited(skill); if (value.status != 'ready') return value;
        if (!self.approved || self.evidence == nil || self.evidence == '')
        { value.status = 'blocked'; value.reason = 'owned-equipment-adequacy-required'; return value; }
        if (self.quality == 'none' ? self.items.length() != 0 : self.items.length() == 0)
            rpgExpandedReject('owned-equipment-item-set');
        local seen = [];
        foreach (local item in self.items)
        {
            if (item == nil || !item.ofKind(RpgLiteItem) || holds(seen,item)) rpgExpandedReject('owned-equipment-item');
            if (!holds(self.profile.equipment,item))
            { value.status = 'blocked'; value.reason = 'owned-equipment-not-owned'; return value; }
            local owners = 0;
            for (local owner = firstObj(RpgLiteProfile); owner != nil; owner = nextObj(owner,RpgLiteProfile))
                foreach (local owned in owner.equipment) if (owned == item) owners += 1;
            if (owners != 1) rpgExpandedReject('owned-equipment-shared-item');
            rpgInteger(item.quantity,1,1000000);
            if (!item.usableBy(self.profile) || item.thrownFlight != nil || item.sharedCarry != nil)
            { value.status = 'blocked'; value.reason = 'owned-equipment-inaccessible'; return value; }
            seen = seen + [item];
        }
        return value;
    }
;
