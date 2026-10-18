#include <vhyl.h>
#include <vhyl.t>
#include <vhyl-rpg.t>
#include <vhyl-rpg-progression.t>
#include <vhyl-rpg-lite.t>
#include <vhyl-rpg-expanded.t>
#include <vhyl-rpg-expanded-health.t>
healthRoom: Room 'Recovery';
modify gameMain initialRoom = healthRoom;
startup() { return vhylStart(); }
act(verb,args)
{
    if (verb == 1600)
    {
        event('test.scaled-shock'); eventValue(rpgExpandedInjuryShock(args[1],args[2])); return nil;
    }
    if (verb == 1601)
    {
        local rules = new RpgExpandedRules(); rules.scaledInjuryShock = args[1] == 1;
        local p = new RpgExpandedProfile(); p.rules = rules; p.st = 30;
        if (args[2] == 1) p.traits = [rpgLiteMakeTrait('high-pain-threshold',1,nil)];
        local before = rpgRandom.draws; rpgLiteWound(p,8); event('test.shock-integration');
        eventValue(p.injury); eventValue(p.shock); rpgLiteWound(p,8);
        eventValue(p.injury); eventValue(p.shock); eventValue(rpgRandom.draws - before); return nil;
    }
    if (verb == 1602)
    {
        local rules = new RpgExpandedRules(); rules.scaledInjuryShock = true;
        local p = new RpgExpandedProfile(); p.rules = rules; p.st = 30;
        local trait = new RpgLiteTrait(); trait.id = 'low-pain-threshold'; p.traits = [trait];
        local before = rpgRandom.draws; event('test.shock-rejection');
        try { rpgLiteWound(p,8); eventValue('unexpected-success'); }
        catch (RpgExpandedError error) { eventValue(error.reason); }
        eventValue(p.injury); eventValue(p.shock); eventValue(p.woundSerial);
        eventValue(rpgRandom.draws - before); return nil;
    }
    if (verb == 1603)
    {
        local rules = new RpgExpandedRules(); rules.scaledInjuryShock = args[1] == 1;
        local p = new RpgExpandedProfile(); p.rules = rules; p.st = 30;
        if (args[2] == 1) p.traits = [rpgLiteMakeTrait('high-pain-threshold',1,nil)];
        local before = rpgRandom.draws; event('test.shock-turn');
        eventValue(p.shockAfterTurn(8)); rpgLiteWound(p,8);
        local fighter = new RpgLiteFighter(); fighter.profile = p;
        local other = new RpgLiteFighter(); other.profile = new RpgLiteProfile();
        local battle = new RpgLiteBattle(); battle.fighters = [fighter,other];
        battle.order = [fighter,other]; battle.active = true;
        local value = battle.step(fighter,new RpgLiteManeuver()); eventValue(value.status);
        eventValue(p.shock); eventValue(p.injury); eventValue(rpgRandom.draws - before); return nil;
    }
    if (verb == 1604)
    {
        local value = rpgExpandedAssessKnockdown(args[1],args[2],args[3],args[4] == 1);
        event('test.knockdown-assessment'); eventValue(value.major ? 1 : 0);
        eventValue(value.required ? 1 : 0); eventValue(value.modifier); eventValue(value.shock); return nil;
    }
    if (verb == 1605)
    {
        event('test.knockdown-rejection');
        try { rpgExpandedAssessKnockdown(10,3,'eye',nil); }
        catch (RpgExpandedError error) { eventValue(error.reason); }
        try { rpgExpandedAssessKnockdown(10,3,'torso',true); }
        catch (RpgExpandedError error) { eventValue(error.reason); }
        return nil;
    }
    if (verb == 1606)
    {
        local rules = new RpgExpandedRules(); rules.scaledInjuryShock = true;
        local p = new RpgExpandedProfile(); p.rules = rules; p.ht = args[3];
        local wound = new RpgExpandedWound(); wound.id = 'impact'; wound.profile = p;
        wound.amount = args[1]; wound.location = args[2];
        rpgRandom.seed(1); event('test.wound-commit'); local preview = wound.assess();
        eventValue(preview.status); eventValue(preview.reason); eventValue(p.injury); eventValue(rpgRandom.draws);
        local result = wound.apply(); eventValue(result.status); eventValue(p.injury); eventValue(p.shock);
        eventValue(p.stunned ? 1 : 0); eventValue(p.unconscious ? 1 : 0);
        eventValue(result.health == nil ? 0 : result.health.checks.length()); eventValue(rpgRandom.draws);
        eventValue(wound.apply().status); eventValue(p.expandedWounds.length()); return nil;
    }
    if (verb == 1607)
    {
        local rules = new RpgExpandedRules(); rules.scaledInjuryShock = true;
        local p = new RpgExpandedProfile(); p.rules = rules;
        local wound = new RpgExpandedWound(); wound.id = 'impact'; wound.profile = p; wound.amount = 6;
        local item = new RpgLiteItem(); item.ready = true; p.equipment = [item];
        local before = rpgRandom.draws; event('test.wound-gates'); eventValue(wound.apply().reason);
        item.ready = nil; wound.anatomy = 'other'; eventValue(wound.apply().reason);
        wound.anatomy = 'standard-humanoid'; rules.scaledInjuryShock = nil; eventValue(wound.apply().reason);
        eventValue(p.injury); eventValue(p.expandedWounds.length()); eventValue(rpgRandom.draws - before); return nil;
    }
    if (verb == 1608)
    {
        local rules = new RpgExpandedRules(); rules.scaledInjuryShock = true;
        local p = new RpgExpandedProfile(); p.rules = rules;
        local trait = new RpgLiteTrait(); trait.id = args[3]; p.traits = [trait];
        local wound = new RpgExpandedWound(); wound.id = 'anatomy-impact'; wound.profile = p;
        wound.amount = args[1]; wound.location = args[2]; wound.maleGroin = args[4] == 1;
        rpgRandom.seed(1); local value = wound.apply(); event('test.anatomy-wound');
        eventValue(value.status); eventValue(p.injury); eventValue(value.assessment.required ? 1 : 0);
        eventValue(value.assessment.modifier); eventValue(p.stunned ? 1 : 0);
        eventValue(rpgRandom.draws); eventValue(wound.knockdownAssessment.brainException ? 1 : 0);
        eventValue(wound.knockdownAssessment.vitalsException ? 1 : 0); return nil;
    }
    if (verb == 1609)
    {
        local before = rpgRandom.draws;
        local value = rpgExpandedAssessCrippling(args[1],args[2],args[3],args[4],args[5] == 1);
        event('test.crippling-assessment'); eventValue(value.minimumInjury); eventValue(value.healthLoss);
        eventValue(value.crippled ? 1 : 0); eventValue(value.destroyed ? 1 : 0);
        eventValue(value.severed ? 1 : 0); eventValue(rpgRandom.draws - before); return nil;
    }
    if (verb == 1610)
    {
        local p = new RpgExpandedProfile(); p.rules = new RpgExpandedRules();
        local arm = new RpgExpandedBodyPart(); arm.id = 'left-arm'; arm.profile = p;
        local hand = new RpgExpandedBodyPart(); hand.id = 'left-hand'; hand.profile = p;
        hand.kind = 'hand'; hand.parent = arm; p.bodyParts = [arm,hand];
        arm.disabled = args[1] == 1; hand.disabled = args[2] == 1; arm.severed = args[3] == 1;
        local weapon = new RpgLiteWeapon(); weapon.ready = true; weapon.bodySupports = [hand];
        local shield = new RpgLiteItem(); shield.db = 3; shield.bodySupports = [arm];
        local before = rpgRandom.draws; rpgExpandedValidate(p); event('test.body-supports');
        eventValue(weapon.attackUsableBy(p) ? 1 : 0); eventValue(weapon.parryUsableBy(p) ? 1 : 0);
        eventValue(shield.attackUsableBy(p) ? 1 : 0); eventValue(shield.blockUsableBy(p) ? 1 : 0);
        eventValue(shield.passiveDefenseBonus(p)); eventValue(rpgRandom.draws - before);
        if (arm.disabled || hand.disabled)
        {
            local fighter = new RpgLiteFighter(); fighter.profile = p; fighter.weapon = weapon;
            event('test.disabled-strike');
            eventValue(rpgLiteStrike(fighter,nil,new RpgLiteManeuver()).reason);
            eventValue(rpgRandom.draws - before);
        }
        return nil;
    }
    if (verb == 1611)
    {
        local p = new RpgExpandedProfile(); p.rules = new RpgExpandedRules();
        local arm = new RpgExpandedBodyPart(); arm.id = 'arm'; arm.profile = p; p.bodyParts = [arm];
        local item = new RpgLiteItem(); item.bodySupports = [arm];
        event('test.body-support-rejections');
        try { item.attackUsableBy(p); eventValue('unexpected'); }
        catch (RpgExpandedError error) { eventValue(error.reason); }
        arm.severed = true;
        try { rpgExpandedValidate(p); eventValue('unexpected'); }
        catch (RpgExpandedError error) { eventValue(error.reason); }
        arm.severed = nil; item.bodySupports = [arm,arm];
        try { item.blockUsableBy(p); eventValue('unexpected'); }
        catch (RpgExpandedError error) { eventValue(error.reason); }
        item.bodySupports = [arm]; local other = new RpgExpandedProfile(); other.rules = p.rules;
        try { item.blockUsableBy(other); eventValue('unexpected'); }
        catch (RpgExpandedError error) { eventValue(error.reason); }
        arm.kind = 'wing';
        try { rpgExpandedValidate(p); eventValue('unexpected'); }
        catch (RpgExpandedError error) { eventValue(error.reason); }
        return nil;
    }
    if (verb == 1612 || verb == 1614)
    {
        local p = new RpgExpandedProfile(); p.rules = new RpgExpandedRules();
        local left = new RpgExpandedBodyPart(); left.id = 'left'; left.profile = p;
        local right = new RpgExpandedBodyPart(); right.id = 'right'; right.profile = p;
        local lh = new RpgExpandedBodyPart(); lh.id = 'left-hand'; lh.profile = p; lh.kind = 'hand'; lh.parent = left;
        local rh = new RpgExpandedBodyPart(); rh.id = 'right-hand'; rh.profile = p; rh.kind = 'hand'; rh.parent = right;
        p.bodyParts = [left,right,lh,rh]; left.disabled = args[1] > 0; right.disabled = args[1] > 1;
        lh.disabled = args[2] == 1;
        if (args[3] == 1)
        {
            local held = new RpgLiteItem(); held.id = 'held'; held.ready = true; held.bodySupports = [rh];
            p.equipment = [held];
        }
        local defender = new RpgLiteFighter(); defender.profile = p; defender.freeHands = args[4];
        local attacker = new RpgLiteFighter(); attacker.profile = new RpgLiteProfile();
        attacker.weapon = rpgLiteMakeWeapon('punch',10);
        if (verb == 1614) defender.weapon = rpgLiteMakeWeapon('punch',10);
        local request = new RpgLiteManeuver(); local before = rpgRandom.draws;
        local punch = rpgLiteMakeWeapon('punch',10); punch.bodySupports = [lh];
        event('test.unarmed-capacity'); eventValue(defender.unarmedParryCapacity());
        eventValue(rpgLiteDefenseScore(defender,attacker,request,'parry'));
        eventValue(rpgLiteDefenseScore(defender,attacker,request,'parry-other'));
        eventValue(punch.attackUsableBy(p) ? 1 : 0); eventValue(rpgRandom.draws - before); return nil;
    }
    if (verb == 1613)
    {
        local p = new RpgExpandedProfile(); p.rules = new RpgExpandedRules();
        local arm = new RpgExpandedBodyPart(); arm.id = 'arm'; arm.profile = p; p.bodyParts = [arm];
        local fighter = new RpgLiteFighter(); fighter.profile = p;
        local item = new RpgLiteItem(); item.ready = true; p.equipment = [item];
        event('test.unarmed-gates');
        try { fighter.unarmedParryCapacity(); eventValue('unexpected'); }
        catch (RpgExpandedError error) { eventValue(error.reason); }
        local punch = rpgLiteMakeWeapon('punch',10);
        try { punch.attackUsableBy(p); eventValue('unexpected'); }
        catch (RpgExpandedError error) { eventValue(error.reason); }
        fighter.profile = new RpgLiteProfile(); fighter.freeHands = 1;
        eventValue(fighter.unarmedParryCapacity());
        fighter.profile = new RpgExpandedProfile(); fighter.freeHands = 2;
        eventValue(fighter.unarmedParryCapacity()); return nil;
    }
    if (verb == 1615)
    {
        event('test.crippling-months'); eventValue(rpgExpandedCripplingMonths(args[1],args[2] < 0 ? nil : args[2]));
        return nil;
    }
    if (verb == 1616)
    {
        local rules = new RpgExpandedRules(); rules.scaledInjuryShock = true; rules.lastWounds = args[6] == 1;
        local p = new RpgExpandedProfile(); p.rules = rules; p.st = args[1]; p.injury = args[2];
        local arm = new RpgExpandedBodyPart(); arm.profile = p; arm.id = 'arm';
        local hand = new RpgExpandedBodyPart(); hand.profile = p; hand.id = 'hand'; hand.kind = 'hand'; hand.parent = arm;
        p.bodyParts = [arm,hand];
        local wound = new RpgExpandedWound(); wound.profile = p; wound.id = 'last-wound'; wound.amount = args[3];
        wound.location = args[4]; wound.bodyPart = args[4] == 'torso' ? nil : args[4] == 'arm' ? arm : hand; wound.criticalHit = args[5] == 1;
        rpgRandom.seed(1); local preview = wound.assess(); event('test.last-wound-preview');
        eventValue(preview.ignored ? 1 : 0); eventValue(preview.healthLoss); eventValue(p.injury); eventValue(rpgRandom.draws);
        local value = wound.apply(); event('test.last-wound'); eventValue(value.ignored ? 1 : 0);
        eventValue(value.healthLoss); eventValue(p.injury); eventValue(p.woundSerial); eventValue(rpgRandom.draws);
        eventValue(wound.bodyPart != nil && wound.bodyPart.disabled ? 1 : 0); eventValue(p.expandedWounds.length());
        eventValue(wound.apply().ignored ? 1 : 0);
        wound.criticalHit = !wound.criticalHit;
        try { wound.apply(); eventValue('unexpected'); }
        catch (RpgExpandedError error) { eventValue(error.reason); }
        return nil;
    }
    return vhylAct(verb,args);
}
