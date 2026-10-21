#include "expanded-acceleration.t"
freeFall: RpgExpandedFreeFallExposure id = 'station-entry' profile = bleedProfile
    approved = true evidence = 'Author confirms nonnative physiology and first entry into sustained free fall';
freeFallRecovery: RpgExpandedFreeFallAdaptation exposure = freeFall;
modify BleedTestAction
    exec(actionContext)
    {
        local code = bleedInput.code;
        if (code == 9100 || code == 9101 || code == 9102)
        {
            local value = code == 9101 ? freeFall.assess() : freeFall.apply();
            event('test.free-fall-result'); eventValue(value.status); eventValue(value.reason);
            if (code == 9102) throw new RpgError(); return nil;
        }
        if (code == 9103) { bleedInput.forcedRoll = 11; return nil; }
        if (code == 9104)
        {
            event('test.free-fall'); eventValue(bleedProfile.nauseated() ? 1 : 0); eventValue(freeFall.adapted ? 1 : 0);
            eventValue(freeFall.checks.length()); eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 9105)
        {
            for (local hour = 1; hour <= 8; hour += 1)
            {
                rpgSpendTime(3600);
                local context = new RpgExpandedRetchingContext(); context.profile = bleedProfile;
                context.approved = true; context.evidence = 'Potential vomiting during continuing free fall';
                local retching = new RpgExpandedRetching(); retching.id = 'free-fall-hour:' + hour;
                retching.context = context; retching.approved = true; retching.evidence = context.evidence; retching.oralEffectsReviewed = true;
                local check = new RpgExpandedNauseaMotionHour(); check.eventId = retching.id;
                check.profile = bleedProfile; check.motion = freeFall.motion; check.observedAt = rpgLedger.seconds;
                check.approved = true; check.evidence = context.evidence; check.episode = retching;
                if (check.apply().status != 'resolved') throw new RpgError();
            }
            return nil;
        }
        if (code == 9106)
        { local value = freeFallRecovery.apply(); event('test.free-fall-recovery'); eventValue(value.status); eventValue(value.reason); return nil; }
        if (code == 9111)
        {
            local nausea = new RpgExpandedNausea(); nausea.id = 'independent-cause'; nausea.profile = bleedProfile;
            nausea.approved = true; nausea.causeEvidence = 'A separate cause remains after leaving free fall'; nausea.apply(); return nil;
        }
        if (code == 9110) { bleedProfile.dx = 20; return nil; }
        if (code == 9107) { freeFall.native = true; return nil; }
        if (code == 9108) { freeFall.susceptible = true; return nil; }
        if (code == 9109) { freeFall.leave(true,'Returned to normal gravity'); return nil; }
        return inherited(actionContext);
    }
;
