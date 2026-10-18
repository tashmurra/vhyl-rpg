#include "expanded-fear-quirks.t"
#include <vhyl-rpg-expanded-health.t>
quirkFearContext: RpgExpandedFearContext profile = quirkProfile approved = true evidence = 'The doorway apparition';
quirkStun: RpgExpandedFearStun id = 'apparition' context = quirkFearContext tableTotal = 16 approved = true
    evidence = 'Recorded combined outcome' quirkAcquisition = quirkAward;
quirkStunRecovery: RpgExpandedFearStunRecovery id = 'first' episode = quirkStun;
quirkMissingModule: RpgExpandedFearQuirkContract profile = quirkProfile eventId = 'apparition';
modify QuirkTestAction
    exec(context)
    {
        local code = quirkInput.code;
        if (code < 20) return inherited(context);
        if (code == 23) { rpgSpendTime(2); return nil; }
        if (code == 27) { quirkProfile.willAdjustment = 10; return nil; }
        if (code == 28) { quirkStun.quirkAcquisition = nil; return nil; }
        if (code == 29) { quirkStun.quirkAcquisition = quirkMissingModule; return nil; }
        if (code <= 22)
        {
            local value = code == 21 ? quirkStun.assess() : quirkStun.apply();
            event('test.quirk-stun-start'); eventValue(value.status); eventValue(value.reason);
            if (code == 22) throw new RpgError(); return nil;
        }
        local value = code == 26 ? quirkStunRecovery.assess() : quirkStunRecovery.apply();
        event('test.quirk-stun-recovery'); eventValue(value.status); eventValue(value.reason);
        if (code == 25) throw new RpgError(); return nil;
    }
;
modify quirkInput
    reportExtraState()
    {
        event('test.quirk-stun-state'); eventValue(quirkProfile.mentalStun ? 1 : 0);
        eventValue(quirkStun.initialEnd); eventValue(quirkStun.completed ? 1 : 0);
        eventValue(quirkStun.recoveries.length()); eventValue(quirkProfile.fatigue); return nil;
    }
;
