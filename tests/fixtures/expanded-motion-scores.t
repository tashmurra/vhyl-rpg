#include "expanded-motion-journey.t"
motionHealthSkill: RpgExpandedSkill id = 'singing' attribute = rpgHT difficulty = 0 vehicleOperationClass = 0;
motionHealthTraining: RpgExpandedTraining skill = motionHealthSkill points = 1;
modify motionHero skills = [motionHealthTraining];
modify ExpandedTestAction
    exec(context)
    {
        local code = expandedInput.code;
        if (code == 16300)
        {
            local c = new RpgLiteContext(); event('test.motion-scores');
            c.attribute = rpgDX; eventValue(rpgLiteScore(motionHero,c));
            c.attribute = rpgIQ; eventValue(rpgLiteScore(motionHero,c));
            c.attribute = rpgHT; eventValue(rpgLiteScore(motionHero,c));
            c.attribute = rpgPerception; eventValue(rpgLiteScore(motionHero,c));
            c.skill = motionHealthSkill; eventValue(rpgLiteScore(motionHero,c));
            eventValue(rpgRandom.draws); return nil;
        }
        if (code == 16301)
        {
            motionTrip.currentPenalty = 0;
            try { motionHero.activeMotionJourney(); }
            catch (RpgExpandedError error) { event('test.motion-score-binding'); eventValue(error.reason); }
            return nil;
        }
        return inherited(context);
    }
;
