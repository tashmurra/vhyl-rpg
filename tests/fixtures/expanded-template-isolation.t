#include "expanded-behavior-templates.t"
isolationState: object source = nil combined = nil;
isolationFirst: RpgExpandedTemplate
    traitRows = [['charisma',1,nil]]
    create(rules)
    {
        local profile = inherited(rules); isolationState.source = profile; return profile;
    }
;
isolationCustomized: RpgExpandedTemplate
    traitRows = [['charisma',1,nil]]
    change = 0
    create(rules)
    {
        local profile = inherited(rules); local trait = profile.traits[1];
        if (self.change == 1) trait.points = 6;
        if (self.change == 2) trait.active = nil;
        if (self.change == 3) trait.mitigated = true;
        if (self.change == 4) trait.skills = [learningSkill];
        if (self.change == 5) trait.nextCheck = 1;
        return profile;
    }
;
selectionCharm: RpgExpandedTemplateOption id = 'charm' traitRows = [['charisma',2,nil]];
selectionTraining: RpgExpandedTemplateOption id = 'training' skillRows = [[learningSkill,2]];
selectionGroup: RpgExpandedTemplateChoice
    id = 'profession'
    options = [selectionCharm,selectionTraining]
;
selectionPackage: RpgExpandedTemplate choiceGroups = [selectionGroup];
selectionInput: RpgExpandedTemplateSelection
    template = selectionPackage
    selections = [['profession',['charm']]]
;
isolationSecond: RpgExpandedTemplate traitRows = [['charisma',2,nil]];
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 5620 || code == 5621)
        {
            if (code == 5621) selectionInput.selections = [['profession',['training']]];
            isolationState.combined = rpgExpandedCombineTemplates([isolationFirst,selectionInput],bleedRules,100,50);
            return nil;
        }
        if (code == 5622)
        {
            local p = isolationState.combined;
            event('test.template-selection'); eventValue(rpgExpandedCharacterCost(p,nil));
            eventValue(p.traits[1].level); eventValue(p.skills.length());
            eventValue(p.templateSelections.length());
            eventValue(p.templateSelections[2][1] == selectionPackage ? 1 : 0);
            eventValue(p.templateSelections[2][2][1][1]); eventValue(p.templateSelections[2][2][1][2]);
            return nil;
        }
        if (code == 5623) { selectionInput.selections = [['profession',['missing']]]; return nil; }
        if (code == 5624)
        {
            event('test.template-selection-error');
            try { rpgExpandedCombineTemplates([isolationFirst,selectionInput],bleedRules,100,50); eventValue('accepted'); }
            catch (RpgExpandedError error) { eventValue(error.reason); }
            return nil;
        }
        if (code == 5625) { selectionGroup.minimumPoints = 10; selectionGroup.maximumPoints = 10; return nil; }
        if (code >= 5610 && code <= 5615)
        {
            isolationCustomized.change = code - 5610;
            event('test.template-customization');
            try
            {
                rpgExpandedCombineTemplates([isolationFirst,isolationCustomized],bleedRules,100,50);
                eventValue('accepted');
            }
            catch (RpgExpandedError error) { eventValue(error.reason); }
            try
            {
                rpgExpandedCombineTemplates([isolationCustomized,isolationFirst],bleedRules,100,50);
                eventValue('accepted');
            }
            catch (RpgExpandedError error) { eventValue(error.reason); }
            return nil;
        }
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
