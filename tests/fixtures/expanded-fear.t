#include <vhyl.h>
#include <vhyl.t>
#include <vhyl-en.t>
#include <vhyl-actions.t>
#include <vhyl-rpg.t>
#include <vhyl-rpg-progression.t>
#include <vhyl-rpg-lite.t>
#include <vhyl-rpg-expanded.t>
#include <vhyl-rpg-expanded-health.t>
fearRoom: Room 'Echo Chamber';
fearProfile: RpgExpandedProfile;
fearContext: RpgExpandedFearContext profile = fearProfile approved = true evidence = 'An extraordinary apparition';
fearEpisode: RpgExpandedFearStun id = 'apparition' context = fearContext approved = true evidence = 'Recorded table outcome';
fearRecovery: RpgExpandedFearStunRecovery id = 'first-recovery' episode = fearEpisode;
fearSecondRecovery: RpgExpandedFearStunRecovery id = 'second-recovery' episode = fearEpisode;
fearInput: object code = 0 row = 4;
class FearTestAction: Action
    exec(context)
    {
        local code = fearInput.code;
        if (code <= 2)
        {
            fearEpisode.tableTotal = fearInput.row;
            local value = code == 1 ? fearEpisode.assess() : fearEpisode.apply();
            event('test.fear-start'); eventValue(value.status); eventValue(value.reason);
            if (code == 2) throw new RpgError(); return nil;
        }
        if (code == 3) { rpgSpendTime(1); return nil; }
        if (code == 4) { rpgLiteRecoverStun(fearProfile); return nil; }
        if (code == 8) { fearProfile.willAdjustment = 10; return nil; }
        if (code == 9) { fearContext.isolated = true; return nil; }
        if (code == 10) { fearContext.isolated = nil; return nil; }
        if (code == 11) { fearProfile.willAdjustment = -7; return nil; }
        if (code == 12)
        {
            local retry = fearSecondRecovery.apply();
            event('test.fear-recovery'); eventValue(retry.status); eventValue(retry.reason);
            eventValue(retry.check == nil ? nil : retry.check.score);
            return nil;
        }
        local value = code == 6 ? fearRecovery.assess() : fearRecovery.apply();
        event('test.fear-recovery'); eventValue(value.status); eventValue(value.reason);
        eventValue(value.check == nil ? nil : value.check.score);
        if (code == 7) throw new RpgError(); return nil;
    }
;
fearAction: FearTestAction;
fearVerb: Verb code = 2250 action = fearAction label = 'fear operation';
modify gameMain initialRoom = fearRoom;
startup() { rpgRandom.seed(1); return vhylStart(); }
turn(tokens) { return vhylTurn(tokens); }
act(verb,args)
{
    if (verb == 2250) { fearInput.code = args[1]; fearInput.row = args[2]; return vhylAct(verb,args); }
    if (verb == 2251)
    {
        event('test.fear-state'); eventValue(fearProfile.mentalStun ? 1 : 0); eventValue(fearEpisode.completed ? 1 : 0);
        eventValue(fearEpisode.initialEnd); eventValue(fearEpisode.recoveries.length());
        eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
    }
    return nil;
}
