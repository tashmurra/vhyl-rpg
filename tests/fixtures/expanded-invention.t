#include <vhyl.h>
#include <vhyl.t>
#include <vhyl-en.t>
#include <vhyl-actions.t>
#include <vhyl-rpg.t>
#include <vhyl-rpg-progression.t>
#include <vhyl-rpg-lite.t>
#include <vhyl-rpg-expanded.t>
#include <vhyl-rpg-expanded-equipment.t>
#include <vhyl-rpg-expanded-health.t>
#include <vhyl-rpg-expanded-technology.t>
inventionRoom: Room 'Design Office';
conceptRules: RpgExpandedRules scaledInjuryShock = true;
conceptUser: RpgExpandedProfile rules = conceptRules money = 1000000 techLevel = 8 skills = [conceptTraining];
conceptSkill: RpgLiteSkill id = 'engineer' attribute = rpgIQ difficulty = 2;
conceptTraining: RpgTraining skill = conceptSkill points = 24;
conceptProposal: RpgExpandedInventionProposal inventor = conceptUser skill = conceptSkill
    description = 'Survey tool' mechanism = 'Optical measurement' evidence = 'Feasible design' approved = true
    techLevel = 8 category = 'average' retailPrice = 1000;
conceptProject: RpgExpandedInventionProject proposal = conceptProposal;
conceptOtherProject: RpgExpandedInventionProject proposal = conceptProposal;
conceptAttempt: RpgExpandedInventionConcept id = 'first' project = conceptProject evidence = 'Independent design';
conceptRetry: RpgExpandedInventionConcept id = 'retry' project = conceptProject knowledge = 'model' evidence = 'Model acquired';
conceptOther: RpgExpandedInventionConcept id = 'other-project' project = conceptOtherProject evidence = 'Another proposal';
conceptFacilities: RpgExpandedInventionFacilities project = conceptProject payer = conceptUser approved = true evidence = 'Fund inventor laboratory';
conceptReplacement: RpgExpandedInventionFacilities project = conceptProject payer = conceptUser approved = true evidence = 'Rebuild laboratory';
conceptBlueprint: RpgExpandedInventionBlueprint project = conceptProject reference = 'survey-design-drawings'
    acquired = true actualDesign = true approved = true evidence = 'Complete acquired construction drawings';
prototypeStart: RpgExpandedPrototypeStart id = 'prototype-one' project = conceptProject payer = conceptUser
    approved = true evidence = 'Fund one attempt with the inventor working alone';
prototypeSecond: RpgExpandedPrototypeStart id = 'prototype-two' project = conceptProject payer = conceptUser
    approved = true evidence = 'Second attempt';
prototypeWork: RpgExpandedPrototypeWork id = 'first-day' attempt = prototypeStart seconds = 86400
    approved = true uninterrupted = true evidence = 'Team and laboratory available for the interval';
prototypeClockFault: object enabled = nil;
modify rpgLedger
    afterAdvance(previousSeconds)
    {
        inherited(previousSeconds);
        if (prototypeClockFault.enabled) conceptUser.unconscious = true;
    }
;
prototypeAccidentTarget: RpgExpandedPrototypeAccidentTarget id = 'lab-accident-wound' profile = conceptUser destination = 'laboratory-floor';
prototypeAccident: RpgExpandedPrototypeAccident attempt = prototypeStart targets = [prototypeAccidentTarget]
    approved = true evidence = 'Crushing machinery accident; torso protection assessed';
prototypeProduct: RpgLiteItem id = 'survey-prototype' cost = 1000 weight = 100;
prototypeCompletion: RpgExpandedPrototypeCompletion attempt = prototypeStart recipient = conceptUser item = prototypeProduct
    accident = prototypeAccident approved = true evidence = 'Completed optical design and specified accident consequences';
