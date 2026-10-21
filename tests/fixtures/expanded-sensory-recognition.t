#include "expanded-chemical.t"
fineHearingFixture: RpgExpandedSensoryRecognition id = 'fine-hearing' sense = 'hearing' approved = true;
fineSmellFixture: RpgExpandedSensoryRecognition id = 'fine-smell' sense = 'smell' approved = true;
fineTasteFixture: RpgExpandedSensoryRecognition id = 'fine-taste' sense = 'taste' approved = true;
modify PhysicianFixtureAction
    exec(context)
    {
        local code = healthInput.code;
        if (code == 28000)
        { crossPhysician.traits = crossPhysician.traits + [fineHearingFixture,fineSmellFixture,fineTasteFixture]; return nil; }
        if (code == 28001)
        { event('test.fine-senses'); eventValue(rpgLiteScore(crossPhysician,hearingContextFixture));
          eventValue(rpgLiteScore(crossPhysician,chemicalContextFixture)); eventValue(fineHearingFixture.creationCost());
          eventValue(fineSmellFixture.creationCost()); eventValue(fineTasteFixture.creationCost());
          eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil; }
        if (code == 28002) { fineSmellFixture.mitigated = true; return nil; }
        if (code == 28003) { fineTasteFixture.active = nil; return nil; }
        if (code == 28004) { fineHearingFixture.percentages = [-30]; fineHearingFixture.creationCost(); return nil; }
        if (code == 28005)
        { crossPhysician.traits = crossPhysician.traits + [fineHearingFixture]; crossPhysician.validateFeatures(); return nil; }
        if (code == 28006)
        {
            local original = rpgExpandedTemplateTraits.plain('fine-smell',1,nil);
            local copied = rpgExpandedTemplateTraits.copy(original); copied.mitigated = true;
            event('test.fine-template'); eventValue(original.creationCost()); eventValue(copied.creationCost());
            eventValue(original != copied); eventValue(original.mitigated); eventValue(copied.mitigated); return nil;
        }
        return inherited(context);
    }
;
