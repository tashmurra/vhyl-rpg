#include "expanded-attribute-reduction.t"
modify attributeEpisode attribute = rpgST;
modify attributeContext attribute = rpgST;
strengthMode: RpgLiteAttackMode skillId = 'observation' base = 'thrust' damageType = 'cr';
strengthWeapon: RpgLiteWeapon id = 'punch' modes = [strengthMode] ready = true weaponST = 10 ammunition = 1;
strengthTargetProfile: RpgExpandedProfile rules = bleedRules st = 100;
strengthAttacker: RpgLiteFighter profile = bleedProfile weapon = strengthWeapon;
strengthTarget: RpgLiteFighter profile = strengthTargetProfile;
strengthRequest: RpgLiteManeuver kind = 'attack' target = strengthTarget;
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 7900)
        {
            event('test.strength-reduction'); eventValue(bleedProfile.muscleDamageStrength());
            eventValue(rpgLiteThrowDamage(bleedProfile,1000,true)); eventValue(bleedProfile.basicLiftHundredths());
            eventValue(bleedProfile.maxHP); eventValue(bleedProfile.maxEnergy); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 7901)
        {
            local value = rpgLiteStrike(strengthAttacker,strengthTarget,strengthRequest);
            event('test.strength-strike'); eventValue(value.damage); return nil;
        }
        if (code == 7902) { strengthWeapon.id = 'crossbow'; strengthMode.ranged = true; return nil; }
        if (code == 7903) { attributeEpisode.penalty = 10; return nil; }
        if (code == 7904)
        {
            event('test.strength-error');
            try { rpgLiteStrike(strengthAttacker,strengthTarget,strengthRequest); eventValue('accepted'); }
            catch (RpgExpandedError error) { eventValue(error.reason); }
            eventValue(rpgRandom.draws); return nil;
        }
        return inherited(context);
    }
;
