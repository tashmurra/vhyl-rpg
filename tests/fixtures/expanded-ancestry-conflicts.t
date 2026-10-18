#include "expanded-ancestry-stacking.t"
conflictFirst: RpgExpandedAncestryTemplate
    id = 'fortunate-ancestry' approved = true evidence = 'Approved ancestry' traitRows = [['luck',1,nil]];
conflictSecond: RpgExpandedAncestryTemplate
    id = 'unfortunate-ancestry' approved = true evidence = 'Approved ancestry' traitRows = [['unluckiness',1,nil]];
conflictDecision: RpgExpandedAncestryConflict
    id = 'fortune-resolution' retainedAncestry = 'fortunate-ancestry' retainedTrait = 'luck'
    discardedAncestry = 'unfortunate-ancestry' discardedTrait = 'unluckiness'
    approved = true evidence = 'Author retains favorable fortune for this combined ancestry';
conflictReverse: RpgExpandedAncestryConflict
    id = 'reverse-resolution' retainedAncestry = 'unfortunate-ancestry' retainedTrait = 'unluckiness'
    discardedAncestry = 'fortunate-ancestry' discardedTrait = 'luck'
    approved = true evidence = 'Opposing decision';
conflictState: object resolutions = [conflictDecision];
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 6200)
        {
            ancestryState.profile = rpgExpandedCreateResolvedAncestryCharacter(ancestryPlain,
                [conflictFirst,conflictSecond],conflictState.resolutions,bleedRules); return nil;
        }
        if (code == 6201) { conflictState.resolutions = [conflictReverse]; return nil; }
        if (code == 6202) { conflictDecision.discardedTrait = 'missing'; return nil; }
        if (code == 6203) { conflictDecision.approved = nil; return nil; }
        if (code == 6204)
        {
            conflictFirst.traitRows = [['charisma',1,nil]]; conflictSecond.traitRows = [['charisma',2,nil]];
            conflictDecision.retainedTrait = 'charisma'; conflictDecision.discardedTrait = 'charisma'; return nil;
        }
        if (code == 6205) { conflictState.resolutions = [conflictDecision,conflictReverse]; return nil; }
        if (code == 6206)
        {
            event('test.ancestry-resolution-error');
            try { rpgExpandedCreateResolvedAncestryCharacter(ancestryPlain,[conflictFirst,conflictSecond],conflictState.resolutions,bleedRules); eventValue('accepted'); }
            catch (RpgExpandedError error) { eventValue(error.reason); } return nil;
        }
        if (code == 6207)
        {
            local p = ancestryState.profile; event('test.ancestry-resolution');
            eventValue(rpgExpandedCharacterCost(p,nil)); eventValue(p.creationDisadvantageExemption());
            eventValue(p.traits.length()); eventValue(p.traits[1].id); eventValue(p.traits[1].selfControlNumber());
            eventValue(p.ancestryScores.decisions.length()); eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 6208) { ancestryState.profile.ancestryScores.decisions = []; return nil; }
        if (code == 6210)
        {
            conflictFirst.traitRows = [['compelled-aid',1,nil,6]]; conflictSecond.traitRows = [['compelled-aid',1,nil,9]];
            conflictDecision.retainedTrait = 'compelled-aid'; conflictDecision.discardedTrait = 'compelled-aid'; return nil;
        }
        return inherited(context);
    }
;
