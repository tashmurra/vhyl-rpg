#include "expanded-sustenance-timely-dose.t"
sustenanceNextDeadline: RpgExpandedSustenanceDeadline id = 'following-dose' source = sustenanceEpisode previous = sustenanceDeadline
    approved = true evidence = 'The following period begins at the fulfilled deadline';
sustenanceNextDose: RpgExpandedSustenanceDueDose deadline = sustenanceNextDeadline stock = sustenanceSupply
    approved = true evidence = 'The subject ingests the next scheduled dose';
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 12400) { sustenanceSupply.quantity = 3; return nil; }
        if (code == 12401 || code == 12402)
        { sustenanceNextDeadline.register(); if (code == 12402) throw new RpgError(); return nil; }
        if (code == 12403) { rpgSpendTime(86400); return nil; }
        if (code == 12404) { sustenanceNextDose.apply(); return nil; }
        if (code == 12405)
        {
            event('test.sustenance-recurrence'); eventValue(bleedProfile.sustenanceDeadlines.length());
            eventValue(sustenanceSupply.quantity); eventValue(sustenanceNextDeadline.dueAt);
            eventValue(sustenanceNextDeadline.fulfillment == nil ? 0 : 1); eventValue(bleedProfile.sustenanceDeprivations.length());
            eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 12406)
        { event('test.sustenance-recurrence-preview'); eventValue(sustenanceNextDeadline.assess().reason); return nil; }
        return inherited(context);
    }
;
