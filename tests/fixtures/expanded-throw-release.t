#include "expanded-throw-attempt.t"
throwRelease: RpgExpandedThrownRelease id = 'released-stone' receipt = throwAttempt;
throwLanding: RpgExpandedThrowLanding release = throwRelease destination = bleedRoom
    consequencesResolved = true evidence = 'The pass comes to rest on the authored padded floor; no impact consequences remain';
throwRetrieve: RpgExpandedEquipmentStorage profile = bleedProfile item = throwStone accessible = true;
throwSale: RpgExpandedTradeTransfer id = 'flight-sale' seller = bleedProfile buyer = catchProfile item = throwStone
    buyerAgrees = true sellerAgrees = true available = true permitted = true;
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 1200 || code == 1201)
        { throwRelease.apply(); if (code == 1201) throw new RpgError(); return nil; }
        if (code == 1202)
        {
            event('test.throw-release'); eventValue(throwStone.thrownFlight != nil ? 1 : 0);
            eventValue(bleedProfile.loadHundredths()); eventValue(throwStone.ready ? 1 : 0);
            eventValue(throwStone.storageLocation == bleedRoom ? 1 : 0);
            eventValue(bleedProfile.thrownReleases.length()); eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
        }
        if (code == 1203)
        { event('test.throw-retrieve'); eventValue(throwRetrieve.move().status); eventValue(throwSale.assess().reason); return nil; }
        if (code == 1204 || code == 1205)
        { throwLanding.apply(); if (code == 1205) throw new RpgError(); return nil; }
        if (code == 1206)
        {
            event('test.throw-clock');
            try { rpgSpendTime(1); eventValue('advanced'); }
            catch (RpgExpandedError error) { eventValue(error.reason); }
            return nil;
        }
        if (code == 1207) { throwLanding.consequencesResolved = nil; return nil; }
        if (code == 1208)
        { local value = throwRelease.assess(); event('test.throw-release-preview'); eventValue(value.status); eventValue(value.reason); return nil; }
        if (code == 1209) { bleedInput.forcedRoll = 18; return nil; }
        return inherited(context);
    }
;
