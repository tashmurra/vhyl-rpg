#include "expanded-sustenance-contact.t"
sustenanceRestart: RpgExpandedSustenanceContact episode = sustenanceEpisode boundaryOrder = 'access-first'
    contactPolicy = 'uninterrupted' approved = true evidence = 'The subject returns to qualifying contact';
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 11900) { rpgSpendTime(1800); return nil; }
        if (code == 11901 || code == 11902)
        {
            sustenanceContact.interrupt(true,'The subject leaves the required environment');
            if (code == 11902) throw new RpgError(); return nil;
        }
        if (code == 11903) { sustenanceRestart.begin(); return nil; }
        if (code == 11904)
        {
            local value = sustenanceRestart.assessCompletion(); event('test.sustenance-restart-preview');
            eventValue(value.status); eventValue(value.reason); return nil;
        }
        if (code == 11905) { sustenanceRestart.finish(true,'Contact remained uninterrupted throughout this new interval'); return nil; }
        if (code == 11906)
        {
            event('test.sustenance-interruption'); eventValue(sustenanceContact.interruptedAt);
            eventValue(sustenanceEpisode.contacts.length()); eventValue(sustenanceEpisode.restoration == nil ? 0 : 1);
            eventValue(bleedProfile.injury); eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        return inherited(context);
    }
;