prototypeMajor: RpgExpandedPrototypeDefect id = 'jam' severity = 'major' effect = 'operation-block' evidence = 'Mechanism can jam';
prototypeMinor1: RpgExpandedPrototypeDefect id = 'blur' severity = 'minor' effect = 'operation-penalty' penalty = 2 evidence = 'Optical blur';
prototypeMinor2: RpgExpandedPrototypeDefect id = 'drift' severity = 'minor' effect = 'operation-penalty' penalty = 1 evidence = 'Calibration drift';
prototypeMinor3: RpgExpandedPrototypeDefect id = 'glare' severity = 'minor' effect = 'operation-penalty' penalty = 1 evidence = 'Glare';
prototypeMinor4: RpgExpandedPrototypeDefect id = 'vibration' severity = 'minor' effect = 'operation-penalty' penalty = 1 evidence = 'Vibration';
prototypeMinor5: RpgExpandedPrototypeDefect id = 'readout' severity = 'minor' effect = 'operation-penalty' penalty = 1 evidence = 'Unstable readout';
prototypeDefects: RpgExpandedPrototypeDefectSet completion = prototypeCompletion
    defects = [prototypeMajor,prototypeMinor1,prototypeMinor2,prototypeMinor3,prototypeMinor4,prototypeMinor5]
    approved = true evidence = 'Complete set of executable optical prototype faults';
prototypeOperation: RpgLiteContext skill = conceptSkill prototypeItem = prototypeProduct;
prototypeUse: RpgExpandedPrototypeOperation id = 'survey-use' profile = conceptUser item = prototypeProduct skill = conceptSkill
    modifier = -10 seconds = 60 marginDefect = prototypeMinor1 criticalDefect = prototypeMajor
    approved = true uninterrupted = true evidence = 'One difficult survey observation with authored fault choices';
prototypeTest: RpgExpandedPrototypeTest id = 'first-test-week' profile = conceptUser item = prototypeProduct skill = conceptSkill
    discoveryDefect = prototypeMinor1 failureDefect = prototypeMajor approved = true uninterrupted = true
    evidence = 'Full week of suitable operation testing';
prototypeLine: RpgExpandedProductionLine id = 'survey-line' project = conceptProject payer = conceptUser
    approved = true available = true permitted = true evidence = 'Available authorized production equipment';
productionCopy: RpgLiteItem id = 'survey-copy' cost = 1000 weight = 100;
productionOrder: RpgExpandedProductionOrder id = 'copy-one' project = conceptProject payer = conceptUser recipient = conceptUser
    worker = conceptUser item = productionCopy approved = true available = true permitted = true uninterrupted = true
    evidence = 'One matching physical copy with supplied parts and available work';
