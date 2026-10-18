#include "expanded-hiking-party.t"
hikingFirstDay: RpgExpandedTravelDay id = 'first-travel-day' profile = bleedProfile approved = true evidence = 'Full day on the trail';
hikingPartnerDay: RpgExpandedTravelDay id = 'partner-travel-day' profile = hikingPartner approved = true evidence = 'Full day on the trail';
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 24100) { hikingFirstDay.reserve(); hikingPartnerDay.reserve(); return nil; }
        if (code == 24101)
        {
            local value = hikingParty.assessFullDayPace(hikingConditions,[100,100],[hikingFirstDay,hikingPartnerDay]);
            event('test.party-day'); eventValue(value.status); eventValue(value.reason); eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
        }
        if (code == 24102) { hikingPartnerDay.interrupt('The partner stops to investigate'); return nil; }
        if (code >= 24103 && code <= 24106)
        {
            event('test.party-day-error');
            try
            {
                if (code == 24103) hikingParty.assessFullDayPace(hikingConditions,[100,100],[hikingPartnerDay,hikingFirstDay]);
                else
                {
                    if (code == 24104) hikingParty.result.profiles = [bleedProfile];
                    if (code == 24105) hikingParty.result.day += 1;
                    if (code == 24106) hikingParty.result.bonusAchieved = !hikingParty.result.bonusAchieved;
                    hikingParty.assess();
                }
                eventValue(nil);
            }
            catch (RpgExpandedError error) { eventValue(error.reason); }
            return nil;
        }
        return inherited(context);
    }
;
