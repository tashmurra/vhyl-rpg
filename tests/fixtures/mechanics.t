/* Original fixtures for numeric rules and observable gameplay contracts. */
#define RPG_CUSTOM_ACT 1
#include "../../examples/hybrid/main.t"

fixtureState: object effects = 0 prepared = nil alarm = 0;
sampleGoal: RpgChallenge id = 'sample';
costlyGoal: RpgChallenge id = 'costly';
automaticGoal: RpgChallenge id = 'automatic';
contestGoal: RpgChallenge id = 'contest';
lostGoal: RpgChallenge id = 'lost';
failedGoal: RpgChallenge id = 'both-failed';
tiedGoal: RpgChallenge id = 'tied';
blockedGoal: RpgChallenge id = 'blocked';
exceptionGoal: RpgChallenge id = 'exception';
untrained: RpgSkill defaultPenalty = nil;
defaultSkill: RpgSkill labelId = 'test.default-skill' defaultPenalty = -5;
defaultGoal: RpgChallenge id = 'default';

class FixtureApproach: RpgApproach
    assessmentDisclosure = rpgFullDisclosure rollDisclosure = rpgFullDisclosure
    attribute = rpgST modifier = -5 timeCost = 30 energyCost = 1
    apply(c, r)
    {
        fixtureState.effects += 1;
        if (r.outcome == 'costly-success') fixtureState.alarm += 2;
        return nil;
    }
;
sample: FixtureApproach id = 'sample' challenge = sampleGoal
    modifierFor(c) { return fixtureState.prepared ? 3 : 0; }
;
costly: FixtureApproach id = 'costly' challenge = costlyGoal costlyMargin = 2;
automatic: FixtureApproach id = 'automatic' challenge = automaticGoal automatic = true;
contest: FixtureApproach id = 'contest' challenge = contestGoal modifier = 1
    opponent = keeperProfile oppositionAttribute = rpgWill;
lost: FixtureApproach id = 'lost' challenge = lostGoal
    opponent = keeperProfile oppositionAttribute = rpgWill;
bothFailed: FixtureApproach id = 'both-failed' challenge = failedGoal
    opponent = keeperProfile oppositionAttribute = rpgST oppositionModifier = -9;
tied: FixtureApproach id = 'tied' challenge = tiedGoal modifier = 0
    opponent = keeperProfile oppositionAttribute = rpgWill;
noTraining: FixtureApproach id = 'untrained' challenge = blockedGoal skill = untrained;
tooHard: FixtureApproach id = 'hard' challenge = blockedGoal modifier = -8;
tooTiring: FixtureApproach id = 'tiring' challenge = blockedGoal energyCost = 11;
noTools: FixtureApproach id = 'tools' challenge = blockedGoal
    blockedReason(c) { return 'test.no-tools'; }
;
throwing: FixtureApproach id = 'throwing' challenge = exceptionGoal
    apply(c, r) { fixtureState.effects += 1; throw new RpgError(); }
;
missing: FixtureApproach id = 'missing' challenge = exceptionGoal;

minimalDisclosure: RpgDisclosure visible = true showAbility = true;
noDisclosure: RpgDisclosure;
hiddenOpposition: RpgDisclosure visible = true
    showAbility = true showCalculation = true showChance = true showCosts = true
    showAvailability = true showDice = true showOutcome = true
    estimateLabelId = 'test.uncertain'
;
hiddenGoal: RpgChallenge id = 'hidden';
minimalGoal: RpgChallenge id = 'minimal';
hiddenOppositionGoal: RpgChallenge id = 'hidden-opposition';
hidden: RpgApproach id = 'hidden' challenge = hiddenGoal attribute = rpgST;
minimal: FixtureApproach id = 'minimal' challenge = minimalGoal
    assessmentDisclosure = minimalDisclosure rollDisclosure = minimalDisclosure;
oppositionHidden: FixtureApproach id = 'hidden-opposition' challenge = hiddenOppositionGoal
    opponent = keeperProfile assessmentDisclosure = hiddenOpposition rollDisclosure = hiddenOpposition;
defaultMethod: FixtureApproach id = 'default' challenge = defaultGoal skill = defaultSkill modifier = 0;

