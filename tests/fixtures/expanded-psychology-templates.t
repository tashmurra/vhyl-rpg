#include "expanded-psychology-skill.t"
#include <vhyl-rpg-expanded-characters.t>
#include <vhyl-rpg-expanded-templates.t>
appliedTemplate: RpgExpandedTemplate iq = 12 skillRows = [[psychologyApplied,4]];
experimentalTemplate: RpgExpandedTemplate iq = 12 skillRows = [[psychologyExperimental,4]];
generalTemplate: RpgExpandedTemplate iq = 12 skillRows = [[psychologyGeneral,4]];
psychologyAppliedCopy: RpgExpandedPsychologySkill specialty = 'river-folk' discipline = 'applied' splitApproved = true splitEvidence = 'Campaign split';
duplicateAppliedTemplate: RpgExpandedTemplate iq = 12 skillRows = [[psychologyAppliedCopy,4]];
psychologyTemplateState: object profile = nil;
modify PhysicianFixtureAction
    exec(context)
    {
        local code = healthInput.code;
        if (code == 21500 || code == 21501)
        {
            psychologyTemplateState.profile = rpgExpandedCombineTemplates([appliedTemplate,experimentalTemplate],healthRules,100,50);
            if (code == 21501) throw new RpgError(); return nil;
        }
        if (code == 21502)
        {
            local p = psychologyTemplateState.profile; event('test.psychology-template');
            eventValue(p == nil ? nil : p.skills.length()); eventValue(p == nil ? nil : rpgExpandedCharacterCost(p,nil));
            eventValue(p == nil ? nil : p.skillScore(psychologyApplied)); eventValue(p == nil ? nil : p.skillScore(psychologyExperimental));
            eventValue(rpgRandom.draws); return nil;
        }
        if (code == 21503 || code == 21504)
        {
            try { rpgExpandedCombineTemplates([appliedTemplate,code == 21503 ? generalTemplate : duplicateAppliedTemplate],healthRules,100,50); }
            catch (RpgExpandedError error) { event('test.psychology-template-error'); eventValue(error.reason); }
            return nil;
        }
        return inherited(context);
    }
;
