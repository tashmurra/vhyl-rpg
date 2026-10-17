#include <vhyl.h>
#include <vhyl.t>
#include <vhyl-en.t>
#include <vhyl-actions.t>
#include <vhyl-dialogue.t>
#include <vhyl-rpg.t>
#include <vhyl-rpg-report.t>

/* The consumer's scalar mode omits ordinary console output. These original
 * messages supply a presentation event as well as direct-console prose. */
class SurveyMessage: Message
    body = ''
    prose(c) { return self.body; }
    say(c)
    {
        local text = self.prose(c);
        event('survey.text'); eventValue(text); "<<text>>";
        return nil;
    }
;
office: Room 'Survey Office' desc { return sayMsg('survey.office', nil); };
hatch: Fixture 'service hatch' location(office) vocab = 'hatch; service';
panel: Fixture 'maintenance panel' location(office) vocab = 'panel; maintenance'
    desc { return sayMsg('survey.panel', nil); }
;
brassKey: Thing 'brass key' location(office) vocab = 'key; brass';
keeper: Actor 'keeper' location(office) vocab = 'keeper';
surveyRecords: Topic 'survey records' vocab = 'records; survey' isFamiliar = nil;
quietMethod: Topic 'quiet release' vocab = 'release; quiet' isFamiliar = nil;

inspection: RpgSkill labelId = 'survey.inspection' attribute = rpgPerception difficulty = 1 defaultPenalty = -5;
lockWork: RpgSkill labelId = 'survey.lockwork' attribute = rpgDX difficulty = 1 defaultPenalty = -5;
negotiation: RpgSkill labelId = 'survey.negotiation' attribute = rpgIQ difficulty = 1 defaultPenalty = -5;
inspectionTraining: RpgTraining skill = inspection points = 4;
lockTraining: RpgTraining skill = lockWork points = 2;
negotiationTraining: RpgTraining skill = negotiation points = 2;
carefulEye: RpgTrait
    labelId = 'survey.careful-eye'
    modifierFor(c) { return c.skill == inspection ? 1 : 0; }
;
surveyor: RpgProfile actor = player st = 10 dx = 11 iq = 11 ht = 10
    skills = [inspectionTraining, lockTraining, negotiationTraining]
    traits = [carefulEye]
;
keeperProfile: RpgProfile actor = keeper st = 12 will = 11;
modify player rpgProfile = surveyor;
modify keeper rpgProfile = keeperProfile;

surveyState: object noise = 0 access = nil;
accessGoal: RpgChallenge id = 'records';
annotationGoal: RpgChallenge id = 'annotations';

class OfficeApproach: RpgApproach
    assessmentDisclosure = rpgFullDisclosure
    rollDisclosure = rpgFullDisclosure
    blockedReason(c) { return here() == office ? nil : 'survey.outside'; }
;
inspectPanel: OfficeApproach id = 'inspect' challenge = annotationGoal
    skill = inspection timeCost = 60
    apply(c, r)
    {
        if (r.achieved)
        {
            c.actor.setKnowsAbout(quietMethod);
            /* New preparation permits a fresh attempt at the shared goal. */
            accessGoal.advance();
        }
        return nil;
    }
;
class AccessApproach: OfficeApproach
    challenge = accessGoal
    apply(c, r)
    {
        if (r.achieved)
        { surveyState.access = true; c.actor.setKnowsAbout(surveyRecords); }
        else surveyState.noise += 1;
        return nil;
    }
;
pickHatch: AccessApproach id = 'pick' skill = lockWork
    modifier = -2 timeCost = 120 energyCost = 1
    modifierFor(c) { return c.actor.knowsAbout(quietMethod) ? 3 : 0; }
;
forceHatch: AccessApproach id = 'force' attribute = rpgST modifier = -2
    timeCost = 30 energyCost = 2 costlyMargin = 2
    apply(c, r)
    {
        inherited(c, r);
        if (r.outcome == 'costly-success') surveyState.noise += 2;
        return nil;
    }
;
persuadeKeeper: AccessApproach id = 'persuade' skill = negotiation
    assessmentDisclosure = keeperDisclosure rollDisclosure = keeperDisclosure
    opponent = keeperProfile oppositionAttribute = rpgWill timeCost = 60
;
/* The player knows their method, but not the keeper's hidden resistance. */
keeperDisclosure: RpgDisclosure visible = true
    showAbility = true showCalculation = true showCosts = true
    showAvailability = true showOutcome = true showDice = true
    estimateLabelId = 'survey.uncertain'
