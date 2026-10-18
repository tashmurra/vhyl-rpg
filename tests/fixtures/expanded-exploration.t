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
    return vhylAct(verb,args);
}
