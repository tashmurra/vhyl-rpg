#include <vhyl.h>
#include <vhyl.t>
#include <vhyl-en.t>
#include <vhyl-actions.t>
#include <vhyl-rpg.t>
#include <vhyl-rpg-progression.t>
#include <vhyl-rpg-lite.t>
#include <vhyl-rpg-expanded.t>
#include <vhyl-rpg-expanded-social.t>
socialRoom: Room 'Assembly';
modify gameMain initialRoom = socialRoom;
startup() { return vhylStart(); }
turn(tokens) { return vhylTurn(tokens); }
act(verb,args)
{
    if (verb == 1167)
    {
        event('test.status-reaction');
        eventValue(rpgExpandedStatusReaction(args[1],args[2],args[3] == 1,args[4] == 1,args[5] == 1));
        return nil;
    }
    if (verb == 1168)
    {
        local p = new RpgExpandedProfile(); p.rules = new RpgExpandedRules();
        local observer = new RpgExpandedProfile(); observer.rules = p.rules;
        local status = new RpgExpandedStatus(); status.id = 'standing'; status.owner = p;
        status.culture = 'local'; status.level = 3; p.contributions = [status];
        local encounter = new RpgExpandedStatusEncounter(); encounter.subject = p;
        encounter.observer = observer; encounter.culture = 'local'; encounter.recognized = true;
        event('test.status-context'); eventValue(status.amounts(p)[1]); eventValue(encounter.assess().modifier);
        encounter.recognized = nil; eventValue(encounter.assess().modifier);
        encounter.recognized = true; encounter.culture = 'foreign'; eventValue(encounter.assess().modifier);
        status.level = -2; eventValue(status.amounts(p)[1]); encounter.culture = 'local';
        eventValue(encounter.assess().modifier); return nil;
    }
    return vhylAct(verb,args);
}