;
useKey: AccessApproach id = 'key' automatic = true timeCost = 5
    blockedReason(c)
    {
        local reason = inherited(c);
        if (reason != nil) return reason;
        return carried(brassKey) ? nil : 'survey.need-key';
    }
;

inspectAttempt: RpgAttempt profile = surveyor approach = inspectPanel;
pickAttempt: RpgAttempt profile = surveyor approach = pickHatch;
forceAttempt: RpgAttempt profile = surveyor approach = forceHatch;
persuadeAttempt: RpgAttempt profile = surveyor approach = persuadeKeeper;
keyAttempt: RpgAttempt profile = surveyor approach = useKey;
keeperForceAttempt: RpgAttempt profile = keeperProfile approach = forceHatch;

/* This is the single gameplay adapter used by both input paths. */
surveyAttempt(approach)
{
    local r = rpgResolve(player.rpgProfile, approach);
    rpgPublish(r);
    rpgPublishRoll(r, nil);
    if (r.status == 'blocked') sayMsg(r.reason, nil);
    else if (r.status == 'complete') sayMsg('survey.complete', nil);
    else if (r.status == 'reused') sayMsg('survey.unchanged', nil);
    else if (approach == inspectPanel)
    {
        sayMsg(r.achieved ? 'survey.annotations' : 'survey.no-annotations', nil);
    }
    else sayMsg(r.outcome == 'costly-success' ? 'survey.costly'
        : r.achieved ? 'survey.access' : r.outcome == 'tie' ? 'survey.tie' : 'survey.setback', nil);
    "\n";
    return r;
}

class SurveyAction: Action
    method = nil
    target = nil
    needsDobj = true
    check(c)
    {
        return c.dobj == target ? nil : verificationFailure('survey.wrong-target', c.dobj, nil);
    }
    exec(c) { surveyAttempt(method); return nil; }
    affordance(c)
    {
        if (c.dobj != target || !c.actor.knowsAbout(target)) return nil;
        local f = new ActionAffordance(); f.visible = true;
        f.labelId = 'survey.try'; return f;
    }
;
inspectAction: SurveyAction method = inspectPanel target = panel;
pickAction: SurveyAction method = pickHatch target = hatch;
forceAction: SurveyAction method = forceHatch target = hatch;
persuadeAction: SurveyAction method = persuadeKeeper target = keeper;
keyAction: SurveyAction method = useKey target = brassKey;
vInspect: Verb code = 100 action = inspectAction label = 'inspect';
vPick: Verb code = 101 action = pickAction label = 'pick';
vForce: Verb code = 102 action = forceAction label = 'force';
vPersuade: Verb code = 103 action = persuadeAction label = 'persuade';
vUseKey: Verb code = 104 action = keyAction label = 'use-key';
grammar command(surveyInspect): 'inspect' nounPhrase->dobj_ : Command action = inspectAction;
grammar command(surveyPick): 'pick' nounPhrase->dobj_ : Command action = pickAction;
grammar command(surveyForce): 'force' nounPhrase->dobj_ : Command action = forceAction;
grammar command(surveyPersuade): 'persuade' nounPhrase->dobj_ : Command action = persuadeAction;
grammar command(surveyKey): 'use' nounPhrase->dobj_ : Command action = keyAction;

/* Availability is observational. Optional assessments have a separate query. */
workPlan: Conversation id = 'survey-plan' target = keeper
    choices = [inspectChoice, pickChoice, forceChoice, persuadeChoice, keyChoice, leaveChoice]
;
class SurveyChoice: DialogueChoice
    method = nil
    available(c) { return !method.challenge.completed; }
    selected(c) { surveyAttempt(method); return nil; }
;
inspectChoice: SurveyChoice id = 'inspect' labelId = 'survey.inspect' method = inspectPanel;
pickChoice: SurveyChoice id = 'pick' labelId = 'survey.pick' method = pickHatch;
forceChoice: SurveyChoice id = 'force' labelId = 'survey.force' method = forceHatch;
persuadeChoice: SurveyChoice id = 'persuade' labelId = 'survey.persuade' method = persuadeKeeper;
keyChoice: SurveyChoice id = 'key' labelId = 'survey.key' method = useKey;
leaveChoice: GoodbyeChoice;