sampleSlot: RpgAttempt profile = surveyor approach = sample;
sampleNpcSlot: RpgAttempt profile = keeperProfile approach = sample;
costlySlot: RpgAttempt profile = surveyor approach = costly;
automaticSlot: RpgAttempt profile = surveyor approach = automatic;
contestSlot: RpgAttempt profile = surveyor approach = contest;
lostSlot: RpgAttempt profile = surveyor approach = lost;
bothFailedSlot: RpgAttempt profile = surveyor approach = bothFailed;
tiedSlot: RpgAttempt profile = surveyor approach = tied;
untrainedSlot: RpgAttempt profile = surveyor approach = noTraining;
hardSlot: RpgAttempt profile = surveyor approach = tooHard;
tiringSlot: RpgAttempt profile = surveyor approach = tooTiring;
toolsSlot: RpgAttempt profile = surveyor approach = noTools;
throwingSlot: RpgAttempt profile = surveyor approach = throwing;
hiddenSlot: RpgAttempt profile = surveyor approach = hidden;
minimalSlot: RpgAttempt profile = surveyor approach = minimal;
oppositionHiddenSlot: RpgAttempt profile = surveyor approach = oppositionHidden;
defaultSlot: RpgAttempt profile = surveyor approach = defaultMethod;

fixtureAttempt(method, profile)
{
    local r = rpgResolve(profile, method);
    rpgPublish(r);
    event('test.result');
    eventValue(r.status); eventValue(r.outcome); eventValue(r.achieved);
    eventValue(r.score); eventValue(r.roll); eventValue(r.margin); eventValue(r.critical);
    eventValue(r.oppositionScore); eventValue(r.oppositionRoll);
    eventValue(r.oppositionMargin); eventValue(r.oppositionCritical);
    eventValue(r.reason); eventValue(r.timeSpent); eventValue(r.energySpent);
    return nil;
}

class FixtureAction: Action
    method = nil
    profile = surveyor
    exec(c) { return fixtureAttempt(method, profile); }
;
sampleAction: FixtureAction method = sample;
costlyAction: FixtureAction method = costly;
automaticAction: FixtureAction method = automatic;
contestAction: FixtureAction method = contest;
lostAction: FixtureAction method = lost;
bothFailedAction: FixtureAction method = bothFailed;
tiedAction: FixtureAction method = tied;
untrainedAction: FixtureAction method = noTraining;
hardAction: FixtureAction method = tooHard;
tiringAction: FixtureAction method = tooTiring;
toolsAction: FixtureAction method = noTools;
throwingAction: FixtureAction method = throwing;
missingAction: FixtureAction method = missing;
npcAction: FixtureAction method = sample profile = keeperProfile;
hiddenAction: FixtureAction method = hidden;
minimalAction: FixtureAction method = minimal;
oppositionHiddenAction: FixtureAction method = oppositionHidden;
defaultAction: FixtureAction method = defaultMethod;
changeRatingsAction: Action
    exec(c)
    {
        surveyor.st = 19; keeperProfile.will = 18;
        sample.modifier = 4; contest.modifier = 7;
        sample.timeCost = 90; sample.energyCost = 7;
        inspection.labelId = 'test.changed-inspection'; inspectionTraining.points = 16;
        return nil;
    }
;
prepareAction: Action
    exec(c)
    {
        if (!fixtureState.prepared)
        { fixtureState.prepared = true; sampleGoal.advance(); }
        return nil;
    }
;
vSample: Verb code = 200 action = sampleAction label = 'sample';
vPrepare: Verb code = 201 action = prepareAction label = 'prepare';
vCostly: Verb code = 202 action = costlyAction label = 'costly';
vAutomatic: Verb code = 203 action = automaticAction label = 'automatic';
vContest: Verb code = 204 action = contestAction label = 'contest';
vLost: Verb code = 205 action = lostAction label = 'lost';
vBothFailed: Verb code = 206 action = bothFailedAction label = 'both-failed';
vTied: Verb code = 207 action = tiedAction label = 'tied';
vUntrained: Verb code = 208 action = untrainedAction label = 'untrained';
vHard: Verb code = 209 action = hardAction label = 'hard';
vTiring: Verb code = 210 action = tiringAction label = 'tiring';
vTools: Verb code = 211 action = toolsAction label = 'tools';
vThrowing: Verb code = 212 action = throwingAction label = 'throwing';
vMissing: Verb code = 213 action = missingAction label = 'missing';
vNpc: Verb code = 214 action = npcAction label = 'npc';
vHidden: Verb code = 215 action = hiddenAction label = 'hidden';
vMinimal: Verb code = 216 action = minimalAction label = 'minimal';
vHiddenOpposition: Verb code = 217 action = oppositionHiddenAction label = 'hidden-opposition';
vChangeRatings: Verb code = 218 action = changeRatingsAction label = 'change-ratings';
vDefault: Verb code = 219 action = defaultAction label = 'default';
grammar command(sampleTest): 'attempt' : Command action = sampleAction;
grammar command(prepareTest): 'prepare' : Command action = prepareAction;

