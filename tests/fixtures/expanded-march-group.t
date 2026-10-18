#include "expanded-march-hour.t"
marchPartnerLoad: RpgLiteItem id = 'march-load' weight = 3000;
marchPartner: RpgExpandedProfile rules = bleedRules equipment = [marchPartnerLoad];
marchPartnerHour: RpgExpandedMarchHour id = 'partner-hour' profile = marchPartner interval = marchInterval
    approved = true evidence = 'Same continuous hour for the loaded partner' dropDestination = bleedRoom;
marchGroup: RpgExpandedMarchGroup id = 'concurrent-hour' hours = [marchExecution,marchPartnerHour];
marchDuplicateGroup: RpgExpandedMarchGroup id = 'concurrent-hour' hours = [marchExecution,marchPartnerHour];
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
        if (code >= 23600 && code <= 23604)
        {
            if (code == 23600) marchGroup.result.allowed = nil;
            if (code == 23601) marchGroup.result.seconds = 0;
            if (code == 23602) marchGroup.result.members = [];
            if (code == 23603) bleedProfile.marchGroups = [];
            try { if (code == 23604) marchDuplicateGroup.assess(); else rpgExpandedValidate(marchPartner); }
            catch (RpgExpandedError error) { event('test.march-group-error'); eventValue(error.reason); }
            return nil;
        }
        return inherited(context);
    }
;