conceptInput: object code = 0;
class InventionConceptAction: Action
    exec(context)
    {
        local code = conceptInput.code;
        if (code >= 200)
        {
            if (code == 200)
            {
                conceptBlueprint.apply(); conceptFacilities.fund(); prototypeStart.begin();
                for (local day = 1; day <= 4; day += 1)
                {
                    local work = new RpgExpandedPrototypeWork(); work.id = day; work.attempt = prototypeStart;
                    work.seconds = 86400; work.approved = true; work.uninterrupted = true; work.evidence = 'Complete day'; work.apply();
                }
                rpgRandom.seed(6); prototypeCompletion.knowledge = 'model'; prototypeCompletion.variantBonus = 5;
                prototypeCompletion.apply(); return nil;
            }
            if (code == 204) { prototypeLine.establish(); productionOrder.line = prototypeLine; }
            if (code == 205) conceptUser.money = 199;
            if (code == 206) prototypeClockFault.enabled = true;
            if (code == 208) productionOrder.evidence = 'Changed copy';
            local value = code >= 206 ? productionOrder.finish() : code == 203 ? productionOrder.assess() : productionOrder.begin();
            event('test.production-order'); eventValue(value.status); eventValue(value.reason); eventValue(value.money); eventValue(value.seconds);
            if (code == 202 || code == 207) throw new RpgError(); return nil;
        }
        if (code >= 180)
        {
            if (code == 180)
            {
                conceptBlueprint.apply(); conceptFacilities.fund(); prototypeStart.begin();
                for (local day = 1; day <= 4; day += 1)
                {
                    local work = new RpgExpandedPrototypeWork(); work.id = day; work.attempt = prototypeStart;
                    work.seconds = 86400; work.approved = true; work.uninterrupted = true; work.evidence = 'Complete day'; work.apply();
                }
                rpgRandom.seed(6); prototypeCompletion.knowledge = 'model'; prototypeCompletion.variantBonus = 5;
                prototypeCompletion.apply(); return nil;
            }
            if (code == 184) conceptUser.money = 19999;
            if (code == 185) prototypeLine.evidence = 'Changed production line';
            if (code == 186) prototypeLine.permitted = nil;
            local value = code == 183 ? prototypeLine.assess() : prototypeLine.establish();
            event('test.production-line'); eventValue(value.status); eventValue(value.reason); eventValue(value.money);
            if (code == 182) throw new RpgError(); return nil;
        }
        if (code >= 160)
        {
            if (code == 160)
            {
                conceptBlueprint.apply(); conceptFacilities.fund(); prototypeStart.begin();
                for (local day = 1; day <= 4; day += 1)
                {
                    local work = new RpgExpandedPrototypeWork(); work.id = day; work.attempt = prototypeStart;
                    work.seconds = 86400; work.approved = true; work.uninterrupted = true; work.evidence = 'Complete day'; work.apply();
                }
                rpgRandom.seed(1); prototypeCompletion.knowledge = 'model'; prototypeCompletion.apply();
                prototypeDefects.apply(); rpgRandom.seed(1); return nil;
            }
            if (code == 164) conceptUser.iq = 7;
            if (code == 165) rpgRandom.seed(5);
            if (code == 166) { conceptUser.iq = 13; rpgRandom.seed(6); }
            if (code == 167) prototypeClockFault.enabled = true;
            if (code == 168) prototypeTest.criticalPolicy = 'incident';
            if (code == 169) prototypeTest.evidence = 'Changed testing';
            local value = code == 163 ? prototypeTest.assess() : prototypeTest.apply();
            event('test.prototype-testing'); eventValue(value.status); eventValue(value.reason);
            eventValue(value.discovered.length()); eventValue(value.falseConfidence ? 1 : 0);
            if (code == 162) throw new RpgError(); return nil;
        }
        if (code >= 140)
        {
            if (code == 140)
            {
                conceptBlueprint.apply(); conceptFacilities.fund(); prototypeStart.begin();
                for (local day = 1; day <= 4; day += 1)
                {
                    local work = new RpgExpandedPrototypeWork(); work.id = day; work.attempt = prototypeStart;
                    work.seconds = 86400; work.approved = true; work.uninterrupted = true; work.evidence = 'Complete day'; work.apply();
                }
                rpgRandom.seed(1); prototypeCompletion.knowledge = 'model'; prototypeCompletion.apply();
                prototypeDefects.apply(); rpgRandom.seed(1); return nil;
            }
            if (code == 144) prototypeUse.modifier = -9;
            if (code == 145) { prototypeUse.modifier = 0; rpgRandom.seed(5); }
            if (code == 146) prototypeUse.criticalDefect = nil;
            if (code == 147) prototypeClockFault.enabled = true;
            if (code == 148) prototypeUse.evidence = 'Changed observation';
            local value = code == 143 ? prototypeUse.assess() : prototypeUse.apply();
            event('test.prototype-use'); eventValue(value.status); eventValue(value.reason);
            eventValue(value.check == nil ? nil : value.check.roll); eventValue(value.activated == nil ? nil : value.activated.id);
            if (code == 142) throw new RpgError(); return nil;
        }
        if (code >= 120)
        {
            if (code == 120)
            {
                conceptBlueprint.apply(); conceptFacilities.fund(); prototypeStart.begin();
                for (local day = 1; day <= 4; day += 1)
                {
                    local work = new RpgExpandedPrototypeWork(); work.id = day; work.attempt = prototypeStart;
                    work.seconds = 86400; work.approved = true; work.uninterrupted = true; work.evidence = 'Complete day'; work.apply();
                }
                rpgRandom.seed(1); prototypeCompletion.knowledge = 'model'; prototypeCompletion.apply(); return nil;
            }
            if (code == 124) prototypeDefects.defects = [prototypeMajor];
            if (code == 125) prototypeMinor1.active = true;
            if (code == 126) prototypeMajor.active = true;
            if (code == 127) prototypeMinor1.penalty = 3;
            if (code == 128) prototypeProduct.storageLocation = 'store';
            local value = code == 123 ? prototypeDefects.assess() : prototypeDefects.apply();
            event('test.prototype-defects'); eventValue(value.status); eventValue(value.reason);
            if (code == 122) throw new RpgError(); return nil;
        }
        if (code >= 100)
        {
            if (code == 100)
            {
                conceptBlueprint.apply(); conceptFacilities.fund(); prototypeStart.begin();
                for (local day = 1; day <= 4; day += 1)
                {
                    local work = new RpgExpandedPrototypeWork(); work.id = day; work.attempt = prototypeStart;
                    work.seconds = 86400; work.approved = true; work.uninterrupted = true; work.evidence = 'Complete day'; work.apply();
                }
                rpgRandom.seed(1); return nil;
            }
            if (code == 103) prototypeCompletion.knowledge = 'model';
            if (code == 104 || code == 105)
            { prototypeCompletion.knowledge = 'model'; prototypeCompletion.variantBonus = 5; rpgRandom.seed(6); }
            if (code == 105) conceptProject.theory = 'flawed';
            if (code == 106) rpgRandom.seed(5);
            if (code == 108) prototypeAccident.approved = nil;
            if (code == 109) prototypeCompletion.evidence = 'Changed completion';
            local value = code == 107 ? prototypeCompletion.assess() : prototypeCompletion.apply();
            event('test.prototype-completion'); eventValue(value.status); eventValue(value.reason);
            eventValue(value.outcome == nil ? nil : value.outcome.check.roll);
            eventValue(value.delivered ? 1 : 0); eventValue(value.pendingDefects ? 1 : 0);
            if (code == 102) throw new RpgError(); return nil;
        }
        if (code >= 80)
        {
            if (code == 80)
            {
                conceptBlueprint.apply(); conceptFacilities.fund(); prototypeStart.begin();
                for (local day = 1; day <= 4; day += 1)
                {
                    local work = new RpgExpandedPrototypeWork(); work.id = day; work.attempt = prototypeStart;
                    work.seconds = 86400; work.approved = true; work.uninterrupted = true; work.evidence = 'Complete day'; work.apply();
                }
                prototypeAccident.outcome = rpgExpandedPrototypeOutcome(12,17,nil,[]); rpgRandom.seed(1); return nil;
            }
            if (code == 84) prototypeAccident.approved = nil;
            if (code == 85) prototypeAccident.targets = [];
            if (code == 86) prototypeAccidentTarget.protection = 100;
            if (code == 87) prototypeAccident.evidence = 'Changed accident';
            local value = code == 83 ? prototypeAccident.assess() : prototypeAccident.apply();
            event('test.prototype-accident'); eventValue(value.status); eventValue(value.reason); eventValue(value.damage.length());
            if (code == 82) throw new RpgError(); return nil;
        }
        if (code >= 60)
        {
            if (code == 60) { conceptBlueprint.apply(); conceptFacilities.fund(); prototypeStart.begin(); return nil; }
            if (code == 64) prototypeWork.uninterrupted = nil;
            if (code == 65) conceptFacilities.destroyed = true;
            if (code == 66) prototypeClockFault.enabled = true;
            if (code == 68) prototypeWork.evidence = 'Changed work';
            local request = prototypeWork;
            if (code == 67 || code == 69)
            {
                request = new RpgExpandedPrototypeWork(); request.id = prototypeStart.workIntervals.length() + 1;
                request.attempt = prototypeStart; request.seconds = code == 69 ? 86400 : 3600;
                request.approved = true; request.uninterrupted = true; request.evidence = 'Next team interval';
            }
            local value = code == 63 ? request.assess() : request.apply();
            event('test.prototype-work'); eventValue(value.status); eventValue(value.reason); eventValue(value.seconds);
            if (code == 62) throw new RpgError(); return nil;
        }
        if (code >= 40)
        {
            if (code == 49) { conceptProposal.category = 'complex'; conceptBlueprint.apply(); conceptFacilities.fund(); return nil; }
            if (code == 50) { prototypeStart.monthDays = [31,28,31,30,31,30]; prototypeStart.calendarEvidence = 'Authored upcoming month intervals'; }
            if (code == 40) { conceptBlueprint.apply(); conceptFacilities.fund(); return nil; }
            if (code == 44) conceptUser.money = 999;
            if (code == 45) conceptFacilities.destroyed = true;
            if (code == 46) prototypeStart.evidence = 'Changed attempt';
            if (code == 48) conceptUser.unconscious = true;
            local value = code == 43 ? prototypeStart.assess() : code == 47 ? prototypeSecond.begin() : prototypeStart.begin();
            event('test.prototype-start'); eventValue(value.status); eventValue(value.reason);
            eventValue(value.money); eventValue(value.seconds);
            if (code == 42) throw new RpgError(); return nil;
        }
        if (code >= 10 && code <= 15)
        {
            if (code == 13) conceptBlueprint.actualDesign = nil;
            if (code == 14) conceptBlueprint.reference = 'different-drawings';
            if (code == 15) conceptBlueprint.acquired = nil;
            local value = code == 11 ? conceptBlueprint.assess() : conceptBlueprint.apply();
            event('test.blueprint'); eventValue(value.status); eventValue(value.reason);
            if (code == 12) throw new RpgError(); return nil;
        }
        if (code >= 20)
        {
            if (code == 29) { conceptProposal.relatedFacilities = true; conceptAttempt.knowledge = 'model'; conceptAttempt.apply(); return nil; }
            if (code == 30) { conceptUser.techLevel = 9; return nil; }
            if (code == 20) { conceptAttempt.knowledge = 'model'; conceptAttempt.apply(); return nil; }
            if (code == 24) conceptUser.money = 99999;
            if (code == 25) conceptFacilities.approved = nil;
            if (code == 26) { conceptFacilities.destroyed = true; return nil; }
            if (code == 28) conceptFacilities.evidence = 'Changed funding';
            local value = code == 23 ? conceptFacilities.assess() : code == 27 ? conceptReplacement.fund() : conceptFacilities.fund();
            event('test.facilities'); eventValue(value.status); eventValue(value.reason); eventValue(value.money); eventValue(value.rebuilt ? 1 : 0);
            if (code == 22) throw new RpgError(); return nil;
        }
        if (code == 3) conceptAttempt.knowledge = 'model';
        if (code == 4) rpgRandom.seed(5);
        if (code == 5) { rpgSpendTime(86400); return nil; }
        if (code == 8) conceptAttempt.evidence = 'Changed evidence';
        if (code == 9) conceptProposal.retailPrice = 2000;
        local request = code == 6 ? conceptRetry : code == 7 ? conceptOther : conceptAttempt;
        local value = code == 2 ? request.assess() : request.apply();
        event('test.concept'); eventValue(value.status); eventValue(value.reason); eventValue(value.theory);
        eventValue(value.score); eventValue(value.check == nil ? nil : value.check.roll);
        if (code == 1) throw new RpgError(); return nil;
    }
