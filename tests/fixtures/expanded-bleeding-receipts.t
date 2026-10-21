#include "expanded-bleeding.t"
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 77)
        {
            event('test.bleeding-receipt'); eventValue(bleedAid.startedAt); eventValue(bleedAid.completesAt);
            eventValue(bleedAid.completedAt);
            eventValue(bleedAid.result == nil ? nil : bleedAid.result.stopped);
            eventValue(bleedAid.result == nil ? nil : bleedAid.result.healed);
            eventValue(bleedAid.result == nil ? nil : bleedAid.result.reason);
            eventValue(bleedAid.result == nil || bleedAid.result.check == nil ? nil : bleedAid.result.check.roll);
            return nil;
        }
        if (code >= 70 && code <= 76)
        {
            if (code == 70) bleedAid.startedAt += 1;
            if (code == 71) bleedAid.completesAt -= 1;
            if (code == 72) bleedAid.completedAt += 1;
            if (code == 73) bleedAid.result.stopped = nil;
            if (code == 74) bleedAid.result.check.roll += 1;
            if (code == 75) bleedAid.result.healed += 1;
            if (code == 76) bleedAid.result.reason = 'changed';
            bleedAid.assess();
            event('test.bleeding-tamper-accepted'); return nil;
        }
        return inherited(context);
    }
;
