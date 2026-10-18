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
    if (verb == 1170)
    {
        local rank = new RpgExpandedRank(); rank.level = args[1]; rank.replacesStatus = args[2] == 1;
        event('test.rank-table'); eventValue(rank.amounts(nil)[1]); eventValue(rank.statusBonus()); return nil;
    }
    if (verb == 1179)
    {
        local context = new RpgExpandedCombatReaction(); context.band = args[1]; context.inCombat = args[2] == 1;
        context.outnumbered = args[3] == 1; context.hopeless = args[4] == 1;
        context.escapePossible = args[5] == 1; context.visitorsRemain = args[6] == 1;
        local value = context.assess(); event('test.combat-reaction'); eventValue(value.intent);
        eventValue(value.aidModifier); eventValue(value.noQuarter ? 1 : 0); eventValue(value.leaveDemand ? 1 : 0);
        return nil;
    }
    if (verb == 1180)
    {
        event('test.combat-reaction-modifier');
        eventValue(rpgExpandedCombatReactionModifier(args[1],args[2] == 1,args[3] == 1)); return nil;
    }
    return vhylAct(verb,args);
}
