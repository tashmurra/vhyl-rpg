#include "expanded-march-hour.t"
marchPartnerLoad: RpgLiteItem id = 'march-load' weight = 3000;
marchPartner: RpgExpandedProfile rules = bleedRules equipment = [marchPartnerLoad];
marchPartnerHour: RpgExpandedMarchHour id = 'partner-hour' profile = marchPartner interval = marchInterval
    approved = true evidence = 'Same continuous hour for the loaded partner' dropDestination = bleedRoom;
marchGroup: RpgExpandedMarchGroup id = 'concurrent-hour' hours = [marchExecution,marchPartnerHour];
modify rpgLedger
    afterAdvance(previous)
    {
        inherited(previous);
        if (bleedInput.code == 23505) marchPartner.fatigue += 1;
        return nil;
    }
;
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 23500 || code == 23501 || code == 23505)
        { local value = marchGroup.apply(); event('test.march-group'); eventValue(value.status); eventValue(value.reason); eventValue(value.allowed ? 1 : 0);
          if (code == 23501) throw new RpgError(); return nil; }
        if (code == 23502)
        { local value = marchGroup.assess(); event('test.march-group-preview'); eventValue(value.status); eventValue(value.reason); return nil; }
        if (code == 23503)
        { event('test.march-group-state'); eventValue(rpgLedger.seconds); eventValue(bleedProfile.fatigue); eventValue(marchPartner.fatigue);
          eventValue(bleedProfile.marchHours.length()); eventValue(marchPartner.marchHours.length()); eventValue(rpgRandom.draws); return nil; }
        if (code == 23504) { marchExecution.apply(); marchPartnerHour.apply(); return nil; }
        return inherited(context);
    }
;
