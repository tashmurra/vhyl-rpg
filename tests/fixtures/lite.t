#include <vhyl.h>
#include <vhyl.t>
#include <vhyl-rpg.t>
#include <vhyl-rpg-progression.t>
#include <vhyl-rpg-lite.t>
liteRoom: Room 'Library';
liteHero: RpgLiteProfile actor = player pointBudget = 1000 disadvantageLimit = 500;
liteEnemy: RpgLiteProfile pointBudget = 1000;
liteInput: object code = 0 args = [];
liteFighter: RpgLiteFighter profile = liteHero;
liteOpponent: RpgLiteFighter profile = liteEnemy;
liteBattle: RpgLiteBattle fighters = [liteFighter, liteOpponent];
liteCare: RpgLiteTreatment patient = liteHero healer = liteEnemy techLevel = 8;
liteExposure: RpgLiteExposure profile = liteHero;
liteJourney: RpgLiteJourney profile = liteHero;
liteNeeds: RpgLiteNeeds profile = liteHero;
liteClimate: RpgLiteClimate profile = liteHero;
liteFire: RpgLiteFire profile = liteHero;
liteSetup: InitObject
    execute()
    {
        liteFighter.weapon = rpgLiteMakeWeapon('broadsword', 10); liteFighter.weapon.ready = true;
        liteOpponent.weapon = rpgLiteMakeWeapon('punch', 10); liteOpponent.weapon.ready = true;
        liteHero.equipment = [liteFighter.weapon]; liteEnemy.equipment = [liteOpponent.weapon];
        liteCare.skill = rpgLiteMakeSkill('first-aid', 8, nil);
        liteExposure.hazard = new RpgLiteHazard(); liteExposure.hazard.dice = 1;
        liteExposure.hazard.adds = -5; liteExposure.hazard.resistible = nil;
        liteExposure.hazard.delay = 10; liteExposure.hazard.interval = 20; liteExposure.hazard.cycles = 3;
        return nil;
    }
;
class LiteTestAction: Action
    exec(context)
    {
        local code = liteInput.code; local args = liteInput.args; local value = nil;
        if (code == 1) value = rpgLiteWound(liteHero, args[2]);
        if (code == 2) value = rpgLiteFatigue(liteHero, args[2], 'exertion');
        if (code == 3) value = rpgLiteRest(liteHero, args[2], true, true, nil, true);
        if (code == 4) rpgRandom.seed(args[2]);
        if (code == 5) liteHero.traits = liteHero.traits + [rpgLiteMakeTrait(args[2], args[3], nil)];
        if (code == 6) { liteHero.ht = args[2]; liteHero.dx = args[3]; }
        if (code == 7) value = liteCare.advance(args[2]);
        if (code == 8) liteBattle.begin();
        if (code == 9)
        {
            local request = new RpgLiteManeuver(); request.kind = args[2]; request.option = args[3];
            request.target = liteBattle.current() == liteFighter ? liteOpponent : liteFighter;
            request.posture = args.length() > 3 ? args[4] : nil;
            request.hands = 1;
            local result = liteBattle.step(liteBattle.current(), request);
            event('test.combat'); eventValue(result.status); eventValue(result.reason);
            eventValue(result.outcome); eventValue(result.damage); eventValue(result.injury);
        }
        if (code == 10) value = liteExposure.advance(args[2]);
        if (code == 11) { rpgLiteWound(liteHero, 3); throw new RpgError(); }
        if (code == 12)
        {
            liteFighter.weapon = rpgLiteMakeWeapon(args[2], 10);
            liteFighter.weapon.ready = true; liteFighter.modeIndex = 1;
            liteFighter.weapon.ammunition = args[3]; liteFighter.weapon.reserves = 20;
            liteHero.equipment = [liteFighter.weapon];
        }
        if (code == 13) rpgLiteReload(liteHero, liteFighter.weapon, liteFighter.mode());
        if (code == 14)
        {
            local method = new RpgLiteContext(); method.attribute = rpgIQ;
            local check = rpgLiteCheck(liteHero, method);
            local changed = rpgLiteLuck(liteHero, check, nil);
            event('test.luck'); eventValue(check.roll); eventValue(changed.roll);
        }
        if (code == 15) rpgLiteSuffocate(liteHero, args[2], nil);
        if (code == 16)
        {
            liteNeeds.meals = args[2]; liteNeeds.waterQuarts = args[3]; liteNeeds.advance(args[4]);
        }
        if (code == 17)
        {
            local care = new RpgLiteTreatment(); care.patient = liteHero; care.healer = liteEnemy;
            care.skill = liteCare.skill; care.advance(60);
        }
        if (code == 18) liteHero.techLevel = args[2];
        if (code == 19)
        {
            liteClimate.fahrenheit = args[2]; liteClimate.clothing = -100; liteClimate.advance(args[3]);
        }
        if (code == 20) rpgLiteRest(liteHero, args[2], true, true, true, true);
        if (code == 21) liteFire.ignite(args[2]);
        if (code == 22) liteFire.extinguish(true);
        if (code == 23)
        {
            local item = rpgLiteMakeTrait('bad-temper', 1, nil); liteHero.traits = liteHero.traits + [item];
            liteHero.earnedPoints = 20; liteHero.unspentPoints = 20; liteHero.developmentOpen = true;
            rpgLiteBuyOff(liteHero, item);
            rpgLiteLearn(liteHero, rpgLiteMakeSkill('karate', nil, nil), 4, nil);
        }
        if (code == 24)
        {
            local tongue = new RpgLiteLanguage(); tongue.id = 'test-language'; tongue.written = args[2];
            liteHero.languages = [tongue];
            local reading = rpgLiteRead(liteHero, tongue.id);
            event('test.reading'); eventValue(reading.status); eventValue(reading.outcome); eventValue(reading.reason);
        }
        if (code == 25)
        {
            liteJourney.kind = 'climbing'; liteJourney.surface = 'ladder-up'; liteJourney.advance(1);
            event('test.default-skill'); eventValue(liteJourney.skill.id); eventValue(liteHero.skillScore(liteJourney.skill));
        }
        if (code == 26)
        {
            liteCare.skill = nil; liteCare.techLevel = 3; liteEnemy.iq = 20;
            local treatment = liteCare.advance(1860);
            event('test.default-aid'); eventValue(treatment.check.score);
        }
        if (value != nil)
        {
            event('test.health'); eventValue(value.status); eventValue(value.injury);
            eventValue(value.healed); eventValue(value.fatigue); eventValue(value.seconds);
        }
        return nil;
    }
