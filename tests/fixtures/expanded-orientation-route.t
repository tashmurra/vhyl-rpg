#include "expanded-orientation-sense.t"
#include <vhyl-rpg-expanded-exploration.t>
orientationJourney: RpgLiteJourney profile = bleedProfile;
orientationRoute: RpgExpandedOrientationRoute id = 'canal-path' journey = orientationJourney
    waypoints = ['gate','bridge','tower'] approved = true evidence = 'The authored journey follows this ordered path';
orientationNorth: RpgExpandedNorthAssessment profile = bleedProfile northDirection = 'toward-ridge'
    approved = true evidence = 'World author establishes local north toward the ridge';
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 9500 || code == 9508)
        { orientationRoute.begin(); if (code == 9508) throw new RpgError(); return nil; }
        if (code == 9501) { orientationJourney.advance(10); return nil; }
        if (code == 9502 || code == 9509)
        {
            local value = orientationRoute.complete(true,'Author confirms arrival via the listed waypoints');
            event('test.orientation-arrival'); eventValue(value.status); eventValue(value.reason);
            if (code == 9509) throw new RpgError(); return nil;
        }
        if (code == 9503 || code == 9504 || code == 9505)
        {
            local value = orientationRoute.retrace(bleedProfile,code == 9504 ? 1 : 0,
                'Author supplies the current calendar month cutoff',code == 9505 ? 'gate' : 'tower',true);
            event('test.orientation-route'); eventValue(value.status); eventValue(value.reason);
            foreach (local point in value.path) eventValue(point); return nil;
        }
        if (code == 9506)
        {
            local value = orientationNorth.assess(); event('test.orientation-north');
            eventValue(value.status); eventValue(value.north); return nil;
        }
        if (code == 9507) { orientationRoute.assess(); return nil; }
        if (code == 9511) { orientationRoute.abandon('The route was interrupted'); return nil; }
        if (code == 9510)
        {
            event('test.orientation-route-state'); eventValue(bleedProfile.orientationRoutes.length());
            eventValue(orientationRoute.completedAt); eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        return inherited(context);
    }
;
