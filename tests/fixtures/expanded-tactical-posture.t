#include "expanded-tactical-positions.t"
postureActor: RpgLiteFighter profile = positionHero;
postureOther: RpgLiteFighter profile = positionOther;
postureBattle: RpgLiteBattle fighters = [postureActor,postureOther];
postureDown: RpgExpandedPostureManeuver battle = postureBattle figure = positionFigure
    posture = 'lying' footprint = positionFall;
postureUp: RpgExpandedPostureManeuver battle = postureBattle figure = positionFigure
    posture = 'kneeling' footprint = positionRise;
postureStand: RpgExpandedPostureManeuver battle = postureBattle figure = positionFigure posture = 'standing';
postureIdle: RpgLiteManeuver;
modify positionHero dx = 12;
modify PositionTestAction
    exec(context)
    {
        local code = positionInput.code;
        if (code < 50) return inherited(context);
        if (code == 50)
        {
            positionPlacement.apply(); positionSecond.apply(); postureBattle.begin(); rpgRandom.seed(1); return nil;
        }
        if (code == 56) { positionFall.selected = positionEast; return nil; }
        if (code == 57) { positionHero.fatigue = 10; return nil; }
        if (code == 58)
        {
            event('test.posture-preview'); eventValue(postureDown.available(postureActor)); return nil;
        }
        local value = code == 52 ? postureBattle.step(postureOther,postureIdle)
            : code == 53 ? postureBattle.step(postureActor,postureUp)
            : code == 54 ? postureBattle.step(postureActor,postureStand)
            : postureBattle.step(postureActor,postureDown);
        event('test.posture-battle'); eventValue(value.status); eventValue(value.reason);
        if (code == 55) throw new RpgError(); return nil;
    }
;
