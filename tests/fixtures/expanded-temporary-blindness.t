#include "expanded-coughing.t"
blindEpisode: RpgExpandedTemporaryBlindness id = 'temporary-sight-loss' profile = bleedProfile durationSeconds = 60
    approved = true evidence = 'An original resolved effect removes sight for sixty seconds';
blindMode: RpgLiteAttackMode skillId = 'first-aid' base = 'fixed' dice = 1 damageType = 'imp';
blindWeapon: RpgLiteWeapon id = 'test-point' modes = [blindMode] ready = true;
blindAttacker: RpgLiteFighter profile = bleedHealer weapon = blindWeapon;
blindDefender: RpgLiteFighter profile = bleedProfile;
blindRequest: RpgLiteManeuver kind = 'attack' target = blindDefender;
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 430) { blindEpisode.assess(); return nil; }
        if (code == 431 || code == 432)
        { blindEpisode.apply(); if (code == 432) throw new RpgError(); return nil; }
        if (code == 433)
        {
            local check = new RpgLiteContext(); check.attribute = rpgPerception; check.kind = 'vision';
            event('test.temporary-blindness'); eventValue(bleedProfile.temporarilyBlind() ? 1 : 0);
            eventValue(rpgLiteScore(bleedProfile,check)); check.kind = 'hearing';
            eventValue(rpgLiteScore(bleedProfile,check)); check.kind = 'task'; check.attribute = rpgIQ;
            check.requiresVision = true; eventValue(rpgLiteScore(bleedProfile,check));
            check.requiresVision = nil; eventValue(rpgLiteScore(bleedProfile,check));
            eventValue(bleedProfile.coughing() ? 1 : 0); eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 435) { rpgLiteStrike(blindAttacker,blindDefender,blindRequest); return nil; }
        if (code == 436)
        {
            local attacker = new RpgLiteFighter(); attacker.profile = bleedProfile; attacker.weapon = blindWeapon;
            rpgLiteStrike(attacker,blindAttacker,blindRequest); return nil;
        }
        return inherited(context);
    }
;
