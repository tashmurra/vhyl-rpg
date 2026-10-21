#include "expanded-fear-aura.t"
fearHearingLoss: RpgExpandedHearingLoss approved = true;
fearHearingAward: RpgExpandedFearPhysicalAcquisition id = 'hearing-loss-outcome' eventId = 'auditory-shock'
    profile = fearProfile tableTotal = 36 purchases = [fearHearingLoss] approved = true
    evidence = 'The selected lasting physical outcome is complete hearing loss';
fearHearingContext: RpgLiteContext attribute = rpgPerception kind = 'hearing';
modify eventAura sense = 'hearing';
modify FearTestAction
    exec(context)
    {
        local code = fearInput.code;
        if (code == 690) { fearProfile.creationComplete = true; fearProfile.disadvantageLimit = 0; return nil; }
        if (code == 691 || code == 692)
        { fearHearingAward.apply(); if (code == 692) throw new RpgError(); return nil; }
        if (code == 693)
        {
            event('test.fear-hearing-loss'); eventValue(fearProfile.traits.length());
            eventValue(fearProfile.postCreationDisadvantageAllowance()); eventValue(rpgLiteScore(fearProfile,fearHearingContext));
            eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
        }
        if (code == 694) { fearHearingLoss.mitigated = true; return nil; }
        if (code == 695) { eventAura.sense = 'sight'; return nil; }
        return inherited(context);
    }
;
