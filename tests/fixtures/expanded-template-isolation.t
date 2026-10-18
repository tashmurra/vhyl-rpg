#include "expanded-behavior-templates.t"
isolationState: object source = nil combined = nil;
isolationFirst: RpgExpandedTemplate
    traitRows = [['charisma',1,nil]]
    create(rules)
    {
        local profile = inherited(rules); isolationState.source = profile; return profile;
    }
;
isolationSecond: RpgExpandedTemplate traitRows = [['charisma',2,nil]];
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 5600)
        {
            isolationState.combined = rpgExpandedCombineTemplates([isolationFirst,isolationSecond],bleedRules,100,50);
            return nil;
        }
        if (code == 5601) { isolationState.combined.traits[1].level = 3; return nil; }
        if (code == 5602)
        {
            event('test.template-isolation'); eventValue(isolationState.source.traits[1].level);
            eventValue(isolationState.combined.traits[1].level);
            eventValue(isolationState.source.traits[1] == isolationState.combined.traits[1] ? 1 : 0);
            eventValue(rpgExpandedCharacterCost(isolationState.source,nil));
            eventValue(rpgExpandedCharacterCost(isolationState.combined,nil)); return nil;
        }
        return inherited(context);
    }
;
