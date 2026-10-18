#include "expanded-swim-negative-fatigue.t"
#include <vhyl-rpg-expanded-hazards.t>
swimSubmersion: RpgExpandedDrowningExposure id = 'underwater' profile = swimPatient swimming = swimEncounter
    approved = true evidence = 'The unconscious swimmer is fully submerged without air';
swimAirSecond: RpgExpandedAirlessSecond id = 'first-second' exposure = swimSubmersion;
modify SwimFixtureAction
    exec(context)
    {
        local code = swimInput.code;
        if (code == 17300 || code == 17301)
        {
            local value = swimSubmersion.start(); event('test.submersion-result'); eventValue(value.status); eventValue(value.reason);
            if (code == 17301) throw new RpgError(); return nil;
        }
        if (code == 17302)
        {
            event('test.submersion'); eventValue(swimPatient.swimmingEncounter == nil); eventValue(swimPatient.airlessExposure == swimSubmersion);
            eventValue(swimPatient.airClock); eventValue(swimPatient.fp()); eventValue(swimPatient.injury); eventValue(rpgLedger.seconds); return nil;
        }
        if (code == 17303) { rpgSpendTime(1); swimAirSecond.apply(); return nil; }
        if (code == 17304)
        { event('test.submersion-rescue'); eventValue(swimSubmersion.resumeAir('Head lifted clear').reason); return nil; }
        return inherited(context);
    }
;
