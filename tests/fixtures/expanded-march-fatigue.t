#include "expanded-bleeding.t"
marchInterval: object;
marchCost: RpgExpandedMarchHourCost id = 'march-hour' profile = bleedProfile interval = marchInterval
    approved = true evidence = 'The resolved hour of road travel' dropDestination = bleedRoom;
marchCombatCost: RpgExpandedMarchHourCost id = 'combat-stop' profile = bleedProfile interval = marchInterval
    basis = 'combat-assumed-hour' approved = true evidence = 'Combat interrupts this same marching interval' dropDestination = bleedRoom;
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 1130)
        {
            local value = marchCost.assess(); event('test.march-preview'); eventValue(value.status);
            eventValue(value.reason); eventValue(value.fatigueCost); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 1131 || code == 1132)
        { marchCost.apply(); if (code == 1132) throw new RpgError(); return nil; }
        if (code == 1133)
        {
            event('test.march-owned'); eventValue(bleedProfile.fatigue); eventValue(bleedProfile.injury);
            eventValue(bleedProfile.marchHours.length()); eventValue(bleedProfile.marchFatigueLosses.length());
            eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
        }
        if (code == 1134) { marchCost.hot = true; marchCost.heavyClothing = true; bleedProfile.heatExtra = 2; return nil; }
        if (code == 1135) { marchCost.cooling = true; return nil; }
        if (code == 1136) { bleedProfile.fatigue = 9; return nil; }
        if (code == 1137)
        {
            event('test.march-combat');
            try { eventValue(marchCombatCost.apply().status); }
            catch (RpgExpandedError error) { eventValue(error.reason); }
            return nil;
        }
        if (code == 1138)
        {
            event('test.march-table');
            for (local encumbrance = 0; encumbrance <= 4; encumbrance += 1)
                foreach (local flags in [[nil,nil,nil],[true,nil,nil],[true,true,nil],[true,true,true]])
                    eventValue(rpgExpandedMarchFatigueCost(encumbrance,flags[1],flags[2],flags[3]));
            eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
        }
        return inherited(context);
    }
;
