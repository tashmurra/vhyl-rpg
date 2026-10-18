#include <vhyl.h>
#include <vhyl.t>
#include <vhyl-en.t>
#include <vhyl-actions.t>
#include <vhyl-rpg.t>
#include <vhyl-rpg-progression.t>
#include <vhyl-rpg-lite.t>
#include <vhyl-rpg-expanded.t>
#include <vhyl-rpg-expanded-equipment.t>
#include <vhyl-rpg-expanded-technology.t>
computerRoom: Room 'Control Room';
computerItem: RpgLiteItem;
computerHost: RpgExpandedComputer item = computerItem complexity = 2 powered = true
    copies = [computerFull,computerSmall,computerLarge];
computerFull: RpgExpandedSoftwareCopy id = 'full' host = computerHost complexity = 2 approved = true evidence = 'Installed copy';
computerSmall: RpgExpandedSoftwareCopy id = 'small' host = computerHost complexity = 1 approved = true evidence = 'Installed copy';
computerLarge: RpgExpandedSoftwareCopy id = 'large' host = computerHost complexity = 3 approved = true evidence = 'Installed copy';
computerRun: RpgExpandedProgramRun id = 'primary' host = computerHost copy = computerFull;
computerNext: RpgExpandedProgramRun id = 'next' host = computerHost copy = computerFull;
computerInput: object code = 0;
class ComputerAction: Action
    exec(context)
    {
        local code = computerInput.code;
        if (code == 3 || code == 4)
        {
            event('test.computer-stop'); eventValue(computerRun.stop());
            if (code == 4) throw new RpgError(); return nil;
        }
        if (code == 5)
        {
            for (local index = 1; index <= 10; index += 1)
            {
                local process = new RpgExpandedProgramRun(); process.id = index;
                process.host = computerHost; process.copy = computerSmall; process.start();
            }
            return nil;
        }
        if (code == 6) computerNext.copy = computerSmall;
        if (code == 7) computerNext.copy = computerLarge;
        if (code == 8) computerHost.powered = nil;
        if (code == 9) computerRun.id = 'changed';
        local request = code == 6 || code == 7 || code == 10 ? computerNext : computerRun;
        local value = code == 2 ? request.assess() : request.start();
        event('test.computer-operation'); eventValue(value.status); eventValue(value.reason);
        if (code == 1) throw new RpgError(); return nil;
    }
;
computerAction: ComputerAction;
computerVerb: Verb code = 2080 action = computerAction label = 'program';
modify gameMain initialRoom = computerRoom;
startup() { return vhylStart(); }
turn(tokens) { return vhylTurn(tokens); }
act(verb,args)
{
    if (verb == 2080) { computerInput.code = args[1]; return vhylAct(verb,args); }
    if (verb == 2081)
    {
        event('test.computer-state'); eventValue(computerHost.used()); eventValue(computerHost.capacity());
        eventValue(computerHost.runs.length()); eventValue(computerRun.active ? 1 : 0);
        eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
    }
    return vhylAct(verb,args);
}
