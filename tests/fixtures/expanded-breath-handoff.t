#include "expanded-airless-transactions.t"
modify airPatient fatigue = 0;
breathExhaustion: RpgExpandedBreathExhaustion id = 'expired-reserve' profile = airPatient reserve = airReserve
    evidence = 'Ordinary air deprivation continues after the fixed mild-activity reserve expires';
breathAirSecond: RpgExpandedAirlessSecond id = 'after-reserve' exposure = breathExhaustion;
modify AirFixtureAction
    exec(context)
    {
        local code = airInput.code; local value = nil;
        if (code == 17800) { rpgSpendTime(40); return nil; }
        if (code == 17801 || code == 17802)
        {
            value = breathExhaustion.start();
            if (code == 17802) throw new RpgError();
        }
        else if (code == 17803) { rpgSpendTime(1); value = breathAirSecond.apply(); }
        else if (code == 17804) value = breathExhaustion.resumeAir('Ventilation restored');
        else if (code == 17805) value = airReserve.resumeAir('Ventilation restored');
        else if (code == 17806)
        {
            event('test.breath-handoff-state'); eventValue(airPatient.breathReserve != nil);
            eventValue(airPatient.airlessExposure != nil); eventValue(airPatient.airClock); eventValue(airPatient.fatigue);
            eventValue(airPatient.injury); eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        else if (code == 17807) value = breathExhaustion.assessStart();
        else return inherited(context);
        event('test.breath-handoff-result'); eventValue(value.status); eventValue(value.reason); return nil;
    }
;