sampleChoice: DialogueChoice id = 'sample' labelId = 'survey.try'
    selected(c) { return fixtureAttempt(sample, surveyor); }
;
testConversation: Conversation id = 'test-plan' target = keeper choices = [sampleChoice];

act(verb, args)
{
    if (verb == 105) return surveyAssess();
    if (verb == 900)
    {
        event('test.state');
        eventValue(turnCount.value); eventValue(undoDepth());
        eventValue(rpgRandom.state); eventValue(rpgRandom.draws);
        eventValue(surveyor.energy); eventValue(rpgLedger.seconds);
        eventValue(accessGoal.completed); eventValue(annotationGoal.completed);
        eventValue(accessGoal.revision); eventValue(surveyState.noise);
        eventValue(surveyState.access); eventValue(player.knowsAbout(quietMethod));
        eventValue(player.knowsAbout(surveyRecords));
        eventValue(fixtureState.effects); eventValue(fixtureState.prepared);
        eventValue(fixtureState.alarm); eventValue(sampleSlot.revision);
        eventValue(sampleGoal.completed); eventValue(sampleGoal.revision);
        eventValue(keeperProfile.energy);
        return nil;
    }
    if (verb == 901)
    {
        for (local roll = 3; roll <= 18; roll += 1)
        {
            local r = rpgCheck(args[1], roll);
            event('test.check'); eventValue(args[1]); eventValue(roll);
            eventValue(r.status); eventValue(r.achieved); eventValue(r.critical);
            eventValue(r.outcome); eventValue(r.margin); eventValue(r.reason);
        }
        return nil;
    }
    if (verb == 902)
    {
        local p = new RpgProfile(); p.dx = args[1];
        local skill = new RpgSkill(); skill.attribute = rpgDX;
        skill.difficulty = args[2]; skill.defaultPenalty = args[4] == 999 ? nil : args[4];
        if (args[3] > 0)
        {
            local training = new RpgTraining(); training.skill = skill;
            training.points = args[3]; p.skills = [training];
        }
        event('test.skill'); eventValue(p.skillScore(skill)); return nil;
    }
    if (verb == 903)
    {
        event('test.entities'); eventValue(panel); eventValue(hatch);
        eventValue(brassKey); eventValue(keeper); return nil;
    }
    if (verb == 904)
    {
        rpgRandom.seed(args[1]);
        for (local i = 0; i < 12; i += 1)
        {
            local die = rpgRandom.die();
            event('test.random'); eventValue(die); eventValue(rpgRandom.state);
        }
        return nil;
    }
    if (verb == 905)
    {
        local value = new RpgAssessment(); value.status = 'ready';
        value.kind = args[4] == 1 ? 'automatic' : args[2] > 0 ? 'contest' : 'check';
        value.costlyMargin = args[3];
        local calculation = new RpgCalculation(); calculation.effectiveScore = args[1];
        value.calculation = calculation;
        if (args[2] > 0)
        {
            local opposition = new RpgCalculation(); opposition.effectiveScore = args[2];
            value.oppositionCalculation = opposition;
        }
        local odds = rpgOddsFor(value);
        event('test.odds'); eventValue(odds.total); eventValue(odds.achieved);
        eventValue(odds.success); eventValue(odds.costlySuccess); eventValue(odds.setback);
        eventValue(odds.complication); eventValue(odds.tie); eventValue(odds.rollSuccess);
        eventValue(odds.criticalSuccess); eventValue(odds.criticalFailure);
        eventValue(odds.chanceBasisPoints()); return nil;
    }
    if (verb == 906 || verb == 907)
    {
        local methods = [sample, costly, automatic, contest, lost, bothFailed,
            tied, noTraining, tooHard, tooTiring, noTools, hidden, minimal, oppositionHidden,
            inspectPanel, pickHatch, defaultMethod];
        local method = methods[args[1]];
        local preferences = args[2] == 0 ? nil
            : args[2] == 1 ? rpgFullDisclosure : args[2] == 2 ? minimalDisclosure : noDisclosure;
        if (verb == 906)
        {
            local value = rpgAssess(surveyor, method);
            event('test.assessment'); eventValue(value.status); eventValue(value.reason);
            eventValue(value.kind); eventValue(value.odds == nil ? nil : value.odds.achieved);
            rpgPublishAssessment(value, preferences);
        }
        else
        {
            local value = rpgRecordedResult(surveyor, method);
            if (value != nil) rpgPublishRoll(value, preferences);
        }
        return nil;
    }
    return vhylAct(verb, args);
}
