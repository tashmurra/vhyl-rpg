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
conceptInput: object code = 0;
class InventionConceptAction: Action
    exec(context)
    {
        local code = conceptInput.code;
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
