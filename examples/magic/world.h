#include <vhyl.h>
#include <vhyl.t>
#include <vhyl-en.t>
#include <vhyl-actions.t>
#include <vhyl-dialogue.t>
#include <vhyl-rpg.t>
#include <vhyl-rpg-progression.t>
#include <vhyl-rpg-lite.t>
#include <vhyl-rpg-expanded.t>
#include <vhyl-rpg-expanded-characters.t>
#include <vhyl-rpg-expanded-skills.t>
#include <vhyl-rpg-gm.t>
#include <vhyl-rpg-magic.t>

workroom: Room 'Optical workshop';
workAssistant: Actor 'workshop assistant' location(workroom) vocab = 'assistant';
workRules: RpgExpandedRules;
workTraining: RpgExpandedTraining skill = rpgMagicMatter points = 24;
lightTraining: RpgExpandedTraining skill = rpgMagicEnergy points = 24;
spaceTraining: RpgExpandedTraining skill = rpgMagicSpace points = 24;
craft: RpgExpandedSkill attribute = rpgIQ difficulty = 1 defaultPenalty = nil;
craftTraining: RpgExpandedTraining skill = craft points = 4;
worker: RpgExpandedProfile actor = player rules = workRules iq = 13
    skills = [workTraining, lightTraining, spaceTraining, craftTraining]
    contributions = [workMagic] pointBudget = 1000 disadvantageLimit = 0
;
workMagic: RpgMagicState id = 'worker-magic' owner = worker mastery = 4 channel = 2
    reserve = 2 knowledge = [matterKnowledge, energyKnowledge, spaceKnowledge]
    opportunities = [inspectOnce, inspectTwice, inspectThird, redirectOnce, relocateOnce]
;
matterKnowledge: RpgMagicKnowledge owner = workMagic domain = rpgMagicMatter rank = 1;
energyKnowledge: RpgMagicKnowledge owner = workMagic domain = rpgMagicEnergy rank = 2;
spaceKnowledge: RpgMagicKnowledge owner = workMagic domain = rpgMagicSpace rank = 4;
workScene: RpgMagicScene id = 'workroom';
workState: object material = 'bronze' knownMaterial = nil light = true lightRedirected = nil
    tokenOnTray = nil targetVisible = true applied = 0 failApplication = nil toolPresent = true
    tokenInHand = true tokenOunces = 8 lampAtLens = true trayVisible = true trayClear = true;
workPractice: RpgMagicPractice id = 'lens-and-measurement' skill = craft
    available(intent) { return workState.toolPresent ? nil : 'missing-lens'; }
;
class WorkshopEffect: RpgMagicEffect
    implemented = true
    facts(intent)
    { return [workState.targetVisible, workState.light, workState.material,
        workState.toolPresent, workState.tokenOnTray, workState.tokenInHand,
        workState.tokenOunces, workState.lampAtLens, workState.trayVisible, workState.trayClear]; }
    available(intent) { return workState.targetVisible ? nil : 'target-unseen'; }
;
inspectMaterial: WorkshopEffect id = 'inspect-material'
    requirements = [[rpgMagicMatter, 1]]
    available(intent)
    { return !workState.tokenInHand ? 'touch-required' : workState.tokenOunces > 16
        ? 'target-too-large' : inherited(intent); }
    apply(intent, result)
    {
        workState.knownMaterial = workState.material; workState.applied += 1;
        if (workState.failApplication) throw new RpgError();
    }
;
redirectLight: WorkshopEffect id = 'redirect-light'
    requirements = [[rpgMagicEnergy, 2]] minimumMargin = 2 partialMargin = 0
    available(intent) { return !workState.light ? 'no-existing-light' : !workState.lampAtLens
        ? 'light-outside-held-lens' : inherited(intent); }
    apply(intent, result)
    { workState.lightRedirected = result.outcome; workState.applied += 1; }
;
relocateToken: WorkshopEffect id = 'relocate-token'
    requirements = [[rpgMagicSpace, 4]] minimumMargin = 1
    available(intent)
    { return !workState.trayVisible || !workState.trayClear ? 'destination-unavailable'
        : workState.tokenOunces > 16 ? 'target-too-large' : inherited(intent); }
    apply(intent, result)
    { workState.tokenOnTray = true; workState.tokenInHand = nil; workState.applied += 1; }
