#include "expanded-low-motivation.t"
#include <vhyl-rpg-expanded-skills.t>
#include <vhyl-rpg-expanded-characters.t>
#include <vhyl-rpg-expanded-templates.t>
aidPackage: RpgExpandedTemplate traitRows = [['compelled-aid',1,nil,6]];
motivationPackage: RpgExpandedTemplate traitRows = [['low-motivation',1,nil,12]];
aidConflictingPackage: RpgExpandedTemplate traitRows = [['compelled-aid',1,nil,15]];
behaviorTemplateState: object profile = nil;
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 5500)
        {
            local p = rpgExpandedCombineTemplates([aidPackage,motivationPackage],bleedRules,100,50);
            behaviorTemplateState.profile = p;
            event('test.behavior-template'); eventValue(rpgExpandedCharacterCost(p,nil)); eventValue(p.traits.length());
            eventValue(p.traits[1].ofKind(RpgExpandedCompelledAid) ? 1 : 0);
            eventValue(p.traits[2].ofKind(RpgExpandedLowMotivation) ? 1 : 0);
            eventValue(p.traits[1].selfControlNumber()); eventValue(p.traits[2].selfControlNumber()); return nil;
        }
        if (code == 5501)
        {
            event('test.behavior-template-conflict');
            try { rpgExpandedCombineTemplates([aidPackage,aidConflictingPackage],bleedRules,100,50); eventValue('accepted'); }
            catch (RpgExpandedError error) { eventValue(error.reason); } return nil;
        }
        if (code == 5502)
        {
            local first = aidPackage.create(bleedRules); local second = aidPackage.create(bleedRules);
            first.traits[1].mitigated = true; event('test.behavior-template-fresh');
            eventValue(first.traits[1] == second.traits[1] ? 1 : 0); eventValue(second.traits[1].mitigated ? 1 : 0); return nil;
        }
        if (code == 5503)
        {
            local receipt = new RpgExpandedCharacterFinalization(); receipt.id = 'behavior-character';
            receipt.profile = behaviorTemplateState.profile; receipt.approved = true; receipt.evidence = 'Approved template-based character';
            receipt.apply(); event('test.behavior-template-history');
            eventValue(receipt.bases.length()); eventValue(receipt.bases[1].originalBonus); eventValue(receipt.bases[2].originalBonus); return nil;
        }
        return inherited(context);
    }
;
