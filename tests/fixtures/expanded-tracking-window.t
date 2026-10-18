#include "expanded-tracking-context.t"
trackingWindowInput: object elapsed = 0 requested = 0;
modify PhysicianFixtureAction
    exec(context)
    {
        local code = healthInput.code;
        if (code == 28600)
        {
            local value = rpgExpandedTrackingWindow(trackingContextFixture.terrain,trackingWindowInput.elapsed,trackingWindowInput.requested);
            event('test.tracking-window'); eventValue(value.status); eventValue(value.reason); eventValue(value.seconds);
            eventValue(value.elapsed); eventValue(value.remaining); eventValue(value.unusedSeconds); eventValue(value.checkDue ? 1 : 0);
            eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 28601) { trackingWindowInput.requested = 1; return nil; }
        if (code == 28602) { trackingWindowInput.requested = 2147483647; return nil; }
        if (code == 28603)
        { trackingWindowInput.elapsed = rpgExpandedTrackingTerrain(trackingContextFixture.terrain).interval-1; return nil; }
        if (code == 28604)
        { trackingWindowInput.elapsed = rpgExpandedTrackingTerrain(trackingContextFixture.terrain).interval; return nil; }
        if (code == 28605) { trackingWindowInput.requested = 59; return nil; }
        if (code == 28606) { trackingWindowInput.elapsed = 59; return nil; }
        if (code == 28607)
        { rpgExpandedTrackingWindow(trackingContextFixture.terrain,-1,1); return nil; }
        if (code == 28608)
        { rpgExpandedTrackingWindow(trackingContextFixture.terrain,rpgExpandedTrackingTerrain(trackingContextFixture.terrain).interval+1,1); return nil; }
        return inherited(context);
    }
;
