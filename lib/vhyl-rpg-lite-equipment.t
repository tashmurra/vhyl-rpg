/** Owned equipment with integer price and weight in hundredths of a pound. */
class RpgLiteItem: object
    id = nil
    cost = 0
    weight = 0
    quantity = 1
    dr = 0
    db = 0
    worn = nil
    ready = nil
    weightHundredths() { return self.weight * self.quantity; }
    usableBy(profile) { return true; }
    validateAcquisition() { return nil; }
    diggingUseReason(role, material) { return nil; }
    /* Separate operation hooks allow optional anatomy without changing carried state. */
    attackUsableBy(profile) { return self.usableBy(profile); }
    attackHandCount(profile, requested) { return requested; }
    parryUsableBy(profile) { return self.usableBy(profile); }
    blockUsableBy(profile) { return self.usableBy(profile); }
    passiveDefenseBonus(profile) { return self.usableBy(profile) ? self.db : 0; }
;

/** Mutable weapon instance with attack modes, ammunition, reserves and reload progress. */
class RpgLiteWeapon: RpgLiteItem
    validateStrike(attacker, mode) { return nil; }
    afterStrike(attacker, mode, result) { return nil; }
    techLevel = 0
    modes = []
    ammunition = 0
    reserves = 0
    reloadProgress = 0
    weaponST = 10
    goatFoot = nil
    scopeBonus = 0
    bipod = nil
;

/** One melee or ranged use of a weapon, including ST, damage, range and reload statistics. */
class RpgLiteAttackMode: object
    skillId = nil
    specialty = nil
    base = 'thrust'
    dice = 0
    adds = 0
    damageType = 'cr'
    minimumST = 0
    hands = 1
    requiresTwoHands = nil
    unready = nil
    ranged = nil
    thrown = nil
    acc = 0
    halfRange = 0
    maximumRange = 0
    rangeScale = 1
    rof = 1
    pellets = 1
    capacity = 0
    reloadSeconds = 0
    individualReload = nil
    armorDivisor = 1
;

/** Return [dice, adds] for ST 1–20 and thrust or swing. */
rpgLiteDamageDice(strength, swing)
{
    rpgInteger(strength, 1, 20);
    local thrust = [[1,-6],[1,-6],[1,-5],[1,-5],[1,-4],[1,-4],[1,-3],[1,-3],[1,-2],[1,-2],
        [1,-1],[1,-1],[1,0],[1,0],[1,1],[1,1],[1,2],[1,2],[2,-1],[2,-1]];
    local swings = [[1,-5],[1,-5],[1,-4],[1,-4],[1,-3],[1,-3],[1,-2],[1,-2],[1,-1],[1,0],
        [1,1],[1,2],[2,-1],[2,0],[2,1],[2,2],[3,-1],[3,0],[3,1],[3,2]];
    return swing ? swings[strength] : thrust[strength];
}

/** Roll basic damage with the crushing/non-crushing minimum, or take maximum damage. */
rpgLiteRollDamage(dice, adds, damageType, maximum)
{
    rpgInteger(dice, 1, 100); rpgInteger(adds, -1000, 1000);
    local damage = adds;
    for (local index = 0; index < dice; index += 1) damage += maximum ? 6 : rpgRandom.die();
    local minimum = damageType == 'cr' ? 0 : 1;
    return damage < minimum ? minimum : damage;
}

/** Apply half range, armor divisor, DR and wound multiplier in that order. */
rpgLitePenetration(damage, dr, divisor, damageType, halfRange)
{
    rpgInteger(damage, 0, 100000); rpgInteger(dr, 0, 10000); rpgInteger(divisor, 1, 100);
    if (!holds(['cr','cut','imp','burn','pi-','pi','pi+','tox','fat'], damageType)) throw new RpgError();
    if (halfRange) damage /= 2;
    local penetration = damage - dr / divisor;
    if (penetration <= 0) return 0;
    local amount = penetration;
    if (damageType == 'pi-') amount /= 2;
    if (damageType == 'cut' || damageType == 'pi+') amount = amount * 3 / 2;
    if (damageType == 'imp') amount *= 2;
    return amount < 1 ? 1 : amount;
}

/** Create an independent armor or shield item by catalogue ID. */
rpgLiteMakeArmor(id)
{
    foreach (local row in rpgLiteCatalogue.armor)
        if (row[1] == id)
        {
            local item = new RpgLiteItem(); item.id = id; item.dr = row[2];
            item.cost = row[3]; item.weight = row[4]; return item;
        }
    foreach (local row in rpgLiteCatalogue.shields)
        if (row[1] == id)
        {
            local item = new RpgLiteItem(); item.id = id; item.db = row[2];
            item.cost = row[3]; item.weight = row[4]; return item;
        }
    throw new RpgError();
}