tryLabel: Message id = 'survey.try' text = 'Try this approach';
inspectLabel: Message id = 'survey.inspect' text = 'Study the fine annotations';
pickLabel: Message id = 'survey.pick' text = 'Pick the hatch lock (two minutes)';
forceLabel: Message id = 'survey.force' text = 'Force the hatch (strenuous and noisy)';
persuadeLabel: Message id = 'survey.persuade' text = 'Ask the keeper to release the records';
keyLabel: Message id = 'survey.key' text = 'Use the brass key';
officeReply: SurveyMessage id = 'survey.office'
    body = 'A service hatch protects the survey records. A keeper waits beside
        a workbench; a brass key hangs on a hook. Try EXAMINE PANEL, INSPECT
        PANEL, PICK HATCH, FORCE HATCH, USE KEY or PERSUADE KEEPER.';
panelReply: SurveyMessage id = 'survey.panel'
    body = 'The diagram plainly marks the hatch release. Its fine annotations
        might reveal a quieter method. The brass key is an ordinary alternative.';
outsideReply: SurveyMessage id = 'survey.outside' body = 'Return to the survey office first.';
needKeyReply: SurveyMessage id = 'survey.need-key' body = 'Take the brass key first.';
completeReply: SurveyMessage id = 'survey.complete' body = 'The records are already accessible.';
unchangedReply: SurveyMessage id = 'survey.unchanged' body = 'That attempt is settled. Change your approach or preparation.';
annotationReply: SurveyMessage id = 'survey.annotations' body = 'You identify a quiet release technique.';
noAnnotationReply: SurveyMessage id = 'survey.no-annotations' body = 'The fine annotations defeat you; the key remains an alternative.';
accessReply: SurveyMessage id = 'survey.access' body = 'The hatch releases. You recover the survey records.';
costlyReply: SurveyMessage id = 'survey.costly' body = 'The hatch releases with a crash. You recover the records, but draw attention.';
tieReply: SurveyMessage id = 'survey.tie' body = 'The keeper hesitates. You need a different approach.';
setbackReply: SurveyMessage id = 'survey.setback' body = 'The hatch stays closed. Your efforts attract the keeper\'s attention.';
wrongTargetReply: SurveyMessage id = 'survey.wrong-target' body = 'That approach does not apply to this object.';
energyReply: SurveyMessage id = 'insufficient-energy' body = 'You need more energy for that effort.';
trainingReply: SurveyMessage id = 'training-required' body = 'This approach needs training you do not have.';
difficultyReply: SurveyMessage id = 'too-difficult' body = 'You need a different method or better preparation.';
oppositionReply: SurveyMessage id = 'opposition-unavailable' body = 'That contest cannot take place now.';

/* Original presentation for the ordinary commands supported by this scene. */
surveyTaken: SurveyMessage priority = 10 id = 'take.ok' body = 'You take the brass key.';
surveyDropped: SurveyMessage priority = 10 id = 'drop.ok' body = 'You put down the brass key.';
surveyAlreadyHeld: SurveyMessage priority = 10 id = 'take.already' body = 'You already have that.';
surveyInventory: SurveyMessage priority = 10 id = 'inventory.some' body = 'You are carrying:';
surveyEmpty: SurveyMessage priority = 10 id = 'inventory.none' body = 'You are carrying nothing.';
surveyInventoryItem: SurveyMessage priority = 10 id = 'inventory.item'
    prose(c) { return aName(c.dobj); }
;
surveyUndo: SurveyMessage priority = 10 id = 'undo.ok' body = 'Your previous action is undone.';
surveyNoUndo: SurveyMessage priority = 10 id = 'undo.none' body = 'There is no earlier action to undo.';
surveyWait: SurveyMessage priority = 10 id = 'wait.ok' body = 'You wait for a moment.';
surveyUnknown: SurveyMessage priority = 10 id = 'parse.nomatch' body = 'Try examining the panel or using the key.';
surveyMissing: SurveyMessage priority = 10 id = 'parse.noref' body = 'Name a target for that action.';

modify gameMain initialRoom = office;
startup() { rpgRandom.seed(27); return vhylStart(); }
turn(tokens) { return vhylTurn(tokens); }
#ifndef RPG_CUSTOM_ACT
act(verb, args)
{
    if (verb == 105) return surveyAssess();
    return vhylAct(verb, args);
}
#endif

/* Example-only observational transport. No gameplay verb or history interval. */
surveyAssess()
{
    if (here() != office) return nil;
    foreach (local approach in [inspectPanel, pickHatch, forceHatch, persuadeKeeper, useKey])
        rpgPublishAssessment(rpgAssess(player.rpgProfile, approach), nil);
    return nil;
}
