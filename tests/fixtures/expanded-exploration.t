#include <vhyl.h>
#include <vhyl.t>
#include <vhyl-rpg.t>
#include <vhyl-rpg-progression.t>
#include <vhyl-rpg-lite.t>
#include <vhyl-rpg-expanded.t>
#include <vhyl-rpg-expanded-exploration.t>
explorationRoom: Room 'Air Chamber';
modify gameMain initialRoom = explorationRoom;
startup() { rpgRandom.seed(1); return vhylStart(); }
act(verb,args)
{
    if (verb == 1870)
    {
        local time = rpgLedger.seconds; local draws = rpgRandom.draws;
        local value = rpgExpandedBreathDuration(args[1],args[2],args[3] == 1,args[4],args[5] == 1,args[6]);
        event('test.breath-duration'); eventValue(value.status); eventValue(value.reason); eventValue(value.seconds);
        eventValue(rpgLedger.seconds - time); eventValue(rpgRandom.draws - draws); return nil;
    }
    if (verb == 1871)
    {
        local patient = new RpgExpandedProfile(); patient.rules = new RpgExpandedRules();
        local reserve = new RpgExpandedBreathReserve(); reserve.id = 'dive'; reserve.profile = patient;
        reserve.evidence = 'One second of preparation already completed; mild exertion throughout';
        local start = reserve.start(); local repeat = reserve.start();
        rpgSpendTime(args[1]); local time = rpgLedger.seconds; local before = reserve.assess();
        local ended = reserve.resumeAir('Breathable air restored'); local after = reserve.assess();
        patient.validateFeatures();
        event('test.breath-reserve'); eventValue(start.status); eventValue(repeat.status);
        eventValue(before.elapsedSeconds); eventValue(before.remainingSeconds); eventValue(before.exhausted ? 1 : 0);
        eventValue(ended.status); eventValue(ended.reason); eventValue(patient.breathReserve == nil ? 0 : 1);
        eventValue(after.elapsedSeconds); eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds - time); return nil;
    }
    if (verb == 1872)
    {
        local patient = new RpgExpandedProfile(); patient.rules = new RpgExpandedRules();
        local reserve = new RpgExpandedBreathReserve(); reserve.id = 'one'; reserve.profile = patient;
        reserve.evidence = 'Prepared breath'; reserve.start();
        local other = new RpgExpandedBreathReserve(); other.id = 'two'; other.profile = patient; other.evidence = 'New attempt';
        local duplicate = other.start(); local rejected = nil;
        try { rpgLiteSuffocate(patient,1,nil); } catch (RpgExpandedError error) { rejected = true; }
        event('test.breath-conflict'); eventValue(duplicate.reason); eventValue(rejected ? 1 : 0);
        eventValue(patient.fatigue); eventValue(patient.airClock); eventValue(rpgRandom.draws); return nil;
    }
    if (verb == 1873)
    {
        event('test.swimming-modifier'); eventValue(rpgExpandedSwimmingModifier(args[1] == 1,args[2],args[3])); return nil;
    }
    if (verb == 1874)
    {
        local time = rpgLedger.seconds; local draws = rpgRandom.draws;
        local value = rpgExpandedSwimmingOutcome(args[1],args[2],args[3]);
        event('test.swimming-outcome'); eventValue(value.nextStage); eventValue(value.seconds);
        eventValue(value.fatigue); eventValue(value.inhaledWater ? 1 : 0);
        eventValue(rpgLedger.seconds - time); eventValue(rpgRandom.draws - draws); return nil;
    }
    if (verb == 1875)
    {
        local modifier = rpgExpandedLifesavingModifier(args[1],args[2],args[3]);
        local time = rpgLedger.seconds; local draws = rpgRandom.draws;
        local value = rpgExpandedLifesavingOutcome(args[4],args[5]);
        event('test.lifesaving'); eventValue(modifier); eventValue(value.rescued ? 1 : 0);
        eventValue(value.fatigue); eventValue(value.inhaledWater ? 1 : 0); eventValue(value.seconds);
        eventValue(value.mustBreakOff ? 1 : 0); eventValue(rpgLedger.seconds - time); eventValue(rpgRandom.draws - draws); return nil;
    }
    if (verb == 1876)
    {
        local patient = new RpgExpandedProfile(); patient.rules = new RpgExpandedRules(); patient.ht = 14;
        local encounter = new RpgExpandedSwimmingEncounter(); encounter.id = 'river'; encounter.profile = patient; encounter.defaultAvailable = true;
        encounter.evidence = 'Unexpected deep water; ordinary build; unchanged activity'; encounter.start();
        local first = new RpgExpandedSwimCheck(); first.id = 'entry'; first.encounter = encounter;
        rpgRandom.seed(5); local value = first.apply(); first.apply(); patient.validateFeatures();
        event('test.swim-entry'); eventValue(value.check.score); eventValue(value.fatigue); eventValue(encounter.stage);
        eventValue(encounter.nextCheckAt - encounter.startedAt); eventValue(rpgRandom.draws);
        local second = new RpgExpandedSwimCheck(); second.id = 'recover'; second.encounter = encounter;
        local early = second.apply(); local exit = encounter.leave('Attempt to leave while struggling');
        rpgSpendTime(5); second.apply(); patient.validateFeatures();
        event('test.swim-recover'); eventValue(early.reason); eventValue(exit.reason); eventValue(encounter.stage);
        eventValue(encounter.nextCheckAt - encounter.startedAt); eventValue(patient.fatigue); eventValue(rpgRandom.draws);
        rpgSpendTime(60); local third = new RpgExpandedSwimCheck(); third.id = 'stable'; third.encounter = encounter;
        third.apply(); local ended = encounter.leave('Climbed onto the bank'); patient.validateFeatures(); first.apply();
        event('test.swim-stable'); eventValue(encounter.stage); eventValue(encounter.nextCheckAt - encounter.startedAt);
        eventValue(patient.fatigue); eventValue(ended.status); eventValue(patient.swimmingEncounter == nil ? 0 : 1);
        eventValue(rpgRandom.draws); return nil;
    }
    if (verb == 1877)
    {
        local patient = new RpgExpandedProfile(); patient.rules = new RpgExpandedRules(); patient.ht = args[1];
        patient.fatigue = args[2]; local item = new RpgLiteItem(); item.weight = args[3]; patient.equipment = [item];
        local encounter = new RpgExpandedSwimmingEncounter(); encounter.id = 'score'; encounter.profile = patient; encounter.defaultAvailable = args.length() <= 4;
        encounter.evidence = 'Deep water with recorded equipment';
        if (args[4] == 1)
        {
            local skill = new RpgLiteSkill(); skill.id = 'swimming'; skill.attribute = rpgHT; skill.difficulty = 0; skill.defaultPenalty = -4;
            local training = new RpgTraining(); training.skill = skill; training.points = 1; patient.skills = [training];
            encounter.skill = skill;
        }
        encounter.start(); local check = new RpgExpandedSwimCheck(); check.id = 'entry'; check.encounter = encounter;
        local value = check.assess(); event('test.swim-score'); eventValue(value.status); eventValue(value.reason);
        eventValue(value.context == nil ? nil : rpgLiteScore(patient,value.context)); eventValue(patient.fatigue); eventValue(rpgRandom.draws); return nil;
    }
    return vhylAct(verb,args);
}
