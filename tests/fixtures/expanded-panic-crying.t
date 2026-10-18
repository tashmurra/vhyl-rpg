#include "expanded-fear-panic.t"
cryGate: RpgExpandedActionGate id = 'crying-health' profile = bleedProfile purpose = 'do-nothing'
    evidence = 'Stationary crying during the authored panic episode';
cryActivity: RpgExpandedFearPanicCrying id = 'crying-interval' episode = panicEpisode seconds = 60 healthGate = cryGate;
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 10700)
        {
            event('test.crying-preview'); local value = cryActivity.assess(); eventValue(value.status); eventValue(value.reason);
            eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 10701 || code == 10702)
        {
            local value = cryActivity.apply(); event('test.crying-result'); eventValue(value.status); eventValue(value.seconds);
            if (code == 10702) throw new RpgError(); return nil;
        }
        if (code == 10703)
        {
            event('test.crying-state'); eventValue(panicEpisode.activities.length()); eventValue(bleedProfile.effortHistory.length());
            eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 10704)
        {
            event('test.panic-gates'); eventValue(bleedProfile.healthEffortReason('action',nil,nil,true));
            eventValue(bleedProfile.healthEffortReason('do-nothing',nil,nil,nil));
            eventValue(bleedProfile.healthManeuverReason('attack')); eventValue(bleedProfile.healthManeuverReason('nothing')); return nil;
        }
        if (code == 10705) { cryActivity.seconds = 61; return nil; }
        return inherited(context);
    }
;
