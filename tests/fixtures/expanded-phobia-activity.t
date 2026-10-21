#include "expanded-phobia.t"
heightPhobia: RpgExpandedPhobia scope = 'heights' points = -10 approved = true;
powerPhobia: RpgExpandedPhobia scope = 'psi' prevalence = 'common' points = -15 approved = true;
phobiaActivity: RpgExpandedPhobiaActivity profile = fearProfile kind = 'height' approved = true
    evidence = 'The action would voluntarily step onto the indicated ledge';
phobiaEffort: RpgExpandedActionGate id = 'ledge' profile = fearProfile phobiaActivity = phobiaActivity
    evidence = 'Permission for the authored voluntary action';
modify FearTestAction
    exec(context)
    {
        local code = fearInput.code;
        if (code == 530) { fearProfile.traits = [heightPhobia]; phobiaActivity.heightFeet = 15; return nil; }
        if (code == 531) { phobiaActivity.heightFeet = 16; return nil; }
        if (code == 532) { phobiaActivity.insideBuilding = true; phobiaActivity.awayFromWindows = true; return nil; }
        if (code == 533) { fearProfile.traits = [powerPhobia]; phobiaActivity.kind = 'power-consent'; phobiaActivity.heightFeet = 0; return nil; }
        if (code == 534)
        { local value = phobiaEffort.assess(); event('test.phobia-activity'); eventValue(value.status); eventValue(value.reason);
          eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil; }
        if (code == 535 || code == 536) { phobiaEffort.apply(); if (code == 536) throw new RpgError(); return nil; }
        if (code == 537) { event('test.phobia-effort'); eventValue(fearProfile.effortHistory.length()); return nil; }
        return inherited(context);
    }
;