;
liteTestAction: LiteTestAction;
liteTestVerb: Verb code = 600 action = liteTestAction label = 'lite-test';
startup() { return vhylStart(); }
act(verb, args)
{
    if (verb == 600) { liteInput.code = args[1]; liteInput.args = args; return vhylAct(600, []); }
    if (verb == 990)
    {
        event('test.lite'); eventValue(liteHero.hp()); eventValue(liteHero.fp());
        eventValue(liteHero.shock); eventValue(liteHero.stunned); eventValue(liteHero.unconscious);
        eventValue(liteHero.dead); eventValue(liteHero.mortal); eventValue(liteHero.posture);
        eventValue(rpgRandom.state); eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds);
        eventValue(liteHero.restClock); eventValue(liteHero.luckReady); eventValue(liteHero.traits.length());
        eventValue(liteBattle.index); eventValue(liteBattle.seconds); eventValue(liteEnemy.injury);
        eventValue(liteFighter.weapon.ammunition); eventValue(liteFighter.weapon.reloadProgress);
        eventValue(liteExposure.elapsed); eventValue(liteExposure.remaining); eventValue(liteExposure.finished);
        eventValue(liteHero.lastCheck == nil ? nil : liteHero.lastCheck.roll);
        eventValue(liteHero.hunger); eventValue(liteHero.thirst); eventValue(liteHero.sleepDebt);
        eventValue(liteHero.temperatureFatigue); eventValue(liteClimate.elapsed);
        eventValue(liteFighter.maneuver); eventValue(liteFighter.aimSeconds); eventValue(liteFighter.weapon.ready);
        eventValue(liteHero.burningPenalty); eventValue(liteHero.unspentPoints); eventValue(liteHero.skills.length());
        return nil;
    }
    if (verb == 991)
    {
        local profile = new RpgLiteProfile(); profile.st = args[1]; profile.dx = args[2]; profile.ht = args[3];
        local item = new RpgLiteItem(); item.weight = args[4]; profile.equipment = [item];
        local thrust = rpgLiteDamageDice(profile.st, nil); local swing = rpgLiteDamageDice(profile.st, true);
        event('test.derived'); eventValue(profile.basicLiftHundredths()); eventValue(profile.basicSpeedQuarters());
        eventValue(profile.basicMove()); eventValue(profile.encumbrance()); eventValue(profile.move());
        eventValue(thrust[1]); eventValue(thrust[2]); eventValue(swing[1]); eventValue(swing[2]); return nil;
    }
    if (verb == 992)
    {
        event('test.penetration'); eventValue(rpgLitePenetration(args[1],args[2],args[3],args[4],args[5] != 0)); return nil;
    }
    if (verb == 993)
    {
        foreach (local row in rpgLiteCatalogue.traits)
        { local trait = rpgLiteMakeTrait(row[1],1,nil); event('test.trait'); eventValue(trait.id); eventValue(rpgLiteTraitCost(trait)); }
        foreach (local row in rpgLiteCatalogue.skills)
        { local skill = rpgLiteMakeSkill(row[1],row[5] ? 3 : nil,nil); event('test.skill'); eventValue(skill.id); eventValue(skill.attribute == rpgDX ? 'DX' : skill.attribute == rpgIQ ? 'IQ' : 'HT'); eventValue(skill.difficulty); eventValue(skill.defaultPenalty); }
        foreach (local row in rpgLiteArmory.weapons)
        { local weapon = rpgLiteMakeWeapon(row[1],10); event('test.weapon'); eventValue(weapon.id); eventValue(weapon.modes.length()); }
        return nil;
    }
    if (verb == 994)
    {
        local method = new RpgLiteContext(); method.kind = args[1]; method.attribute = rpgIQ;
        event('test.score'); eventValue(rpgLiteScore(liteHero,method)); return nil;
    }
    if (verb == 995)
    {
        event('test.travel'); eventValue(rpgLiteJumpDistance(liteHero,nil,args[1],true));
        eventValue(rpgLiteJumpDistance(liteHero,nil,args[1],nil)); eventValue(rpgLiteThrowDistance(liteHero,args[2]));
        eventValue(rpgLiteHikingMilesHundredths(liteHero,'good',100,true)); return nil;
    }
    if (verb == 996)
    {
        local profile = new RpgLiteProfile(); profile.pointBudget = 1000;
        local nativeTongue = new RpgLiteLanguage(); nativeTongue.id = 'native'; nativeTongue.native = true; nativeTongue.written = 0;
        profile.languages = [nativeTongue]; profile.st = 11; profile.dx = 12; profile.iq = 11; profile.ht = 12;
        profile.traits = [rpgLiteMakeTrait('combat-reflexes',1,nil),rpgLiteMakeTrait('bad-temper',1,nil)];
        try { rpgLiteValidateCharacter(profile); }
        catch (RpgLiteCharacterError error)
        { event('test.character-error'); eventValue(error.reason); return nil; }
        event('test.character'); eventValue(rpgLiteCharacterCost(profile,nil)); eventValue(rpgLiteCharacterCost(profile,true));
        eventValue(rpgLiteStartingWealth(profile,true)); eventValue(profile.language('native',true)); return nil;
    }
    if (verb == 997)
    {
        local profile = new RpgLiteProfile(); local skill = rpgLiteMakeSkill(args[1],nil,nil);
        local training = new RpgTraining(); training.skill = skill; training.points = args[2];
        if (args[2] > 0) profile.skills = [training];
        event('test.training'); eventValue(profile.skillScore(skill)); return nil;
    }
    if (verb == 998)
    {
        local weapon = rpgLiteMakeWeapon(args[1],10); local mode = weapon.modes[1];
        event('test.weapon-data'); eventValue(weapon.cost); eventValue(weapon.weight);
        eventValue(mode.base); eventValue(mode.dice); eventValue(mode.adds); eventValue(mode.damageType);
        eventValue(mode.acc); eventValue(mode.halfRange); eventValue(mode.maximumRange); eventValue(mode.capacity);
        eventValue(mode.minimumST); eventValue(mode.reloadSeconds); return nil;
    }
    if (verb == 999)
    {
        local defender = new RpgLiteFighter(); defender.profile = new RpgLiteProfile();
        defender.profile.dx = 12; defender.profile.ht = 12; defender.profile.posture = args[1];
        defender.maneuver = args[2]; defender.defenseOption = 'dodge';
        defender.weapon = rpgLiteMakeWeapon('broadsword',10); defender.weapon.ready = true;
        defender.shield = rpgLiteMakeArmor('medium-shield'); defender.shield.ready = true;
        local request = new RpgLiteManeuver();
        event('test.defenses');
        eventValue(rpgLiteDefenseScore(defender,liteOpponent,request,'dodge'));
        eventValue(rpgLiteDefenseScore(defender,liteOpponent,request,'block'));
        eventValue(rpgLiteDefenseScore(defender,liteOpponent,request,'parry')); return nil;
    }
    if (verb == 1000)
    {
        event('test.reaction'); eventValue(rpgLiteReaction(args[1])); return nil;
    }
    return vhylAct(verb, args);
}
modify gameMain initialRoom = liteRoom;
