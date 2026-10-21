#include "expanded-attention-task.t"
#include <vhyl-rpg-expanded-equipment.t>
#include <vhyl-rpg-expanded-technology.t>
attentionMachine: RpgLiteItem requiresMaintenance = true artifactHT = 8 cost = 500;
attentionFault: RpgExpandedBreakdown id = 'dust-attention' item = attentionMachine evidence = 'Dust exposure';
attentionRepairSkill: RpgLiteSkill id = 'mechanic' attribute = rpgIQ difficulty = 0;
attentionRepairTraining: RpgTraining skill = attentionRepairSkill points = 1;
attentionRepair: RpgExpandedBreakdownRepair id = 'attention-repair' failure = attentionFault repairer = fearProfile
    skill = attentionRepairSkill approvedSkill = true uninterrupted = true evidence = 'The scheduled repair attempt with suitable tools';
attentionRepairControl: RpgExpandedAttentionRepair id = 'repair-focus' profile = fearProfile trait = attentionTrait trigger = attentionRepair
    repair = attentionRepair occasion = 'extended-focus' evidence = 'Sustained focus on the repair' stressRelation = 'unrelated';
attentionParts: RpgExpandedRepairParts failure = attentionFault payer = fearProfile weight = 50
    evidence = 'Suitable replacement parts in stock' available = true permitted = true;
attentionRepairInput: object rolls = 0 major = nil;
modify rpgRandom
    roll()
    {
        self.draws += 3; attentionRepairInput.rolls += 1;
        if (attentionRepairInput.rolls == 1) return attentionRepairInput.major ? 18 : 13;
        return attentionRepairInput.rolls == 2 ? attentionInput.controlRoll : 7;
    }
    die(sides) { self.draws += 1; return 2; }
;
modify FearTestAction
    exec(context)
    {
        local code = fearInput.code;
        if (code == 1230)
        {
            fearProfile.traits = [attentionTrait]; fearProfile.skills = [attentionRepairTraining]; fearProfile.money = 1000;
            attentionFault.apply(); if (attentionRepairInput.major) attentionParts.purchase(); return nil;
        }
        if (code == 1231 || code == 1232)
        { attentionRepairControl.resolve(); if (code == 1232) throw new RpgError(); return nil; }
        if (code == 1233)
        {
            event('test.attention-repair'); eventValue(fearProfile.selfControlTriggers.length());
            eventValue(attentionFault.repairs.length()); eventValue(attentionMachine.environmentFailure == nil ? 1 : 0);
            eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); eventValue(fearProfile.money);
            eventValue(attentionParts.installed ? 1 : 0);
            eventValue(attentionRepair.result == nil ? nil : attentionRepair.result.check.reason); return nil;
        }
        if (code == 1234)
        { event('test.attention-repair-direct'); eventValue(attentionRepair.apply().reason); return nil; }
        if (code == 1235) { attentionRepairControl.assess(); return nil; }
        if (code == 1236) { attentionRepair.result.check.achieved = !attentionRepair.result.check.achieved; attentionRepairControl.assess(); return nil; }
        if (code == 1237) { attentionTrait.mitigated = true; attentionRepair.apply(); return nil; }
        if (code == 1238) { attentionRepair.applyAttention(attentionRepairControl); return nil; }
        if (code == 1239) { attentionRepairInput.major = true; return nil; }
        if (code == 1240) { attentionRepair.uninterrupted = nil; return nil; }
        return inherited(context);
    }
;