;
conceptAction: InventionConceptAction;
conceptVerb: Verb code = 2097 action = conceptAction label = 'develop concept';
modify gameMain initialRoom = inventionRoom;
startup() { rpgRandom.seed(1); return vhylStart(); }
turn(tokens) { return vhylTurn(tokens); }
act(verb,args)
{
    if (verb == 2120) { conceptInput.code = 200 + args[1]; return vhylAct(2097,args); }
    if (verb == 2121)
    {
        event('test.production-order-state'); eventValue(conceptUser.money); eventValue(conceptUser.equipment.length());
        eventValue(productionOrder.result == nil ? 0 : 1); eventValue(productionOrder.delivered ? 1 : 0);
        eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); eventValue(prototypeLine.activeOrder == nil ? 0 : 1); return nil;
    }
    if (verb == 2118) { conceptInput.code = 180 + args[1]; return vhylAct(2097,args); }
    if (verb == 2119)
    {
        event('test.production-line-state'); eventValue(conceptUser.money); eventValue(conceptProject.productionLines.length());
        eventValue(conceptUser.equipment.length()); eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
    }
    if (verb == 2115) { conceptInput.code = 160 + args[1]; return vhylAct(2097,args); }
    if (verb == 2116)
    {
        local known = 0; foreach (local defect in prototypeDefects.defects) if (defect.discovered) known += 1;
        event('test.prototype-testing-state'); eventValue(known); eventValue(prototypeMajor.active ? 1 : 0);
        eventValue(prototypeDefects.tests.length()); eventValue(prototypeTest.result != nil && prototypeTest.result.falseConfidence ? 1 : 0);
        eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
    }
    if (verb == 2113) { conceptInput.code = 140 + args[1]; return vhylAct(2097,args); }
    if (verb == 2114)
    {
        event('test.prototype-use-state'); eventValue(prototypeMinor1.active ? 1 : 0); eventValue(prototypeMinor1.discovered ? 1 : 0);
        eventValue(prototypeMajor.active ? 1 : 0); eventValue(prototypeDefects.operations.length());
        eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
    }
    if (verb == 2111) { conceptInput.code = 120 + args[1]; return vhylAct(2097,args); }
    if (verb == 2112)
    {
        local score = rpgLiteScore(conceptUser,prototypeOperation);
        event('test.prototype-operation'); eventValue(score);
        eventValue(score == nil ? prototypeOperation.unavailableReason(conceptUser) : nil);
        eventValue(conceptUser.equipment.length()); eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
    }
    if (verb == 2109) { conceptInput.code = 100 + args[1]; return vhylAct(2097,args); }
    if (verb == 2110)
    {
        event('test.prototype-completion-state'); eventValue(conceptProject.activePrototype == nil ? 0 : 1);
        eventValue(conceptProject.theory); eventValue(conceptUser.equipment.length());
        eventValue(prototypeCompletion.result == nil ? nil : prototypeCompletion.result.outcome.majorBugs);
        eventValue(prototypeCompletion.result == nil ? nil : prototypeCompletion.result.outcome.minorBugs);
        eventValue(conceptUser.injury); eventValue(conceptFacilities.destroyed ? 1 : 0);
        eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
    }
    if (verb == 2107) { conceptInput.code = 80 + args[1]; return vhylAct(2097,args); }
    if (verb == 2108)
    {
        event('test.prototype-accident-state'); eventValue(conceptUser.injury); eventValue(conceptUser.expandedWounds.length());
        eventValue(conceptFacilities.destroyed ? 1 : 0); eventValue(conceptUser.money);
        eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
    }
    if (verb == 2106) { conceptInput.code = 60 + args[1]; return vhylAct(2097,args); }
    if (verb == 2104) { conceptInput.code = 40 + args[1]; return vhylAct(2097,args); }
    if (verb == 2105)
    {
        event('test.prototype-start-state'); eventValue(conceptUser.money); eventValue(conceptProject.prototypes.length());
        eventValue(prototypeStart.result == nil ? nil : prototypeStart.result.seconds);
        eventValue(prototypeStart.workedSeconds); eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
    }
    if (verb == 2102) { conceptInput.code = 20 + args[1]; return vhylAct(2097,args); }
    if (verb == 2103)
    {
        event('test.facilities-state'); eventValue(conceptUser.money); eventValue(conceptProject.facilityFunding.length());
        eventValue(conceptProject.facilities == nil ? nil : conceptProject.facilities.destroyed ? 'destroyed' : 'available');
        eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
    }
    if (verb == 2097) { conceptInput.code = args[1]; return vhylAct(verb,args); }
    if (verb == 2098)
    {
        event('test.concept-state'); eventValue(conceptProject.attempts.length());
        eventValue(conceptUser.inventionConceptAttempts.length()); eventValue(conceptProject.theory);
        eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
    }
    return vhylAct(verb,args);
}
