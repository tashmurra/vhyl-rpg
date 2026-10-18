#include "expanded-sustenance-injury.t"
sustenanceContact: RpgExpandedSustenanceContact episode = sustenanceEpisode boundaryOrder = 'access-first'
    approved = true evidence = 'Contact with the required environment begins now';
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 11800) { sustenanceContact.begin(); return nil; }
        if (code == 11801)
        {
            local value = sustenanceContact.assessCompletion(); event('test.sustenance-contact-preview');
            eventValue(value.status); eventValue(value.reason); return nil;
        }
        if (code == 11802 || code == 11803)
        {
            sustenanceContact.finish(true,'The author confirms uninterrupted qualifying contact throughout the recorded interval');
            if (code == 11803) throw new RpgError(); return nil;
        }
        if (code == 11804) { sustenanceContact.boundaryOrder = 'injury-first'; return nil; }
        if (code == 11805)
        {
            event('test.sustenance-contact-state'); eventValue(sustenanceEpisode.restoration == nil ? 0 : 1);
            eventValue(bleedProfile.injury); eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        return inherited(context);
    }
;
