#include "expanded-nausea.t"
triggerContext: RpgExpandedRetchingContext profile = radiationProfile approved = true evidence = 'Vomiting after a nausea trigger';
triggerRetching: RpgExpandedRetching id = 'nausea-vomit' context = triggerContext approved = true
    evidence = 'The current trigger caused vomiting' oralEffectsReviewed = true;
nauseaTrigger: RpgExpandedNauseaTrigger eventId = 'meal-one' profile = radiationProfile kind = 'meal'
    observedAt = 0 approved = true evidence = 'The nauseated patient just finished eating' episode = triggerRetching;
triggerEnd: RpgExpandedRetchingRecovery id = 'fixed-end' episode = triggerRetching;
modify RadiationTestAction
    exec(context)
    {
        local code = radiationInput.code;
        if (code == 40) { rpgRandom.seed(6); return nil; }
        if (code == 41) { triggerRetching.oralEffectsReviewed = nil; return nil; }
        if (code >= 50 && code <= 52)
        {
            local value = code == 51 ? nauseaTrigger.assess() : nauseaTrigger.apply();
            event('test.nausea-trigger-result'); eventValue(value.status); eventValue(value.reason);
            if (code == 52) throw new RpgError(); return nil;
        }
        if (code == 53) { triggerEnd.apply(); return nil; }
        if (code == 54)
        {
            event('test.nausea-trigger'); eventValue(radiationProfile.nauseaTriggers.length());
            eventValue(radiationProfile.retchingEpisode != nil ? 1 : 0); eventValue(radiationProfile.fatigue);
            eventValue(triggerRetching.initialEnd); eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
        }
        return inherited(context);
    }
;
