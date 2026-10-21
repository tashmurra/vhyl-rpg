#include "expanded-attention-task.t"
#include <vhyl-rpg-expanded-equipment.t>
#include <vhyl-rpg-expanded-technology.t>
attentionDesignSkill: RpgLiteSkill id = 'engineer' attribute = rpgIQ difficulty = 2;
attentionDesignTraining: RpgTraining skill = attentionDesignSkill points = 24;
attentionProposal: RpgExpandedInventionProposal inventor = fearProfile skill = attentionDesignSkill
    description = 'Survey tool' mechanism = 'Optical measurement' evidence = 'Feasible design' approved = true
    techLevel = 8 category = 'simple' retailPrice = 1000;
attentionProject: RpgExpandedInventionProject proposal = attentionProposal;
attentionConcept: RpgExpandedInventionConcept id = 'first-concept' project = attentionProject evidence = 'Independent design';
attentionNextConcept: RpgExpandedInventionConcept id = 'next-concept' project = attentionProject evidence = 'A second attempt';
attentionCapability: RpgExpandedInventor approved = true tier = 'rapid';
attentionPermission: RpgExpandedInventionPermission inventor = fearProfile mode = 'rapid' designApproved = true evidence = 'Approved optical concept';
attentionRapidProposal: RpgExpandedRapidProposal inventor = fearProfile skill = attentionDesignSkill permission = attentionPermission
    description = 'Rapid survey design' mechanism = 'Optical measurement' evidence = 'Approved rapid design'
    approved = true techLevel = 8 category = 'simple' retailPrice = 1000;
attentionRapidProject: RpgExpandedInventionProject proposal = attentionRapidProposal;
attentionRapidConcept: RpgExpandedRapidConcept id = 'rapid-concept' project = attentionRapidProject approved = true uninterrupted = true
    evidence = 'An uninterrupted design period';
attentionConceptControl: RpgExpandedAttentionConcept id = 'concept-focus' profile = fearProfile trait = attentionTrait trigger = attentionConcept
    concept = attentionConcept occasion = 'distraction' evidence = 'A noise distracts the inventor during this attempt' stressRelation = 'unrelated';
attentionConceptInput: object rolls = 0;
modify rpgRandom
    roll() { self.draws += 3; attentionConceptInput.rolls += 1; return attentionConceptInput.rolls == 1 ? attentionInput.controlRoll : 7; }
    die(sides) { self.draws += 1; return 2; }
;
modify FearTestAction
    exec(context)
    {
        local code = fearInput.code;
        if (code == 1250)
        { fearProfile.traits = [attentionTrait]; fearProfile.skills = [attentionDesignTraining];
          fearProfile.techLevel = 8; fearProfile.campaignTL = 8; return nil; }
        if (code == 1251 || code == 1252)
        { attentionConceptControl.resolve(); if (code == 1252) throw new RpgError(); return nil; }
        if (code == 1253)
        {
            event('test.attention-concept'); eventValue(fearProfile.selfControlTriggers.length());
            eventValue(fearProfile.inventionConceptAttempts.length()); eventValue(attentionConceptControl.concept.project.theory);
            eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds);
            eventValue(attentionConceptControl.concept.result == nil ? nil : attentionConceptControl.concept.result.check.reason); return nil;
        }
        if (code == 1254)
        { event('test.attention-concept-direct'); eventValue(attentionConceptControl.concept.apply().reason); return nil; }
        if (code == 1255) { attentionConceptControl.assess(); return nil; }
        if (code == 1256) { attentionConceptControl.concept.result.check.achieved = true; attentionConceptControl.assess(); return nil; }
        if (code == 1257)
        {
            fearProfile.traits = [attentionTrait,attentionCapability]; fearRules.cinematicInvention = true; fearRules.rapidInvention = true;
            attentionConceptControl.concept = attentionRapidConcept; attentionConceptControl.trigger = attentionRapidConcept; return nil;
        }
        if (code == 1258)
        { event('test.attention-concept-next'); eventValue(attentionNextConcept.assess().reason); return nil; }
        if (code == 1259) { attentionProposal.approved = nil; return nil; }
        return inherited(context);
    }
;
