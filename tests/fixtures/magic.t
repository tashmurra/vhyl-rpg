#include "../../examples/magic/world.h"
testInput: object args = [];
testProvider: RpgGmAuthoredProvider data = ['inspect-material', 'subtle', 0, 'Test ruling.'];
testTool: RpgMagicTool owner = workMagic domain = rpgMagicMatter designated = true bound = true
    available(intent) { return workState.toolPresent; }
;
testFormula: RpgMagicFormula owner = workMagic effect = inspectMaterial improvement = 3;
testPreparation: RpgMagicPreparation intent = inspectIntent skill = craft seconds = 2
    available() { return nil; }
;
testPurchase: RpgMagicPurchase id = 'restore-matter' state = workMagic kind = 'restore'
    knowledge = matterKnowledge target = 1 unlocked = true;
testWitness: RpgMagicWitness id = 'observer' present = true perceives = true;
testLast: object other = nil held = nil injury = 0 lasting = 0 received = 0;
testConsequence: RpgMagicConsequence id = 'authored-test' band = 4
    available(state, backlash) { return nil; }
    apply(state, backlash, injury, lasting)
    { testLast.injury += injury; testLast.lasting += lasting; }
;
class MagicTestAction: Action
    exec(context)
    {
        local a = testInput.args; local op = a[1]; local q = inspectIntent;
        if (op == 1) rpgRandom.seed(a[2]);
        else if (op == 2)
        { testProvider.data = ['inspect-material', a[2], a[3], 'Test ruling.']; workLast.gm = rpgGmResolve(q, testProvider); }
        else if (op == 3) { q.reserveSpend = a[2]; q.extraTime = a[3] != 0; q.familiarity = a[4]; }
        else if (op == 4) { workLast.result = rpgCastMagic(q); testLast.other = rpgCastMagic(q); }
        else if (op == 5) { workState.material = a[2]; }
        else if (op == 6) workLast.packet = rpgGmAsk(q);
        else if (op == 7) workLast.gm = rpgGmSubmit(q, workLast.packet, 'ruled', [a[2],a[3],a[4],'External.']);
        else if (op == 8) { workState.failApplication = true; }
        else if (op == 9) { workMagic.mastery = a[2]; matterKnowledge.rank = a[3]; matterKnowledge.access = a[4]; }
        else if (op == 10) { inspectMaterial.minimumMargin = a[2]; }
        else if (op == 11) { q.opportunity = [inspectOnce,inspectTwice,inspectThird][a[2]]; q.revision += 1; }
        else if (op == 12) inspectGoal.reopen();
        else if (op == 13) rpgMagicAddStrain(workMagic, a[2]);
        else if (op == 14) workMagic.lasting = a[2];
        else if (op == 15) testLast.other = rpgMagicDischarge(workMagic);
        else if (op == 16) { q.formula = testFormula; workMagic.formulas = [testFormula]; }
        else if (op == 17) workLast.result = rpgPrepareMagic(testPreparation);
        else if (op == 18) { workMagic.tool = testTool; workState.toolPresent = a[2] != 0; }
        else if (op == 19) { worker.developmentOpen = true; worker.unspentPoints = 100; workLast.result = rpgBuyMagic(testPurchase); }
        else if (op == 20) { workScene.witnesses = [testWitness]; testWitness.present = a[2] != 0; }
        else if (op == 21) { q.conspicuous = true; workScene.coincidences = a[2]; }
        else if (op == 22)
        { workLast.result = rpgCastMagic(inspectIntent); testLast.other = rpgCastMagic(redirectIntent); }
        else if (op == 23) workLast.packet = rpgGmPublishRequest(q);
        else if (op == 24) { testLast.held = workLast.packet; workState.material = 'copper'; workLast.packet = rpgGmAsk(q); }
        else if (op == 25) workLast.gm = rpgGmSubmit(q, testLast.held, 'ruled', testProvider.data);
        else if (op == 26) { q.practice = nil; }
        else if (op == 27) { matterKnowledge.exempt = true; }
        else if (op == 28) { inspectMaterial.implemented = nil; }
        else if (op == 29) { inspectMaterial.duration = 30; }
        else if (op == 30) { inspectMaterial.requirements = [[rpgMagicMatter,1],[rpgMagicEnergy,2]]; }
        else if (op == 31) workLast.gm = rpgGmSubmit(q, workLast.packet, a[2], []);
        else if (op == 32) testLast.received = rpgMagicReceive(workMagic, a[2]);
        else if (op == 33) workLast.result = rpgResolveMagicBacklash(workMagic, testConsequence);
        else if (op == 34) testConsequence.band = a[2];
        else if (op == 35) workMagic.reserve = 0;
        else if (op == 36) workState.tokenInHand = nil;
        else if (op == 37) workState.tokenOunces = a[2];
        return nil;
    }
