#include "expanded-radiation-burn.t"
#include <vhyl-rpg-expanded-characters.t>
modify radiationProfile creationComplete = true;
recoveryTerminal: RpgExpandedTerminalCondition profile = radiationProfile yearSeconds = 31536000
    approved = true meaningfulDuration = true calendarEvidence = 'The campaign year is 365 days';
burnRecovery: RpgExpandedRadiationBurnRecovery episode = radiationBurn terminalCondition = recoveryTerminal
    approved = true recoveryEvidence = 'Full physical recovery has been confirmed';
recoveryDice: object enabled = nil index = 0 pair = [10,10];
modify rpgRandom
    roll()
    {
        if (!recoveryDice.enabled) return inherited();
        recoveryDice.index += 1; self.draws += 3; return recoveryDice.pair[recoveryDice.index];
    }
;
modify RadiationTestAction
    exec(context)
    {
        local code = radiationInput.code;
        if (code == 70)
        {
            local pairs = [[10,10],[18,10],[10,18],[18,18],[11,11]];
            recoveryDice.enabled = true; recoveryDice.pair = pairs[radiationInput.days]; recoveryDice.index = 0; return nil;
        }
        if (code == 80) { rpgLiteHeal(radiationProfile,radiationProfile.injury); return nil; }
        if (code == 85) { recoveryTerminal.approved = nil; return nil; }
        if (code >= 81 && code <= 83)
        {
            local value = code == 81 ? burnRecovery.assess() : burnRecovery.apply();
            event('test.radiation-recovery-result'); eventValue(value.status); eventValue(value.reason);
            if (code == 83) throw new RpgError(); return nil;
        }
        if (code == 84)
        {
            event('test.radiation-recovery'); eventValue(radiationProfile.fertilityBlocked() ? 1 : 0);
            eventValue(rpgExpandedCharacterCost(radiationProfile,nil)); eventValue(radiationProfile.developmentRevision);
            eventValue(rpgRandom.draws); eventValue(firstRadiationCheck.result.consequencesPending ? 1 : 0);
            eventValue(recoveryTerminal.deathDue); eventValue(radiationProfile.injury);
            eventValue(radiationProfile.unspentPoints); return nil;
        }
        return inherited(context);
    }
;
