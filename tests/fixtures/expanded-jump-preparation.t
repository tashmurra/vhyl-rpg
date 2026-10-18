#include "expanded-bleeding.t"
#include <vhyl-rpg-expanded-exploration.t>
prepFighter: RpgLiteFighter profile = bleedProfile;
prepOtherProfile: RpgLiteProfile;
prepOther: RpgLiteFighter profile = prepOtherProfile;
prepBattle: RpgLiteBattle fighters = [prepFighter,prepOther];
prepReceipt: RpgExpandedJumpPreparation fighter = prepFighter battle = prepBattle;
prepDistance: RpgExpandedJumpDistance profile = bleedProfile preparation = prepReceipt;
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 1340)
        { prepBattle.order = [prepFighter,prepOther]; prepBattle.index = 1; prepBattle.active = true; return nil; }
        if (code == 1341 || code == 1342)
        {
            local gate = new RpgExpandedActionGate(); gate.profile = bleedProfile;
            gate.id = ['prep-one','prep-two','prep-three','prep-four'][prepBattle.seconds + 1];
            gate.evidence = 'One concentration turn for a jump';
            local request = new RpgExpandedJumpPrepareManeuver(); request.healthGate = gate; request.preparation = prepReceipt;
            prepBattle.step(prepFighter,request);
            if (code == 1342) throw new RpgError(); return nil;
        }
        if (code == 1343) { prepBattle.step(prepOther,new RpgLiteManeuver()); return nil; }
        if (code == 1344)
        {
            local value = prepDistance.combatAssessment(); event('test.jump-preparation');
            eventValue(prepReceipt.turns); eventValue(prepFighter.concentration);
            eventValue(prepReceipt.readyFor(bleedProfile) ? 1 : 0); eventValue(value.highInchTenths);
            eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 1345) { prepFighter.concentration = 0; return nil; }
        if (code == 1346)
        { local request = new RpgLiteManeuver(); request.kind = 'concentrate'; prepBattle.step(prepFighter,request); return nil; }
        return inherited(context);
    }
;
