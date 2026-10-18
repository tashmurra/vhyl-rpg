#include "expanded-postmortem.t"
bodyRecognizable: RpgExpandedBodyAssessment id = 'puncture-remains' profile = bleedProfile disposition = 'recognizable'
    approved = true evidence = 'Author determines that the accumulated punctures leave recognizable remains';
bodyDestroyed: RpgExpandedBodyAssessment id = 'burned-remains' profile = bleedProfile disposition = 'destroyed'
    approved = true evidence = 'Author determines that subsequent incineration destroys the body';
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 7700 || code == 7701 || code == 7702)
        {
            local value = code == 7700 ? bodyRecognizable.assess()
                : code == 7701 ? bodyRecognizable.apply() : bodyDestroyed.apply();
            event('test.body-assessment'); eventValue(value.status); eventValue(value.reason); eventValue(value.disposition); return nil;
        }
        if (code == 7703)
        {
            event('test.body-state'); eventValue(bleedProfile.bodyIntegrity()); eventValue(bleedProfile.hp());
            eventValue(bleedProfile.bodyAssessments.length()); eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 7704) { bodyRecognizable.apply(); throw new RpgError(); }
        if (code == 7705) { bodyRecognizable.evidence = 'Changed judgment'; return nil; }
        if (code == 7706)
        {
            event('test.body-error');
            try { bleedProfile.bodyIntegrity(); eventValue('accepted'); }
            catch (RpgExpandedError error) { eventValue(error.reason); }
            return nil;
        }
        return inherited(context);
    }
;
