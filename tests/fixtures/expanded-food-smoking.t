#include "expanded-forage-food.t"
smokingFire: RpgExpandedSmokingFire id = 'campfire' litAt = 0 fuelUntil = 120
    evidence = 'A suitable fire is lit and supplied with fuel through second 120';
smokingBatch: RpgExpandedSmokingBatch id = 'smoke-fish' profile = bleedProfile stock = forageStock fire = smokingFire
    seconds = 60 approved = true evidence = 'The author specifies sixty seconds for this fixture, suitable preparation and sufficient fire capacity for the whole batch';
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 2000 || code == 2001)
        { smokingBatch.start(); if (code == 2001) throw new RpgError(); return nil; }
        if (code == 2002 || code == 2003 || code == 2004)
        {
            local value = code == 2002 ? smokingBatch.assessCompletion() : smokingBatch.complete();
            event('test.smoking-result'); eventValue(value.status); eventValue(value.reason);
            if (code == 2004) throw new RpgError(); return nil;
        }
        if (code == 2005)
        {
            event('test.smoking-state'); eventValue(forageStock.quantity); eventValue(forageStock.preserved ? 1 : 0);
            eventValue(forageStock.readyToEat ? 1 : 0); eventValue(forageStock.smokingBatch == smokingBatch ? 1 : 0);
            eventValue(bleedProfile.smokingBatches.length()); eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 2006) { rpgSpendTime(59); return nil; }
        if (code == 2007) { rpgSpendTime(1); return nil; }
        if (code == 2008) { smokingFire.extinguish(); return nil; }
        if (code == 2009) { smokingBatch.cancel(); return nil; }
        if (code == 2010) { smokingFire.fuelUntil = 59; return nil; }
        if (code == 2011)
        { local value = smokingBatch.assess(); event('test.smoking-result'); eventValue(value.status); eventValue(value.reason); return nil; }
        return inherited(context);
    }
;
