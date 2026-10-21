#include "expanded-pressure.t"
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code >= 8400 && code <= 8410)
        {
            local rows = [[200,100,0,100000,true],[250,100,0,4800,true],[250,100,0,4801,true],
                [400,100,0,1320,true],[550,100,0,1,true],[300,100,0,60,true],
                [500,200,0,60,true],[1000,100,1,100000,true],[1001,100,1,60,true],
                [1000000,100,2,100000,true],[250,100,0,60,nil]];
            local row = rows[code - 8399];
            local value = rpgExpandedAssessDecompression(row[1],row[2],row[3],row[4],row[5]);
            event('test.decompression-assessment'); eventValue(value.status); eventValue(value.reason);
            eventValue(value.safeReturn ? 1 : 0); eventValue(value.slowRequired ? 1 : 0);
            eventValue(value.referenceSafeSeconds); eventValue(value.approximate ? 1 : 0);
            eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 8411)
        {
            pressureExposure.pressure = 250; pressureExposure.begin(); rpgSpendTime(4800); pressureExposure.end();
            local value = pressureExposure.assessReturnToNative(true);
            event('test.decompression-exposure'); eventValue(value.safeReturn ? 1 : 0);
            eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        return inherited(context);
    }
;
