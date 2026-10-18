#include "expanded-march-group.t"
marchPartnerCombat: RpgExpandedMarchHourCost id = 'partner-combat' profile = marchPartner interval = marchInterval
    basis = 'combat-assumed-hour' approved = true evidence = 'Combat interrupts the shared road march' dropDestination = bleedRoom;
marchInterruption: RpgExpandedMarchInterruption id = 'road-encounter' costs = [marchCombatCost,marchPartnerCombat];
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 23800 || code == 23801 || code == 23802)
        { local value = code == 23802 ? marchInterruption.assess() : marchInterruption.apply();
          event('test.march-interruption'); eventValue(value.status); eventValue(value.reason);
          if (code == 23801) throw new RpgError(); return nil; }
        if (code == 23803) { marchInterruption.costs = [marchExecution.result.cost,marchPartnerCombat]; return nil; }
        if (code == 23804) { marchInterruption.costs = [marchExecution.result.cost,marchPartnerHour.result.cost]; return nil; }
        if (code == 23805) { marchPartnerCombat.approved = nil; return nil; }
        return inherited(context);
    }
;
