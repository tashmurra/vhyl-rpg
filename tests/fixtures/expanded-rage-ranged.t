#include "expanded-panic-attack.t"
#include <vhyl-rpg-expanded-combat.t>
modify attackMode rof = 3 capacity = 6 reloadSeconds = 2;
modify attackWeapon reserves = 6;
rageRanged: RpgExpandedRageRangedChoice fighter = attackFighter target = attackOther distanceYards = 21
    action = 'attack' firearm = true shots = 2 approved = true
    evidence = 'The visible foe is twenty-one yards away; this ready firearm has two rounds left';
modify FearTestAction
    exec(context)
    {
        local code = fearInput.code;
        if (code == 920)
        { local v = rageRanged.assess(); event('test.rage-ranged'); eventValue(v.status); eventValue(v.reason);
          eventValue(v.shots); eventValue(attackWeapon.ammunition); eventValue(attackWeapon.reserves);
          eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil; }
        if (code == 921) { rageRanged.distanceYards = 20; return nil; }
        if (code == 922) { rageRanged.action = 'aim'; return nil; }
        if (code == 923) { rageRanged.shots = 1; return nil; }
        if (code == 924) { attackWeapon.ammunition = 0; return nil; }
        if (code == 925) { attackWeapon.ammunition = 6; rageRanged.shots = 3; return nil; }
        if (code == 926)
        { rageRanged.action = 'reload'; rageRanged.target = nil; rageRanged.shots = 0; return nil; }
        if (code == 927) { rageRanged.quickDrawConfirmed = true; rageRanged.reloadSeconds = 1; return nil; }
        if (code == 928) { rageRanged.reloadSeconds = 2; return nil; }
        return inherited(context);
    }
;
