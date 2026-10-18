#include "expanded-radiation.t"
#include <vhyl-rpg-expanded-characters.t>
modify radiationProfile creationComplete = true;
terminalCondition: RpgExpandedTerminalCondition profile = radiationProfile yearSeconds = 31536000
    approved = true meaningfulDuration = true calendarEvidence = 'The campaign year is 365 days';
modify RadiationTestAction
    exec(context)
    {
        local code = radiationInput.code;
        if (code == 20) { terminalCondition.acquire(); return nil; }
        if (code == 21) { terminalCondition.assess(); return nil; }
        if (code == 22) { terminalCondition.acquire(); throw new RpgError(); }
        if (code == 23) { terminalCondition.resolveDeath(); return nil; }
        if (code == 24) { terminalCondition.resolveDeath(); throw new RpgError(); }
        if (code == 25) { terminalCondition.approved = nil; return nil; }
        if (code == 30) { rpgSpendTime(radiationInput.days); return nil; }
        if (code == 31)
        {
            event('test.terminal'); eventValue(rpgExpandedCharacterCost(radiationProfile,nil));
            eventValue(radiationProfile.unspentPoints); eventValue(radiationProfile.developmentRevision);
            eventValue(radiationProfile.postCreationDisadvantageAllowance());
            eventValue(terminalCondition.deathDue); eventValue(radiationProfile.dead ? 1 : 0);
            eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        return inherited(context);
    }
;
