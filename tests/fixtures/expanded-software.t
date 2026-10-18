#include <vhyl.h>
#include <vhyl.t>
#include <vhyl-rpg.t>
#include <vhyl-rpg-progression.t>
#include <vhyl-rpg-lite.t>
#include <vhyl-rpg-expanded.t>
#include <vhyl-rpg-expanded-skills.t>
#include <vhyl-rpg-expanded-equipment.t>
#include <vhyl-rpg-expanded-technology.t>
softwareRoom: Room 'Accounts Office';
softwareUser: RpgLiteProfile skills = [softwareTraining,technicalTraining];
softwareSkill: RpgLiteSkill id = 'accounting' attribute = rpgIQ difficulty = 1;
softwareTraining: RpgTraining skill = softwareSkill points = 2;
softwareEquipment: RpgExpandedEquipmentAssessment quality = 'good';
softwareCapability: RpgExpandedSoftwareCapability taskId = 'prepare-accounts' skill = softwareSkill
    equipment = softwareEquipment approved = true evidence = 'Accounting support for this task';
softwareCopy: RpgExpandedSoftwareCopy id = 'accounts' host = softwareHost complexity = 2 approved = true
    evidence = 'Installed copy' taskCapabilities = [softwareCapability];
softwareItem: RpgLiteItem;
softwareHost: RpgExpandedComputer item = softwareItem complexity = 2 powered = true copies = [softwareCopy];
softwareProgram: RpgExpandedProgramRun id = 'accounts-first' host = softwareHost copy = softwareCopy;
softwareOtherProgram: RpgExpandedProgramRun id = 'accounts-second' host = softwareHost copy = softwareCopy;
softwareTerminal: RpgExpandedTerminal controller = softwareUser hosts = [softwareHost] current = softwareHost powered = true;
softwareUse: RpgExpandedSoftwareUse program = softwareProgram terminal = softwareTerminal
    taskId = 'prepare-accounts' capability = softwareCapability;
softwareContext: RpgLiteContext skill = softwareSkill softwareUse = softwareUse;
technicalSkill: RpgLiteSkill id = 'engineer' attribute = rpgIQ difficulty = 2 techLevel = 8;
technicalTraining: RpgTraining skill = technicalSkill points = 4;
technicalCapability: RpgExpandedSoftwareCapability taskId = 'design-engine' skill = technicalSkill
    equipment = softwareEquipment approved = true evidence = 'Design support';
technicalUse: RpgExpandedSoftwareUse program = softwareProgram terminal = softwareTerminal
    taskId = 'design-engine' capability = technicalCapability;
technicalRequirement: RpgExpandedSoftwareRequirement taskId = 'design-engine' skill = technicalSkill
    fallbackTL = 7 use = technicalUse approved = true evidence = 'Lower-technology design without program';
technicalContext: RpgExpandedSkillContext skill = technicalSkill equipmentTL = 8 softwareRequirement = technicalRequirement;
modify gameMain initialRoom = softwareRoom;
startup() { softwareProgram.start(); return vhylStart(); }
act(verb,args)
{
    if (verb == 2090)
    {
        local code = args[1];
        if (code == 1) softwareOtherProgram.start();
        if (code == 2) softwareProgram.stop();
        if (code == 3) softwareUse.taskId = 'different-task';
        if (code == 4) softwareHost.powered = nil;
        if (code == 5) softwareCapability.approved = nil;
        if (code == 6) softwareContext.softwareUse = nil;
        if (code == 7) softwareTerminal.current = nil;
        if (code == 8) softwareUser.unconscious = true;
        if (code == 9) softwareCopy.approved = nil;
        if (code == 10) softwareCopy.taskCapabilities = [];
        if (code == 11) softwareEquipment.quality = 'fine';
        if (code == 12) softwareTerminal.powered = nil;
        local draws = rpgRandom.draws; local clock = rpgLedger.seconds;
        local score = rpgLiteScore(softwareUser,softwareContext);
        event('test.software-score'); eventValue(score);
        eventValue(score == nil ? softwareContext.unavailableReason(softwareUser) : nil);
        eventValue(softwareUser.skillScore(softwareSkill));
        eventValue(rpgRandom.draws-draws); eventValue(rpgLedger.seconds-clock); return nil;
    }
    if (verb == 2092)
    {
        softwareCopy.taskCapabilities = [softwareCapability,technicalCapability];
        local code = args[1];
        if (code == 1) technicalRequirement.minimumComplexity = 2;
        if (code == 2) technicalRequirement.use = nil;
        if (code == 3) technicalRequirement.fallbackTL = nil;
        if (code == 4) technicalRequirement.approved = nil;
        if (code == 5) { technicalRequirement.minimumComplexity = 2; softwareProgram.stop(); }
        if (code == 6) technicalContext.equipmentTL = 7;
        if (code == 7) { technicalRequirement.minimumComplexity = 2; technicalContext.softwareUse = technicalUse; }
        local draws = rpgRandom.draws; local clock = rpgLedger.seconds;
        local value = technicalRequirement.assess(softwareUser,technicalSkill);
        local score = rpgLiteScore(softwareUser,technicalContext);
        event('test.software-requirement'); eventValue(value.status); eventValue(value.effectiveTL);
        eventValue(value.softwareAvailable ? 1 : 0); eventValue(value.reason); eventValue(value.softwareReason);
        eventValue(score); eventValue(score == nil ? technicalContext.unavailableReason(softwareUser) : nil);
        eventValue(technicalSkill.techLevel); eventValue(softwareUser.skillScore(technicalSkill));
        eventValue(rpgRandom.draws-draws); eventValue(rpgLedger.seconds-clock); return nil;
    }
    if (verb == 2091)
    { event('test.software-complexity'); eventValue(rpgExpandedRequiredSoftwareComplexity(args[1])); return nil; }
    return vhylAct(verb,args);
}
