#include "expanded-shared-carry.t"
carryReleaseInput: object transientLoss = nil;
modify rpgLedger
    afterAdvance(previousSeconds)
    {
        inherited(previousSeconds);
        if (carryReleaseInput.transientLoss)
        {
            carryPartner.becomeUnconscious();
            carryPartner.unconscious = nil;
        }
        return nil;
    }
;
sharedRelease: RpgExpandedSharedCarryRelease carry = sharedCarry member = carryPartner cause = 'unconscious'
    destination = bleedRoom wholeLoadDrops = true evidence = 'Loss of this support drops the whole crate in this arrangement'
    impactResolved = true impactEvidence = 'The authored short drop of the sturdy empty crate onto padding has no additional damage';
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 804)
        {
            carryReleaseInput.transientLoss = true;
            sharedCarry.lower(bleedRoom,2,'The group sets the crate down in an authored two-second action');
            carryReleaseInput.transientLoss = nil; return nil;
        }
        if (code == 790)
        { local value = sharedRelease.assess(); event('test.shared-release-preview'); eventValue(value.status); eventValue(value.reason); return nil; }
        if (code == 791 || code == 792)
        { sharedRelease.release(); if (code == 792) throw new RpgError(); return nil; }
        if (code == 793) { sharedRelease.impactResolved = nil; return nil; }
        if (code == 794) { sharedRelease.wholeLoadDrops = nil; return nil; }
        if (code == 795) { carryPartner.unconscious = nil; return nil; }
        if (code == 796) { sharedRelease.member = bleedProfile; return nil; }
        if (code == 797) { carryPartner.dead = true; sharedRelease.cause = 'dead'; return nil; }
        if (code == 798) { carryPartner.posture = 'lying'; carryPartner.stunned = true; sharedRelease.cause = 'knockdown'; return nil; }
        if (code == 800 || code == 803)
        { carryPartner.becomeUnconscious(); if (code == 803) throw new RpgError(); return nil; }
        if (code == 801)
        {
            event('test.shared-support-clock');
            try { rpgSpendTime(1); eventValue('advanced'); }
            catch (RpgExpandedError error) { eventValue(error.reason); }
            eventValue(rpgLedger.seconds); return nil;
        }
        if (code == 802)
        {
            event('test.shared-support-loss'); eventValue(sharedCarry.supportLosses.length());
            eventValue(sharedCarry.pendingSupportLoss() ? 1 : 0); eventValue(carryPartner.unconscious ? 1 : 0);
            eventValue(rpgLedger.seconds); return nil;
        }
        return inherited(context);
    }
;
