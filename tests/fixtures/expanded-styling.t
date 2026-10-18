#include "expanded-appearance.t"
stylingTrait: RpgExpandedStyling approved = true;
stylingDesigner: RpgExpandedProfile rules = healthRules traits = [stylingTrait];
stylingOccasionFixture: object;
stylingOutfitFixture: object;
stylingPrepFixture: RpgExpandedStylingPreparation id = 'reception-outfit' designer = stylingDesigner wearer = crossPhysician
    occasion = stylingOccasionFixture outfit = stylingOutfitFixture description = 'A repaired coat with a coordinated scarf'
    plannedInAdvance = true approved = true evidence = 'The stylist assembled this outfit before the reception';
modify appearanceReaction stylingPreparation = stylingPrepFixture stylingOccasion = stylingOccasionFixture
    stylingOutfit = stylingOutfitFixture stylingWorn = true stylingSocialSituation = true stylingEvidence = 'The outfit is worn at the reception';
modify PhysicianFixtureAction
    exec(context)
    {
        local code = healthInput.code;
        if (code == 25000 || code == 25001)
        { stylingPrepFixture.prepare(); if (code == 25001) throw new RpgError(); return nil; }
        if (code == 25002)
        { event('test.styling'); eventValue(rpgLiteReactionModifier(crossPhysician,appearanceReaction));
          eventValue(crossPhysician.stylingPreparations.length()); eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil; }
        if (code == 25003) { appearanceReaction.stylingWorn = nil; return nil; }
        if (code == 25004) { appearanceReaction.stylingOccasion = nil; return nil; }
        if (code == 25005) { appearanceReaction.stylingSocialSituation = nil; return nil; }
        if (code == 25006) { stylingTrait.mitigated = true; return nil; }
        if (code == 25007)
        { local value = stylingPrepFixture.assess(); event('test.styling-preview'); eventValue(value.status); eventValue(value.reason);
          eventValue(crossPhysician.stylingPreparations.length()); return nil; }
        if (code == 25008)
        {
            stylingPrepFixture.description = 'A different outfit';
            try { stylingPrepFixture.assess(); }
            catch (RpgExpandedError error) { event('test.styling-error'); eventValue(error.reason); }
            return nil;
        }
        return inherited(context);
    }
;
