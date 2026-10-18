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
        self.item.validateAcquisition();
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
