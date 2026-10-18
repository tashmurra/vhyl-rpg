#include "expanded-begging-hour.t"
#include <vhyl-rpg-expanded-traits.t>
beggingSympathy: RpgExpandedSympathy approved = true;
beggingInhibition: RpgExpandedSocialInhibition approved = true level = 1;
beggingObserver: RpgExpandedProfile rules = healthRules;
beggingCallousness: RpgExpandedCallousness approved = true;
beggingReaction: RpgExpandedSympathyReactionContext subject = crossPhysician observer = beggingObserver
    perceivedNeed = true approved = true evidence = 'The observer recognizes the subject needs help';
modify crossPhysician traits = [beggingSympathy,beggingInhibition];
modify PhysicianFixtureAction
    exec(context)
    {
        local code = healthInput.code;
        if (code == 24600)
        { event('test.begging-traits'); eventValue(beggingSympathy.creationCost());
          eventValue(rpgLiteScore(crossPhysician,beggingContext)); eventValue(beggingReaction.traitReactionModifier(crossPhysician));
          eventValue(crossPhysician.skillLearningReason(beggingSkill)); eventValue(rpgRandom.draws); return nil; }
        if (code == 24601) { beggingInhibition.level = 2; return nil; }
        if (code == 24602) { beggingInhibition.level = 3; return nil; }
        if (code == 24603) { beggingSympathy.mitigated = true; return nil; }
        if (code == 24604) { beggingObserver.traits = [beggingCallousness]; return nil; }
        if (code == 24605) { beggingReaction.perceivedNeed = nil; return nil; }
        if (code == 24606 || code == 24607)
        {
            if (code == 24606) beggingContext.pitiable = true; else beggingContext.shynessPenalty = -1;
            event('test.begging-trait-conflict'); eventValue(beggingContext.unavailableReason(crossPhysician)); return nil;
        }
        return inherited(context);
    }
;
