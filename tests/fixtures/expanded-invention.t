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
inventionRoom: Room 'Design Office';
conceptRules: RpgExpandedRules;
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
conceptInput: object code = 0;
class InventionConceptAction: Action
    exec(context)
    {
        local code = conceptInput.code;
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
