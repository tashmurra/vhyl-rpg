#include "expanded-shadowing-context.t"
shadowOutcomeInput: object followerRoll = 10 targetRoll = 10 aware = nil;
modify PhysicianFixtureAction
    exec(context)
    {
        local code = healthInput.code;
        if (code == 29200)
        {
            local value = rpgExpandedAssessShadowing(12,shadowOutcomeInput.followerRoll,12,shadowOutcomeInput.targetRoll,shadowOutcomeInput.aware);
            event('test.shadowing-outcome'); eventValue(value.interval); eventValue(value.victoryMargin);
            eventValue(value.lost ? 1 : 0); eventValue(value.seen ? 1 : 0); eventValue(value.wrongTarget ? 1 : 0);
            eventValue(value.targetBelievesEscape ? 1 : 0); eventValue(value.targetAware ? 1 : 0);
            eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 29201) { shadowOutcomeInput.aware = true; return nil; }
        if (code == 29202) { shadowOutcomeInput.followerRoll = 15; return nil; }
        if (code == 29203) { shadowOutcomeInput.followerRoll = 16; return nil; }
        if (code == 29204) { shadowOutcomeInput.targetRoll = 15; return nil; }
        if (code == 29205) { shadowOutcomeInput.followerRoll = 9; return nil; }
        if (code == 29206) { shadowOutcomeInput.followerRoll = 18; shadowOutcomeInput.targetRoll = 18; return nil; }
        if (code == 29207) { shadowOutcomeInput.followerRoll = 14; shadowOutcomeInput.targetRoll = 15; return nil; }
        if (code == 29208) { shadowOutcomeInput.followerRoll = 15; shadowOutcomeInput.targetRoll = 14; return nil; }
        return inherited(context);
    }
;
