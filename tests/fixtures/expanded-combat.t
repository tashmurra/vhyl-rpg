#include <vhyl.h>
#include <vhyl.t>
#include <vhyl-rpg.t>
#include <vhyl-rpg-progression.t>
#include <vhyl-rpg-lite.t>
#include <vhyl-rpg-expanded.t>
#include <vhyl-rpg-expanded-combat.t>
burstRoom: Room 'Range';
modify gameMain initialRoom = burstRoom;
startup() { return vhylStart(); }
act(verb,args)
{
    local draws = rpgRandom.draws; local clock = rpgLedger.seconds;
    if (verb == 2010) { event('test.burst-bonus'); eventValue(rpgExpandedRapidFireBonus(args[1])); }
    else if (verb == 2011)
    {
        local value = rpgExpandedAssessBurst(args[1],args[2],args[3],args[4]);
        event('test.burst-assessment'); eventValue(value.status); eventValue(value.reason);
        eventValue(value.shots); eventValue(value.modifier);
    }
    else if (verb == 2012)
    { event('test.burst-hits'); eventValue(rpgExpandedRapidFireHits(args[1],args[2],args[3])); }
    else if (verb == 2013)
    {
        local value = rpgExpandedRapidFireDodge(args[1],args[2],args[3]);
        event('test.burst-dodge'); eventValue(value.avoided); eventValue(value.remaining);
        eventValue(value.check.achieved ? 1 : 0); eventValue(value.check.critical);
    }
    else if (verb == 2014)
    {
        local value = rpgExpandedCombatCheck(args[1],args[2],args[3]);
        event('test.combat-check'); eventValue(value.status); eventValue(value.reason);
        eventValue(value.achieved ? 1 : 0); eventValue(value.critical); eventValue(value.outcome);
    }
    else if (verb == 2015)
    {
        local value = rpgExpandedRangedOutcome(args[1],args[2],args[3] == 0 ? nil : args[3]);
        event('test.ranged-outcome'); eventValue(value.status); eventValue(value.reason); eventValue(value.outcome);
        eventValue(value.malfunction ? 1 : 0); eventValue(value.defenseAllowed ? 1 : 0); eventValue(value.criticalTable);
    }
    else if (verb == 2016)
    {
        local value = rpgExpandedCriticalHit(args[1],args[2],args[3],args[4] == 1);
        event('test.critical-hit'); eventValue(value.location); eventValue(value.basicDamageMultiplier);
        eventValue(value.maximumDamage ? 1 : 0); eventValue(value.ignoreArmor ? 1 : 0);
        eventValue(value.halveArmor ? 1 : 0); eventValue(value.roundArmorUp ? 1 : 0);
        eventValue(value.majorWoundOnPenetration ? 1 : 0); eventValue(value.doubleShockOnPenetration ? 1 : 0);
        eventValue(value.temporaryCrippleOnPenetration ? 1 : 0); eventValue(value.dropHeld ? 1 : 0);
        eventValue(value.dropWeapon ? 1 : 0); eventValue(value.forcedDoNothing ? 1 : 0);
        eventValue(value.deafenOnPenetration ? 1 : 0); eventValue(value.appearanceLossOnPenetration);
        eventValue(rpgExpandedCriticalArmor(value,5));
    }
    else if (verb == 2017)
    { event('test.critical-cripple'); eventValue(rpgExpandedCriticalCrippleSeconds(args[1])); }
    else if (verb == 2018)
    {
        local value = rpgExpandedCriticalHit(args[1],args[2],'cr',true);
        event('test.critical-arithmetic'); eventValue(rpgExpandedCriticalDamage(value,7,12));
        eventValue(rpgExpandedCriticalArmor(value,5));
        eventValue(rpgExpandedCriticalShock(value,args[3],args[4] == 1));
    }
    else if (verb == 2019)
    {
        local context = new RpgExpandedWeaponMissContext(); context.kind = args[1]; context.damageType = args[2];
        context.breakResistant = args[3] == 1; context.cheap = args[4] == 1;
        local rolls = [args[5]]; if (args[6] != 0) rolls = rolls + [args[6]];
        if (args[7] != 0) rolls = rolls + [args[7]];
        local value = rpgExpandedWeaponMiss(context,rolls);
        event('test.weapon-miss'); eventValue(value.status); eventValue(value.reason); eventValue(value.outcome);
        eventValue(value.rollsUsed); eventValue(value.selfDamageDivisor); eventValue(value.defenseModifier);
        eventValue(value.readyActions); eventValue(value.disabilitySeconds);
        eventValue(value.forbidsFurtherActions ? 1 : 0); eventValue(value.randomLimb ? 1 : 0);
        eventValue(value.randomDisplacement ? 1 : 0);
    }
    else if (verb == 2020)
    {
        local context = new RpgExpandedUnarmedMissContext(); context.kind = args[2]; context.limbUsed = args[3] == 1;
        context.naturalWeapon = args[4] == 1; context.kicking = args[5] == 1;
        context.normalMishapPenalty = args[6] == 999 ? nil : args[6]; context.health = args[7];
        context.intelligence = args[8]; context.animal = args[9] == 1; context.canFlee = args[10] == 1;
        context.foeReadyImpaling = args[11] == 1; context.highPainThreshold = args[12] == 1; context.mobility = args[13];
        local value = rpgExpandedUnarmedMiss(context,args[1]);
        event('test.unarmed-miss'); eventValue(value.outcome); eventValue(value.injury); eventValue(value.injuryDice);
        eventValue(value.injuryAdds); eventValue(value.injuryLocation); eventValue(value.recoveryIntervalSeconds);
        eventValue(value.disabilitySeconds); eventValue(value.painSeconds); eventValue(value.damageMode);
        eventValue(value.damageDivisor); eventValue(value.naturalDamageModifier); eventValue(value.attackModifier);
        eventValue(value.defenseModifier); eventValue(value.affectedActionModifier); eventValue(value.guardExposureMultiplier);
        eventValue(value.movePastYards); eventValue(value.turnAway ? 1 : 0); eventValue(value.dexterityModifier);
        eventValue(value.forbidsFurtherActions ? 1 : 0);
    }
    else if (verb == 2021)
    { event('test.unarmed-injury'); eventValue(rpgExpandedUnarmedMissInjury(args[1])); }
    else return vhylAct(verb,args);
    event('test.burst-purity'); eventValue(rpgRandom.draws - draws); eventValue(rpgLedger.seconds - clock); return nil;
}
