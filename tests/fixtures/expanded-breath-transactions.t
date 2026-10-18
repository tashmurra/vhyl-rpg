#include <vhyl.h>
#include <vhyl.t>
#include <vhyl-en.t>
#include <vhyl-actions.t>
#include <vhyl-rpg.t>
#include <vhyl-rpg-progression.t>
#include <vhyl-rpg-lite.t>
#include <vhyl-rpg-expanded.t>
#include <vhyl-rpg-expanded-exploration.t>
breathRoom: Room 'Airlock';
breathRules: RpgExpandedRules;
breathPatient: RpgExpandedProfile rules = breathRules fatigue = 2;
breathReserve: RpgExpandedBreathReserve id = 'first' profile = breathPatient
    evidence = 'One-second preparation already completed; mild activity';
breathSecond: RpgExpandedBreathReserve id = 'second' profile = breathPatient
    evidence = 'Fresh prepared breath after restoring air';
breathInput: object code = 0;
class BreathFixtureAction: Action
    exec(context)
    {
        local code = breathInput.code; local value = nil;
        if (code == 0 || code == 1) value = breathReserve.start();
        else if (code == 2) { rpgSpendTime(39); return nil; }
        else if (code == 3 || code == 10) { rpgSpendTime(1); return nil; }
        else if (code == 4 || code == 5) value = breathReserve.resumeAir('Breathable air restored');
        else if (code == 6) { breathReserve.activity = 'none'; value = breathReserve.start(); }
        else if (code == 7) { breathPatient.validateFeatures(); return nil; }
        else if (code == 8) value = breathReserve.assess();
        else if (code == 9) value = breathSecond.start();
        else if (code == 12) { rpgLiteSuffocate(breathPatient,1,nil); return nil; }
        event('test.breath-operation'); eventValue(value.status); eventValue(value.reason);
        if (code == 1 || code == 5) throw new RpgError();
        return nil;
    }
;
breathAction: BreathFixtureAction;
breathVerb: Verb code = 1880 action = breathAction label = 'breath-fixture';
modify gameMain initialRoom = breathRoom;
startup() { rpgRandom.seed(1); return vhylStart(); }
turn(tokens) { return vhylTurn(tokens); }
act(verb,args)
{
    if (verb == 1880) { breathInput.code = args[1]; return vhylAct(verb,args); }
    if (verb == 1881)
    {
        local value = breathReserve.assess();
        event('test.breath-state'); eventValue(breathPatient.breathReserve == nil ? 0 : 1);
        eventValue(breathPatient.breathHistory.length()); eventValue(breathReserve.startedAt == nil ? 0 : 1);
        eventValue(breathReserve.endedAt == nil ? 0 : 1); eventValue(breathReserve.durationSeconds);
        eventValue(value.remainingSeconds); eventValue(value.elapsedSeconds); eventValue(rpgLedger.seconds);
        eventValue(rpgRandom.draws); eventValue(breathReserve.activity); eventValue(breathPatient.fatigue);
        eventValue(breathPatient.airClock); return nil;
    }
    return vhylAct(verb,args);
}
