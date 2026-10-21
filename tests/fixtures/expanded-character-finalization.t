#include "expanded-buyoff.t"
#include <vhyl-rpg-expanded-characters.t>
modify bleedProfile buyoffBases = [];
characterFinalization: RpgExpandedCharacterFinalization id = 'starting-character' profile = bleedProfile
    approved = true evidence = 'The author approves the validated starting character';
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 5400 || code == 5401 || code == 5402)
        {
            local value = code == 5400 ? characterFinalization.assess() : characterFinalization.apply();
            event('test.character-finalization'); eventValue(value.status); eventValue(value.reason); eventValue(value.points);
            if (code == 5402) throw new RpgError(); return nil;
        }
        if (code == 5403)
        {
            event('test.character-history'); eventValue(bleedProfile.creationComplete ? 1 : 0);
            eventValue(bleedProfile.buyoffBases.length());
            eventValue(bleedProfile.buyoffBases.length() == 0 ? nil : bleedProfile.buyoffBases[1].originalBonus); return nil;
        }
        if (code == 5404)
        { bleedProfile.buyoffBases[1].approved = true; bleedProfile.buyoffBases[1].evidence = 'Approved later development removes the disadvantage'; return nil; }
        if (code == 5405) { bleedProfile.buyoffBases[1].originalBonus = 15; return nil; }
        if (code == 5406)
        {
            event('test.character-history-error');
            try { rpgLiteBuyOff(bleedProfile,aidTrait); eventValue('accepted'); }
            catch (RpgExpandedError error) { eventValue(error.reason); }
            eventValue(bleedProfile.unspentPoints); return nil;
        }
        return inherited(context);
    }
;
