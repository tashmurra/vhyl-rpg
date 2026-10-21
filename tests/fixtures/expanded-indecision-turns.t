#include "expanded-indecision.t"
indecisionFighter: RpgLiteFighter profile = fearProfile;
indecisionBattle: RpgLiteBattle fighters = [indecisionFighter];
indecisionMove: RpgLiteManeuver kind = 'move' movement = 1;
indecisionNothing: RpgLiteManeuver kind = 'nothing';
modify FearTestAction
    exec(context)
    {
        local code = fearInput.code;
        if (code == 1160)
        { fearProfile.traits = [indecisionTrait]; indecisionEpisode.highStress = true;
          indecisionBattle.active = true; indecisionBattle.order = [indecisionFighter]; return nil; }
        if (code == 1161 || code == 1162 || code == 1164 || code == 1165)
        {
            local request = code == 1161 || code == 1164 ? indecisionMove : indecisionNothing;
            local result = indecisionBattle.step(indecisionFighter,request);
            event('test.indecision-turn-result'); eventValue(result.status); eventValue(result.reason);
            if (code == 1164 || code == 1165) throw new RpgError(); return nil;
        }
        if (code == 1163)
        {
            event('test.indecision-turns'); eventValue(indecisionFighter.turnSerial); eventValue(indecisionFighter.maneuver);
            eventValue(indecisionBattle.seconds); eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws);
            eventValue(indecisionEpisode.attempts.length()); eventValue(fearProfile.activeIndecision() != nil ? 1 : 0); return nil;
        }
        return inherited(context);
    }
;
