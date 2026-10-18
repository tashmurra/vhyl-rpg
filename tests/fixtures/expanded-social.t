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
    if (verb == 1181)
    {
        local request = new RpgExpandedAidReaction(); request.band = args[1]; request.simple = args[2] == 1;
        request.reasonableness = args[3]; local value = request.assess();
        event('test.aid-reaction'); eventValue(value.granted ? 1 : 0); eventValue(value.extent);
        eventValue(value.advice ? 1 : 0); eventValue(value.volunteerInformation ? 1 : 0);
        eventValue(value.combatFollowup ? 1 : 0); eventValue(value.followupModifier); eventValue(value.followupBestBand);
        eventValue(value.retry ? 1 : 0); eventValue(value.retryModifier); return nil;
    }
    if (verb == 1182)
    {
        local context = new RpgExpandedAidModifiers(); event('test.aid-modifiers');
        eventValue(context.assess().modifier); context.verySimple = true; eventValue(context.assess().modifier);
        context.verySimple = nil; context.complexity = -3; context.inconvenience = true;
        context.standingRisk = -2; context.physicalRisk = -1; eventValue(context.assess().modifier);
        return nil;
    }
    if (verb == 1183)
    {
        local query = new RpgExpandedInformationReaction(); query.band = args[1]; query.complexity = args[2];
        query.adverseChoice = args[3]; query.paymentReceived = args[4] == 1; query.bribeOffered = args[5] == 1;
        query.knowledgeIncomplete = true; query.offersHelp = true;
        local value = query.assess(); event('test.information-reaction'); eventValue(value.status);
        eventValue(value.reason); eventValue(value.answer); eventValue(value.related ? 1 : 0);
        eventValue(value.research ? 1 : 0); eventValue(value.combatFollowup ? 1 : 0);
        eventValue(value.followupModifier); eventValue(value.retry ? 1 : 0);
        eventValue(value.aidFollowup ? 1 : 0); eventValue(value.aidModifier); eventValue(value.aidWorstBand); return nil;
    }
    if (verb == 1184)
    {
        local context = new RpgExpandedInformationModifiers(); context.bribeScale = args[1];
        context.discreet = true; context.appropriate = true;
        event('test.information-modifiers'); eventValue(context.assess().modifier);
        context.complexity = 2; context.intrusive = true; context.danger = -3; context.knowledgeProfessionBonus = 2;
        eventValue(context.assess().modifier); context.discreet = nil; eventValue(context.assess().reason); return nil;
    }
    if (verb == 1192)
    {
        local trade = new RpgExpandedTradeReaction(); trade.band = args[1]; trade.direction = args[2];
        trade.fairPrice = args[3]; trade.offeredPrice = args[4];
        local value = trade.assess(); event('test.trade-price'); eventValue(value.status); eventValue(value.reason);
        eventValue(value.price); eventValue(value.refused ? 1 : 0); eventValue(value.followupModifier);
        eventValue(value.offersAdvice ? 1 : 0); return nil;
    }
    if (verb == 1193)
    {
        event('test.trade-limits');
        try { rpgExpandedTradeFraction(100,1,3); eventValue('unexpected-success'); }
        catch (RpgExpandedError error) { eventValue(error.reason); }
        try { rpgExpandedTradeFraction(1000000000,3,1); eventValue('unexpected-success'); }
        catch (RpgExpandedError error) { eventValue(error.reason); }
        eventValue(rpgExpandedTradeFraction(2147483640,1,2)); return nil;
    }
    return vhylAct(verb,args);
}
