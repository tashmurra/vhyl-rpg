#include "expanded-shared-limb.t"
carryLeftWeapon: RpgLiteWeapon id = 'left-weapon' bodySupports = [carryLeftHand];
carryRightWeapon: RpgLiteWeapon id = 'right-weapon' bodySupports = [carryRightHand];
carryArmShield: RpgLiteItem id = 'arm-shield' db = 2 bodySupports = [carryLeftArm];
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 820)
        {
            event('test.shared-hands'); eventValue(carryLeftWeapon.attackUsableBy(carryPartner) ? 1 : 0);
            eventValue(carryLeftWeapon.parryUsableBy(carryPartner) ? 1 : 0);
            eventValue(carryLeftWeapon.attackHandCount(carryPartner,1));
            eventValue(carryRightWeapon.attackUsableBy(carryPartner) ? 1 : 0);
            eventValue(carryArmShield.blockUsableBy(carryPartner) ? 1 : 0);
            eventValue(carryArmShield.passiveDefenseBonus(carryPartner));
            eventValue(carryPartner.reservedLiftingHandsReason([carryLeftHand]));
            eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 821)
        {
            local attacker = new RpgLiteFighter(); attacker.profile = carryPartner; attacker.weapon = carryLeftWeapon;
            local defender = new RpgLiteFighter(); defender.profile = bleedProfile;
            carryLeftWeapon.ready = true;
            local value = rpgLiteResolveStrike(attacker,defender,new RpgLiteManeuver());
            carryLeftWeapon.ready = nil;
            event('test.shared-hand-attack'); eventValue(value.reason); eventValue(rpgRandom.draws); return nil;
        }
        return inherited(context);
    }
;
