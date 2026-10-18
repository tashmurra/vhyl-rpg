#include "expanded-sustenance-deadline.t"
sustenanceInitialContact: RpgExpandedSustenanceContact episode = sustenanceEpisode boundaryOrder = 'access-first'
    contactPolicy = 'uninterrupted' approved = true evidence = 'Initial contact with the required environment';
sustenanceTimelyContact: RpgExpandedSustenanceDueContact deadline = sustenanceDeadline contactPolicy = 'uninterrupted'
    approved = true evidence = 'The subject enters qualifying contact before the next deadline';
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 12300)
        { bleedProfile.traits = [sustenanceTrait]; sustenanceEpisode.begin(); sustenanceInitialContact.begin(); return nil; }
        if (code == 12301)
        { sustenanceInitialContact.finish(true,'The initial qualifying contact was uninterrupted'); sustenanceDeadline.register(); return nil; }
        if (code == 12302) { rpgSpendTime(82800); return nil; }
        if (code == 12303) { sustenanceTimelyContact.begin(); return nil; }
        if (code == 12304)
        {
            local value = sustenanceTimelyContact.assessCompletion(); event('test.sustenance-timely-contact-preview');
            eventValue(value.status); eventValue(value.reason); return nil;
        }
        if (code == 12305 || code == 12306)
        {
            sustenanceTimelyContact.finish(true,'Qualifying contact continued uninterrupted until the deadline');
            if (code == 12306) throw new RpgError(); return nil;
        }
        if (code == 12307)
        {
            event('test.sustenance-timely-contact-state'); eventValue(sustenanceDeadline.fulfillment == nil ? 0 : 1);
            eventValue(bleedProfile.sustenanceDeprivations.length()); eventValue(bleedProfile.injury);
            eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        return inherited(context);
    }
;
