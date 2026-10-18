#include "expanded-bleeding.t"
#include <vhyl-rpg-expanded-traits.t>
recurrentPain: RpgExpandedRecurrentPain approved = true;
modify bleedProfile traits = [recurrentPain];
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 4500)
        {
            event('test.recurrent-pain-table');
            foreach (local severity in [1,2,3])
                foreach (local hours in [1,2,4,8])
                    foreach (local frequency in [6,9,12,15])
                    {
                        recurrentPain.severity = severity; recurrentPain.intervalHours = hours; recurrentPain.frequency = frequency;
                        eventValue(recurrentPain.creationCost());
                    }
            return nil;
        }
        if (code == 4501)
        {
            event('test.recurrent-pain-definition');
            foreach (local severity in [1,2,3])
            { recurrentPain.severity = severity; eventValue(recurrentPain.awakePenalty()); }
            foreach (local hours in [1,2,4,8])
            { recurrentPain.intervalHours = hours; eventValue(recurrentPain.intervalSeconds()); }
            foreach (local frequency in [6,9,12,15])
            {
                recurrentPain.frequency = frequency;
                eventValue(recurrentPain.appears(frequency-1) ? 1 : 0);
                eventValue(recurrentPain.appears(frequency) ? 1 : 0);
                eventValue(recurrentPain.appears(frequency+1) ? 1 : 0);
            }
            eventValue(rpgRandom.draws); return nil;
        }
        if (code == 4502 || code == 4503 || code == 4504)
        {
            if (code == 4502) recurrentPain.severity = 4;
            if (code == 4503) recurrentPain.intervalHours = 3;
            if (code == 4504) recurrentPain.frequency = 10;
            event('test.recurrent-pain-invalid');
            try { recurrentPain.creationCost(); eventValue('accepted'); }
            catch (RpgExpandedError error) { eventValue(error.reason); }
            return nil;
        }
        return inherited(context);
    }
;
