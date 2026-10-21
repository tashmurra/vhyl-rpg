#include "expanded-ancestry-traits.t"
stackFirst: RpgExpandedAncestryTemplate
    id = 'first-ancestry' approved = true evidence = 'Approved first ancestry'
    traitRows = [['charisma',1,nil],['night-vision',4,nil],['compelled-aid',1,nil,6]]
;
stackSecond: RpgExpandedAncestryTemplate
    id = 'second-ancestry' approved = true evidence = 'Approved second ancestry'
    traitRows = [['charisma',2,nil],['night-vision',5,nil],['compelled-aid',1,nil,6]]
;
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 6100 || code == 6101)
        {
            local packages = code == 6100 ? [stackFirst,stackSecond] : [stackSecond,stackFirst];
            ancestryState.profile = rpgExpandedCreateAncestryCharacter(ancestryPlain,packages,bleedRules); return nil;
        }
        if (code == 6102) { stackSecond.traitRows = [['night-vision',6,nil]]; return nil; }
        if (code == 6103) { stackSecond.traitRows = [['compelled-aid',1,nil,9]]; return nil; }
        if (code == 6104)
        { stackFirst.traitRows = [['delusions',1,nil]]; stackSecond.traitRows = [['delusions',2,nil]]; return nil; }
        if (code == 6106)
        { stackFirst.traitRows = [['ambidexterity',1,nil]]; stackSecond.traitRows = [['ambidexterity',1,nil]]; return nil; }
        if (code == 6107) { stackFirst.traitRows = [['charisma',1,nil],['charisma',1,nil]]; return nil; }
        if (code == 6108)
        {
            local p = ancestryState.profile; event('test.ancestry-stack');
            eventValue(rpgExpandedCharacterCost(p,nil)); eventValue(p.traits.length());
            eventValue(p.level('charisma')); eventValue(p.level('night-vision'));
            eventValue(p.creationDisadvantageExemption());
            foreach (local origins in p.ancestryScores.traitOrigins) eventValue(origins.length());
            eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 6109)
        {
            event('test.ancestry-stack-error');
            try { rpgExpandedCreateAncestryCharacter(ancestryPlain,[stackFirst,stackSecond],bleedRules); eventValue('accepted'); }
            catch (RpgExpandedError error) { eventValue(error.reason); } return nil;
        }
        return inherited(context);
    }
;
