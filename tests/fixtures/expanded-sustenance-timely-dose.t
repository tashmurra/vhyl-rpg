#include "expanded-sustenance-deadline.t"
sustenanceTimelyDose: RpgExpandedSustenanceDueDose deadline = sustenanceDeadline stock = sustenanceSupply
    approved = true evidence = 'The subject ingests a sufficient dose at the scheduled deadline';
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 12200) { sustenanceSupply.quantity = 2; return nil; }
        if (code == 12201)
        {
            local value = sustenanceTimelyDose.assess(); event('test.sustenance-timely-preview');
            eventValue(value.status); eventValue(value.reason); return nil;
        }
        if (code == 12202 || code == 12203)
        { sustenanceTimelyDose.apply(); if (code == 12203) throw new RpgError(); return nil; }
        if (code == 12204)
        {
            event('test.sustenance-timely-state'); eventValue(sustenanceSupply.quantity); eventValue(bleedProfile.equipment.length());
            eventValue(sustenanceDeadline.fulfillment == nil ? 0 : 1); eventValue(bleedProfile.sustenanceDeprivations.length());
            eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 12205)
        { event('test.sustenance-timely-missed'); eventValue(sustenanceDeadline.miss(sustenanceMissed).reason); return nil; }
        return inherited(context);
    }
;
