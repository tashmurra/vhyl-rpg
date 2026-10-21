#include "expanded-fear-mental.t"
credulousTrait: RpgExpandedCredulity approved = true;
credulousStory: RpgExpandedCredulityTrigger id = 'story' profile = fearProfile trait = credulousTrait trigger = fearRoom
    story = 'The bridge is safe' plausibility = 'convincing-or-unfamiliar' evidence = 'The teller delivers the story convincingly';
credulousMerchant: RpgLiteSkill id = 'merchant' attribute = rpgIQ;
credulousDetect: RpgLiteSkill id = 'detect-lies' attribute = rpgPerception;
credulousTrade: RpgLiteContext skill = credulousMerchant scoreFor(profile) { return 12; };
credulousOther: RpgLiteContext attribute = rpgIQ;
modify rpgRandom roll() { self.draws += 3; return 7; };
modify FearTestAction
    exec(context)
    {
        local code = fearInput.code;
        if (code == 1170) { fearProfile.traits = [credulousTrait]; return nil; }
        if (code == 1171 || code == 1172) { credulousStory.resolve(); if (code == 1172) throw new RpgError(); return nil; }
        if (code == 1173 || code == 1174) { credulousStory.plausibility = code == 1173 ? 'familiar' : 'outlandish'; return nil; }
        if (code == 1175)
        { event('test.credulity'); eventValue(fearProfile.selfControlTriggers.length()); eventValue(credulousStory.acceptedStory());
          eventValue(credulousStory.check == nil ? nil : credulousStory.check.score); eventValue(rpgRandom.draws); return nil; }
        if (code == 1176) { credulousStory.story = 'A different story'; credulousStory.assess(); return nil; }
        if (code == 1177)
        { event('test.credulity-effects'); eventValue(rpgLiteScore(fearProfile,credulousTrade)); eventValue(rpgLiteScore(fearProfile,credulousOther));
          eventValue(fearProfile.skillLearningReason(credulousDetect)); eventValue(rpgRandom.draws); return nil; }
        if (code == 1178)
        { credulousTrade.credulityExploited = true; credulousTrade.credulityEvidence = 'The bargain exploits trust';
          credulousOther.credulityExploited = true; credulousOther.credulityEvidence = 'An improvised judgment exploits trust'; return nil; }
        if (code == 1179) { credulousTrait.mitigated = true; return nil; }
        if (code == 1180) { credulousTrait.selfControlRating = 6; return nil; }
        return inherited(context);
    }
;