;
modify worker
    afterAttempt(c, r)
    {
        if (c.profile != self || r.profile != self || r.approach != c.approach
            || r.kind != 'magic' || r.status != 'resolved'
            || !holds(['success', 'setback', 'complication'], r.outcome)) throw new RpgError();
        return nil;
    }
;
testAction: MagicTestAction;
testVerb: Verb code = 710 action = testAction label = 'test-magic';
startup() { return vhylStart(); }
turn(tokens) { return vhylTurn(tokens); }
act(verb, args)
{
    if (verb == 700) { workInput.args = args; return vhylAct(700, []); }
    if (verb == 710) { testInput.args = args; return vhylAct(710, []); }
    if (verb == 990)
    {
        event('test.magic-state'); eventValue(workMagic.reserve); eventValue(workMagic.strain);
        eventValue(workMagic.lasting); eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds);
        eventValue(inspectGoal.attempts); eventValue(inspectGoal.ended); eventValue(inspectGoal.completed);
        eventValue(workState.knownMaterial); eventValue(workState.applied); eventValue(worker.unspentPoints);
        eventValue(matterKnowledge.access); eventValue(matterKnowledge.restorationPaid);
        eventValue(workMagic.pendingBacklash == nil ? 0 : workMagic.pendingBacklash.strength);
        return nil;
    }
    if (verb == 991)
    {
        local r = rpgAssessMagic(inspectIntent);
        event('test.magic-assess'); eventValue(r.status); eventValue(r.reason); eventValue(r.score);
        eventValue(r.spent); eventValue(r.seconds); eventValue(r.outcome); return nil;
    }
    if (verb == 992)
    {
        local r = workLast.result;
        event('test.magic-result'); eventValue(r.status); eventValue(r.reason);
        eventValue(r.score); eventValue(r.check == nil ? nil : r.check.roll);
        eventValue(r.check == nil ? nil : r.check.critical); eventValue(r.outcome);
        eventValue(r.delivered); eventValue(r.spent); eventValue(r.seconds); eventValue(r.strainGained);
        return nil;
    }
    if (verb == 993)
    {
        local r = workLast.gm;
        event('test.gm-result'); eventValue(r.status); eventValue(r.reason); return nil;
    }
    if (verb == 994)
    {
        event('test.magic-other'); eventValue(testLast.other.status); eventValue(testLast.other.reason); return nil;
    }
    if (verb == 995)
    {
        event('test.magic-costs');
        for (local i = 1; i <= 5; i++) eventValue(rpgMagicRestorationCost(i, true));
        eventValue(rpgMagicMasteryCost(8)); eventValue(rpgMagicFormulaCost(3));
        eventValue(rpgMagicBlastInjury(12,1,0,3));
        eventValue(rpgExpandedCharacterCost(worker,nil)); return nil;
    }
    if (verb == 996)
    {
        event('test.magic-resource'); eventValue(testLast.injury); eventValue(testLast.lasting);
        eventValue(testLast.received); eventValue(rpgMagicTransferable(workMagic));
        return nil;
    }
    return vhylAct(verb,args);
}
