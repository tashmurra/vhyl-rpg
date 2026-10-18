#include <vhyl.h>
#include <vhyl.t>
#include <vhyl-rpg.t>
#include <vhyl-rpg-progression.t>
#include <vhyl-rpg-lite.t>
#include <vhyl-rpg-expanded.t>
#include <vhyl-rpg-expanded-exploration.t>
loadRoom: Room 'Loading yard';
modify gameMain initialRoom = loadRoom;
startup() { return vhylStart(); }
act(verb,args)
{
    if (verb == 2292)
    {
        local value = rpgExpandedAssessLift(args[1],args[2],['one-hand','two-hands','shove','back','shift'][args[3]],
            args[4] == 1,args[5] == 1,args[6] == 1);
        event('test.lift'); eventValue(value.status); eventValue(value.reason);
        eventValue(value.capacityHundredths); eventValue(value.seconds); eventValue(value.maneuver);
        eventValue(value.fatiguePerSecond); eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
    }
    if (verb == 2293)
    {
        local value = rpgExpandedAssessDragging(args[1],args[2],args[3],['none','snow-sledge','cart','wagon'][args[4]],args[5] == 1);
        event('test.drag'); eventValue(value.status); eventValue(value.reason);
        eventValue(value.effectiveNumerator); eventValue(value.effectiveDenominator);
        eventValue(value.encumbranceLevel); eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
    }
    if (verb == 2297)
    {
        local profile = new RpgExpandedProfile(); profile.st = args[1];
        local value = rpgExpandedAssessLift(profile.basicLiftHundredths(),args[2],'one-hand',nil,nil,nil);
        event('test.load-strength'); eventValue(profile.basicLiftHundredths());
        eventValue(value.seconds); eventValue(value.status); return nil;
    }
    if (verb == 2298)
    {
        local first = new RpgExpandedProfile(); first.st = 8;
        local second = new RpgExpandedProfile(); second.st = 11;
        local task = new RpgExpandedCooperativeLoad(); task.participants = [first,second];
        task.approved = true; task.evidence = 'Both workers have suitable access and grips on this authored load';
        task.weight = args[2];
        if (args[1] == 1) { task.operation = 'drag'; task.device = 'wagon'; task.deviceWeight = 10000; task.smoothLevel = true; }
        if (args[1] == 2) task.participants = [first,first];
        if (args[1] == 3) task.approved = nil;
        if (args[1] == 4) second.unconscious = true;
        event('test.cooperative-load');
        try
        {
            local value = task.assess(); eventValue(value.status); eventValue(value.reason);
            eventValue(value.combinedLift); eventValue(value.participantCount);
            eventValue(value.capacityHundredths); eventValue(value.effectiveNumerator);
            eventValue(value.effectiveDenominator); eventValue(value.encumbranceLevel);
        }
        catch (RpgExpandedError error) { eventValue(error.reason); }
        eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
    }
    return vhylAct(verb,args);
}