/** Numeric weapon and attack-mode tables; no mutable ammunition is stored in these rows. */
rpgLiteArmory: object
    weapons = [
        ['axe',0,50,400], ['mace',2,50,500], ['punch',0,0,0], ['kick',0,0,0],
        ['brass-knuckles',1,10,25], ['blackjack',1,20,100], ['broadsword',2,500,300], ['thrusting-broadsword',2,600,300],
        ['large-knife',0,40,100], ['poleaxe',3,120,1000], ['rapier',4,500,275],
        ['shortsword',2,400,200], ['spear',0,40,400], ['quarterstaff',0,10,400],
        ['thrusting-greatsword',3,900,700], ['longbow',0,200,300], ['short-bow',0,50,200],
        ['crossbow',2,150,600], ['throwing-axe',0,60,400], ['derringer',5,100,50],
        ['auto-pistol-9mm',6,350,240], ['revolver-357',7,500,300], ['auto-pistol-44m',8,750,450],
        ['lever-carbine',5,300,700], ['self-loading-rifle',6,600,1000],
        ['sniper-rifle',8,5600,1750], ['pump-shotgun',6,240,800]
    ]
    melee = [
        ['axe','axe-mace','swing',2,'cut',11,1,nil], ['mace','axe-mace','swing',3,'cr',12,1,nil],
        ['punch','brawling','thrust',-1,'cr',0,1,nil], ['kick','brawling','thrust',0,'cr',0,1,nil],
        ['brass-knuckles','brawling','thrust',0,'cr',0,1,nil],
        ['blackjack','brawling','thrust',0,'cr',7,1,nil],
        ['broadsword','broadsword','swing',1,'cut',10,1,nil], ['broadsword','broadsword','thrust',1,'cr',10,1,nil],
        ['thrusting-broadsword','broadsword','swing',1,'cut',10,1,nil], ['thrusting-broadsword','broadsword','thrust',2,'imp',10,1,nil],
        ['large-knife','knife','swing',-2,'cut',6,1,nil], ['large-knife','knife','thrust',0,'imp',6,1,nil],
        ['poleaxe','polearm','swing',4,'cut',12,2,true], ['poleaxe','polearm','swing',4,'cr',12,2,true],
        ['rapier','rapier','thrust',1,'imp',9,1,nil],
        ['shortsword','shortsword','swing',0,'cut',8,1,nil], ['shortsword','shortsword','thrust',0,'imp',8,1,nil],
        ['spear','spear','thrust',2,'imp',9,1,nil], ['spear','spear','thrust',3,'imp',9,2,nil],
        ['quarterstaff','staff','swing',2,'cr',7,2,nil], ['quarterstaff','staff','thrust',2,'cr',7,2,nil],
        ['quarterstaff','two-handed-sword','swing',2,'cr',9,2,nil], ['quarterstaff','two-handed-sword','thrust',1,'cr',9,2,nil],
        ['thrusting-greatsword','two-handed-sword','swing',3,'cut',12,2,nil], ['thrusting-greatsword','two-handed-sword','thrust',3,'imp',12,2,nil]
    ]
    ranged = [
        ['longbow','bow',nil,'thrust',0,2,'imp',3,150,200,10,11,1,1,2,nil,nil],
        ['short-bow','bow',nil,'thrust',0,0,'imp',1,100,150,10,7,1,1,2,nil,nil],
        ['crossbow','crossbow',nil,'thrust',0,4,'imp',4,200,250,10,7,1,1,4,nil,nil],
        ['throwing-axe','thrown-weapon','axe-mace','swing',0,2,'cut',2,10,15,10,11,1,1,1,nil,true],
        ['large-knife','thrown-weapon','knife','thrust',0,0,'imp',0,8,15,10,6,1,1,1,nil,true],
        ['spear','thrown-weapon','spear','thrust',0,3,'imp',2,10,15,10,9,1,1,1,nil,true],
        ['derringer','guns','pistol','fixed',1,0,'pi+',1,80,650,1,9,1,2,3,true,nil],
        ['auto-pistol-9mm','guns','pistol','fixed',2,2,'pi',2,150,1850,1,9,3,9,3,nil,nil],
        ['revolver-357','guns','pistol','fixed',3,-1,'pi',2,185,2000,1,10,3,6,3,true,nil],
        ['auto-pistol-44m','guns','pistol','fixed',3,0,'pi+',2,230,2500,1,12,3,10,3,nil,nil],
        ['lever-carbine','guns','rifle','fixed',5,0,'pi',4,450,3000,1,10,1,7,3,true,nil],
        ['self-loading-rifle','guns','rifle','fixed',7,0,'pi',5,1000,4200,1,10,3,8,3,nil,nil],
        ['sniper-rifle','guns','rifle','fixed',9,1,'pi',6,1500,5500,1,11,1,5,3,nil,nil],
        ['pump-shotgun','guns','shotgun','fixed',1,1,'pi-',3,50,125,1,10,2,5,3,true,nil]
    ]
