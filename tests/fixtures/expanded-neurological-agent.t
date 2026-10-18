#include "expanded-poison-exposure.t"
neurologicalParalysis: RpgExpandedParalysis id = 'agent-paralysis' profile = bleedProfile durationSeconds = 120
    approved = true positionAssessed = true balanced = nil evidence = 'Authored two-minute paralysis for this agent';
neurologicalSeizure: RpgExpandedSeizure id = 'agent-seizure' profile = bleedProfile durationSeconds = 60
    approved = true evidence = 'Authored one-minute seizure for this agent';
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 480)
        {
            poisonExposure.hazard = rpgExpandedPoisonCatalogue('neurological-agent','contact');
            poisonDelivery.route = 'contact'; poisonDelivery.method = 'area'; poisonDelivery.inArea = true;
            poisonExposure.preparedForAgent = true; poisonExposure.preparationEvidence = 'Patient is briefed on this hazard';
            poisonExposure.associatedCondition = neurologicalParalysis;
            poisonExposure.associatedPolicy = 'first-failed-cycle';
            poisonExposure.associationEvidence = 'Author chooses onset at the first failed cycle, with no refresh on later cycles';
            return nil;
        }
        if (code == 481) { poisonExposure.associatedCondition = nil; return nil; }
        if (code == 482) { poisonExposure.associatedCondition = neurologicalSeizure; return nil; }
        if (code == 483) { poisonExposure.associatedPolicy = 'every-cycle'; return nil; }
        if (code == 484) { neurologicalParalysis.durationSeconds = 121; return nil; }
        if (code == 485)
        {
            event('test.neurological'); eventValue(poisonExposure.started ? 1 : 0);
            eventValue(poisonExposure.remaining); eventValue(bleedProfile.injury);
            eventValue(bleedProfile.paralyzed() ? 1 : 0); eventValue(bleedProfile.seizing() ? 1 : 0);
            eventValue(poisonExposure.associatedApplied ? 1 : 0);
            eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 486) { neurologicalSeizure.finish(); return nil; }
        return inherited(context);
    }
;
