#include <vhyl.h>
#include <vhyl.t>
#include <vhyl-rpg.t>
#include <vhyl-rpg-progression.t>
#include <vhyl-rpg-lite.t>
#include <vhyl-rpg-expanded.t>
#include <vhyl-rpg-expanded-equipment.t>
#include <vhyl-rpg-expanded-technology.t>
technologyRoom: Room 'Workshop';
inventionUser: RpgLiteProfile techLevel = 8 skills = [inventionTraining,inventionRelatedTraining];
inventionSkill: RpgLiteSkill id = 'engineer' attribute = rpgIQ difficulty = 2;
inventionRelated: RpgLiteSkill id = 'astronomy' attribute = rpgIQ difficulty = 2;
inventionTraining: RpgTraining skill = inventionSkill points = 24;
inventionRelatedTraining: RpgTraining skill = inventionRelated points = 16;
inventionProposal: RpgExpandedInventionProposal inventor = inventionUser skill = inventionSkill
    description = 'A compact survey instrument' mechanism = 'Optical measurement'
    evidence = 'Feasible optical design' approved = true techLevel = 8 category = 'average' retailPrice = 1000;
modify gameMain initialRoom = technologyRoom;
startup() { return vhylStart(); }
act(verb,args)
{
    if (verb == 2095)
    {
        local code = args[1];
        if (code == 1) inventionProposal.relatedSkills = [inventionRelated];
        if (code == 2) inventionProposal.techLevel = 9;
        if (code == 3) inventionProposal.techLevel = 10;
        if (code == 4) { inventionProposal.techLevel = 7; inventionProposal.category = 'complex'; }
        if (code == 5) inventionProposal.relatedFacilities = true;
        if (code == 6) { inventionProposal.category = nil; inventionProposal.softwareComplexity = 6; }
        if (code == 7) inventionProposal.approved = nil;
        if (code == 8) inventionTraining.points = 0;
        if (code == 9) inventionProposal.descriptionBonus = 2;
        local value = inventionProposal.assess();
        event('test.invention-proposal'); eventValue(value.status); eventValue(value.reason);
        eventValue(value.skillScore); eventValue(value.category); eventValue(value.conceptModifier);
        eventValue(value.facilitiesCost); eventValue(value.attemptCost);
        eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
    }
    if (verb == 2096)
    {
        event('test.invention-category'); eventValue(rpgExpandedInventionPriceCategory(args[1]));
        eventValue(rpgExpandedInventionSkillCategory(args[2])); eventValue(rpgExpandedInventionSoftwareCategory(args[3])); return nil;
    }
    if (verb == 2051)
    {
        local draws = rpgRandom.draws; local clock = rpgLedger.seconds;
        event('test.object-capacity'); eventValue(rpgExpandedObjectCapacity(args[1],args[2]));
        event('test.object-purity'); eventValue(rpgRandom.draws-draws); eventValue(rpgLedger.seconds-clock); return nil;
    }
    if (verb == 2052)
    {
        local draws = rpgRandom.draws; local clock = rpgLedger.seconds;
        local value = rpgExpandedObjectInjury(args[1],args[2],args[3]);
        event('test.object-injury'); eventValue(value.remaining); eventValue(value.automaticDestruction ? 1 : 0);
        eventValue(value.stressChecksRequired ? 1 : 0); eventValue(value.reducedEffectivenessEligible ? 1 : 0);
        eventValue(value.majorDamage ? 1 : 0); eventValue(value.destructionThresholds.length());
        foreach (local threshold in value.destructionThresholds) eventValue(threshold);
        event('test.object-purity'); eventValue(rpgRandom.draws-draws); eventValue(rpgLedger.seconds-clock); return nil;
    }
    if (verb == 2050)
    {
        local draws = rpgRandom.draws; local clock = rpgLedger.seconds;
        local value = rpgExpandedBrokenWeapon(args[1],args[2],args[3] != 0,args[4],args[5] == 0 ? nil : args[5],args[6]);
        event('test.broken-weapon'); eventValue(value.status); eventValue(value.reason); eventValue(value.usable ? 1 : 0);
        eventValue(value.retainOriginal ? 1 : 0); eventValue(value.cuttingDamageModifier);
        eventValue(value.thrustBase); eventValue(value.thrustDamageType); eventValue(value.reach); eventValue(value.pieces.length());
        foreach (local piece in value.pieces)
        {
            event(piece.placement == 'held' ? 'test.broken-held' : 'test.broken-ground'); eventValue(piece.form); eventValue(piece.placement); eventValue(piece.attackModifier);
            eventValue(piece.reach); eventValue(piece.damageBase); eventValue(piece.damageAdds); eventValue(piece.damageType);
        }
        event('test.broken-purity'); eventValue(rpgRandom.draws-draws); eventValue(rpgLedger.seconds-clock); return nil;
    }
    return vhylAct(verb,args);
}
