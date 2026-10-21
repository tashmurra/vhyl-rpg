#include "expanded-packing-attempt.t"
modify packingAttempt task = 'route' difficult = nil finding = 'The eastern pass is suitable for these pack animals'
    evidence = 'Surveyed trail and animal capability establish this route recommendation';
modify PhysicianFixtureAction
    exec(context)
    {
        local code = healthInput.code;
        if (code == 22600 || code == 22601)
        { local value = code == 22600 ? packingAttempt.resolve() : packingAttempt.assess();
          event('test.packing-finding'); eventValue(value.status); eventValue(value.reason); eventValue(value.finding); return nil; }
        if (code == 22602) { packingAttempt.finding = nil; return nil; }
        if (code == 22603) { packingAttempt.task = 'evaluate'; packingAttempt.finding = 'This animal can carry the proposed load'; return nil; }
        if (code == 22604 || code == 22605 || code == 22606)
        {
            if (code == 22604) packingAttempt.finding = 'Changed recommendation';
            else if (code == 22605) packingAttempt.result.finding = 'Invented result';
            else packingAttempt.task = 'load';
            try { packingAttempt.resolve(); }
            catch (RpgExpandedError error) { event('test.packing-finding-error'); eventValue(error.reason); }
            return nil;
        }
        return inherited(context);
    }
;