;
inspectGoal: RpgMagicGoal id = 'identify-material' owner = workMagic;
redirectGoal: RpgMagicGoal id = 'redirect-existing-light' owner = workMagic;
relocateGoal: RpgMagicGoal id = 'move-token-to-tray' owner = workMagic;
inspectOnce: RpgMagicOpportunity id = 'inspect-1' owner = workMagic goal = inspectGoal;
inspectTwice: RpgMagicOpportunity id = 'inspect-2' owner = workMagic goal = inspectGoal ordinal = 2;
inspectThird: RpgMagicOpportunity id = 'inspect-3' owner = workMagic goal = inspectGoal ordinal = 3;
redirectOnce: RpgMagicOpportunity id = 'redirect-1' owner = workMagic goal = redirectGoal;
relocateOnce: RpgMagicOpportunity id = 'relocate-1' owner = workMagic goal = relocateGoal;
class WorkshopIntent: RpgMagicIntent
    state = workMagic scene = workScene practice = workPractice
    method = 'Use the calibrated lens to examine and redirect existing phenomena.'
    targetIds = ['token', 'lamp', 'tray']
;
inspectIntent: WorkshopIntent id = 'inspect' opportunity = inspectOnce effects = [inspectMaterial];
redirectIntent: WorkshopIntent id = 'redirect' opportunity = redirectOnce effects = [redirectLight];
relocateIntent: WorkshopIntent id = 'relocate' opportunity = relocateOnce effects = [relocateToken];
workProvider: RpgGmProvider
    propose(packet)
    {
        local r = new RpgGmProposal(); r.status = 'ruled';
        r.data = [packet[3][5][1][1], 'subtle', 0, 'Authored workshop ruling.'];
        return r;
    }
;
workLast: object result = nil gm = nil packet = nil intent = nil;
workInput: object args = [];
class WorkshopAction: Action
    exec(context)
    {
        local a = workInput.args;
        local intent = [inspectIntent, redirectIntent, relocateIntent][a[1]];
        workLast.intent = intent;
        if (a[2] == 0) workLast.result = rpgAssessMagic(intent);
        else if (a[2] == 1) workLast.gm = rpgGmResolve(intent, workProvider);
        else if (a[2] == 2) return workCast(intent);
        else if (a[2] == 3) workLast.packet = rpgGmPublishRequest(intent);
        else if (a[2] == 4)
        {
            if (intent.pending == nil || a[3] != intent.pending[2])
            { event('magic.reply-refused'); return nil; }
            workLast.gm = rpgGmSubmit(intent, intent.pending, a[4],
                a[4] == 'ruled' ? [a[5], a[6], a[7], a[8]] : []);
        }
        if (a[2] == 0) rpgPublishMagic(intent, workLast.result);
        return nil;
    }
;
workAction: WorkshopAction;
workVerb: Verb code = 700 action = workAction label = 'magic';
modify gameMain initialRoom = workroom;

/* All player input paths normalize to the same intent/opportunity. */
workCast(intent)
{
    workLast.result = rpgCastMagic(intent);
    rpgPublishMagic(intent, workLast.result); return nil;
}
class WorkshopCastAction: Action
    intent = nil
    exec(c) { return workCast(self.intent); }
;
workInspectAction: WorkshopCastAction intent = inspectIntent;
workLightAction: WorkshopCastAction intent = redirectIntent;
workMoveAction: WorkshopCastAction intent = relocateIntent;
grammar command(workInspect): 'inspect' 'material' : Command action = workInspectAction;
grammar command(workLight): 'redirect' 'light' : Command action = workLightAction;
grammar command(workMove): 'relocate' 'token' : Command action = workMoveAction;
workConversation: Conversation id = 'workshop' target = workAssistant
    choices = [workInspectChoice, workLightChoice, workMoveChoice]
;
class WorkshopChoice: DialogueChoice
    intent = nil
    selected(c) { return workCast(self.intent); }
;
workInspectChoice: WorkshopChoice id = 'inspect' labelId = 'work.inspect' intent = inspectIntent;
workLightChoice: WorkshopChoice id = 'light' labelId = 'work.light' intent = redirectIntent;
workMoveChoice: WorkshopChoice id = 'move' labelId = 'work.move' intent = relocateIntent;
workInspectLabel: Message id = 'work.inspect' text = 'Inspect the material';
workLightLabel: Message id = 'work.light' text = 'Redirect the light';
workMoveLabel: Message id = 'work.move' text = 'Relocate the token';
