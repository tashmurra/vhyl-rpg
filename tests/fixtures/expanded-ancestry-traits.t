#include "expanded-ancestry-scores.t"
ancestryPersonalTraits: RpgExpandedTemplate
    disadvantageLimit = 5
    traitRows = [['quirk',1,'maps'],['quirk',1,'hats'],['quirk',1,'coins'],['quirk',1,'songs'],['quirk',1,'names']]
;
ancestryTraitPackage: RpgExpandedAncestryTemplate
    id = 'communal-ancestry' approved = true evidence = 'Approved mandatory ancestry components'
    traitRows = [['charisma',2,nil],['compelled-aid',1,nil,6],['quirk',1,'ancestry greeting']]
;
ancestryTraitOffer: RpgDevelopment
    id = 'ancestry-trait-removal' kind = 'remove-trait' cost = 30 unlocked = true
    available(profile) { return nil; }
;
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 6000)
        {
            ancestryState.profile = rpgExpandedCreateAncestryCharacter(ancestryPersonalTraits,[ancestryTraitPackage],bleedRules);
            return nil;
        }
        if (code == 6001)
        {
            local p = ancestryState.profile; local aid = p.ancestryScores.traits[2];
            event('test.ancestry-traits'); eventValue(rpgExpandedCharacterCost(p,nil));
            eventValue(rpgExpandedCharacterCost(p,true)); eventValue(p.creationDisadvantageExemption());
            eventValue(p.traits.length()); eventValue(p.level('charisma'));
            eventValue(aid.ofKind(RpgExpandedCompelledAid) ? 1 : 0); eventValue(aid.selfControlNumber());
            eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 6002)
        {
            local p = ancestryState.profile; local retained = [];
            foreach (local trait in p.traits) if (trait != p.ancestryScores.traits[2]) retained = retained + [trait];
            p.traits = retained; return nil;
        }
        if (code == 6003)
        {
            local p = ancestryState.profile; p.unspentPoints = 100; p.developmentOpen = true;
            local aid = p.ancestryScores.traits[2]; ancestryTraitOffer.profile = p; ancestryTraitOffer.trait = aid;
            event('test.ancestry-buyoff'); eventValue(rpgLiteBuyOff(p,aid) ? 1 : 0);
            eventValue(rpgDevelop(ancestryTraitOffer).reason); eventValue(p.unspentPoints); return nil;
        }
        if (code == 6004)
        {
            local finalization = new RpgExpandedCharacterFinalization(); finalization.id = 'ancestry-character';
            finalization.profile = ancestryState.profile; finalization.approved = true; finalization.evidence = 'Approved complete character';
            finalization.apply();
            foreach (local basis in finalization.bases) { basis.approved = true; basis.evidence = 'Ordinary buyoff approval'; }
            return nil;
        }
        if (code == 6005)
        {
            local p = ancestryState.profile; p.traits = p.traits + [rpgLiteMakeTrait('quirk',1,'extra personal')]; return nil;
        }
        if (code == 6006) { ancestryState.profile.ancestryScores.traits[1].level = 3; return nil; }
        if (code == 6007)
        {
            local first = ancestryState.profile;
            local second = rpgExpandedCreateAncestryCharacter(ancestryPersonalTraits,[ancestryTraitPackage],bleedRules);
            second.ancestryScores.traits[2].mitigated = true; event('test.ancestry-trait-ownership');
            eventValue(first.ancestryScores.traits[2] == second.ancestryScores.traits[2] ? 1 : 0);
            eventValue(first.ancestryScores.traits[2].mitigated ? 1 : 0); return nil;
        }
        return inherited(context);
    }
;
