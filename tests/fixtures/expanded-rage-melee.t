#include "expanded-rage-ranged.t"
modify attackMode ranged = nil;
rageMelee: RpgExpandedRageMeleeChoice fighter = attackFighter target = attackOther
    action = 'all-out-attack' inReach = true reachAssessed = true distanceYards = 1
    approved = true evidence = 'The identified foe is in hand-weapon reach; the selected route is legal and unobstructed';
modify FearTestAction
    exec(context)
    {
        local code = fearInput.code;
        if (code == 930)
        { local v = rageMelee.assess(); event('test.rage-melee'); eventValue(v.status); eventValue(v.reason);
          eventValue(attackTarget.injury); eventValue(attackWeapon.ammunition);
          eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil; }
        if (code == 931) { rageMelee.action = 'attack'; return nil; }
        if (code == 932)
        { rageMelee.inReach = nil; rageMelee.distanceYards = 8; rageMelee.closestDistance = 3;
          rageMelee.endingDistance = 3; rageMelee.movement = 5; rageMelee.movementAssessed = true;
          rageMelee.action = 'move'; return nil; }
        if (code == 933) { rageMelee.moveAttackPossible = true; return nil; }
        if (code == 934) { rageMelee.action = 'move-attack'; return nil; }
        if (code == 935) { rageMelee.slamPossible = true; rageMelee.action = 'slam'; return nil; }
        if (code == 936) { rageMelee.endingDistance = 4; return nil; }
        if (code == 937) { rageMelee.movementAssessed = nil; return nil; }
        if (code == 938) { rageMelee.movement = 6; return nil; }
        if (code == 939) { attackWeapon.ready = nil; return nil; }
        return inherited(context);
    }
;