;

/** Create an unloaded weapon with independent modes and selected muscle-powered weapon ST. */
rpgLiteMakeWeapon(id, weaponST)
{
    local weapon = nil;
    foreach (local row in rpgLiteArmory.weapons)
        if (row[1] == id)
        {
            weapon = new RpgLiteWeapon(); weapon.id = id; weapon.techLevel = row[2];
            weapon.cost = row[3]; weapon.weight = row[4];
        }
    if (weapon == nil) throw new RpgError();
    rpgInteger(weaponST, 1, 20); weapon.weaponST = weaponST;
    foreach (local row in rpgLiteArmory.melee)
        if (row[1] == id)
        {
            local mode = new RpgLiteAttackMode(); mode.skillId = row[2]; mode.base = row[3];
            mode.adds = row[4]; mode.damageType = row[5]; mode.minimumST = row[6]; mode.hands = row[7];
            mode.unready = row[8]; weapon.modes = weapon.modes + [mode];
        }
    foreach (local row in rpgLiteArmory.ranged)
        if (row[1] == id)
        {
            local mode = new RpgLiteAttackMode(); mode.skillId = row[2]; mode.specialty = row[3];
            mode.base = row[4]; mode.dice = row[5]; mode.adds = row[6]; mode.damageType = row[7];
            mode.acc = row[8]; mode.halfRange = row[9]; mode.maximumRange = row[10]; mode.rangeScale = row[11];
            mode.minimumST = row[12]; mode.rof = row[13]; mode.capacity = row[14];
            mode.reloadSeconds = row[15]; mode.individualReload = row[16]; mode.thrown = row[17]; mode.ranged = true;
            if (!mode.thrown && mode.specialty != 'pistol') mode.hands = 2;
            mode.requiresTwoHands = holds(['longbow','short-bow','pump-shotgun'], id);
            if (id == 'pump-shotgun') mode.pellets = 9;
            weapon.modes = weapon.modes + [mode];
        }
    if (id == 'sniper-rifle') { weapon.scopeBonus = 3; weapon.bipod = true; }
    return weapon;
}

/** Query reload eligibility and duration without changing the weapon. */
rpgLiteReloadSeconds(profile, weapon, mode)
{
    if (!holds(profile.equipment, weapon) || !weapon.usableBy(profile) || !mode.ranged || mode.thrown || weapon.reserves < 1) return nil;
    local seconds = mode.reloadSeconds;
    if (weapon.id == 'crossbow')
    {
        local difference = weapon.weaponST - profile.handlingStrength();
        if (difference >= 5 || difference >= 3 && (!weapon.goatFoot || profile.posture != 'standing')) return nil;
        seconds = difference <= 0 ? 4 : difference <= 2 ? 8 : 20;
    }
    if (weapon.ammunition >= mode.capacity) return nil;
    return seconds;
}

/** Advance one second of a legal reload; consume reserves only when loading completes. */
rpgLiteReload(profile, weapon, mode)
{
    local seconds = rpgLiteReloadSeconds(profile, weapon, mode);
    if (seconds == nil) return nil;
    weapon.ready = nil; weapon.reloadProgress += 1;
    if (weapon.reloadProgress >= seconds)
    {
        local amount = mode.individualReload ? 1 : mode.capacity - weapon.ammunition;
        if (amount > weapon.reserves) amount = weapon.reserves;
        weapon.ammunition += amount; weapon.reserves -= amount; weapon.reloadProgress = 0; weapon.ready = true;
    }
    return true;
}

/** Buy an affordable, available item once and transfer it to the character inventory. */
rpgLiteBuy(profile, item)
{
    if (holds(profile.equipment, item) || profile.money < item.cost
        || item.ofKind(RpgLiteWeapon) && item.techLevel > profile.techLevel) return nil;
    profile.money -= item.cost; profile.equipment = profile.equipment + [item]; return true;
}

/** Sum DR of the character's worn equipment. */
rpgLiteArmor(profile)
{
    local total = 0;
    foreach (local item in profile.equipment) if (item.worn && item.usableBy(profile)) total += item.dr;
    return total;
}
