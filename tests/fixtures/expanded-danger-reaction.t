#include "expanded-danger-avoidance.t"
#include <vhyl-rpg-expanded-social.t>
avoidanceObserver: RpgLiteProfile;
avoidanceOther: RpgLiteProfile;
avoidanceSocial: RpgExpandedDangerReactionContext subject = bleedProfile observer = avoidanceObserver
    approved = true evidence = 'This observer knows the trait and expects physical courage in this role'
    avoidanceKnown = true occupationalExpectation = true;
avoidanceDiplomacy: RpgLiteSkill id = 'diplomacy' attribute = rpgIQ difficulty = 2 influence = true;
avoidanceDiplomacyTraining: RpgTraining skill = avoidanceDiplomacy points = 4;
modify bleedProfile skills = [avoidanceDiplomacyTraining];
avoidanceTalk: RpgLiteContext skill = avoidanceDiplomacy;
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 720)
        {
            event('test.avoidance-reaction');
            foreach (local rating in [6,9,12,15])
            { avoidanceTrait.selfControlRating = rating; eventValue(rpgLiteReactionModifier(bleedProfile,avoidanceSocial)); }
            avoidanceTrait.selfControlRating = 12; eventValue(rpgRandom.draws); return nil;
        }
        if (code == 721)
        { event('test.avoidance-reaction-single'); eventValue(rpgLiteReactionModifier(bleedProfile,avoidanceSocial)); return nil; }
        if (code == 722) { avoidanceSocial.avoidanceKnown = nil; return nil; }
        if (code == 723) { avoidanceSocial.occupationalExpectation = nil; return nil; }
        if (code == 724) { avoidanceSocial.evidence = nil; return nil; }
        if (code == 725 || code == 726)
        {
            event('test.avoidance-influence');
            try
            {
                local value = rpgLiteInfluence(bleedProfile,code == 725 ? avoidanceObserver : avoidanceOther,
                    avoidanceTalk,avoidanceSocial);
                eventValue(value.reactionRoll);
            }
            catch (RpgExpandedError error) { eventValue(error.reason); }
            eventValue(rpgRandom.draws); return nil;
        }
        if (code == 727) { avoidanceSocial.modifier = 3; return nil; }
        return inherited(context);
    }
;
