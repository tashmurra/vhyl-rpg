#include "expanded-fear-mental.t"
confidencePurchase: RpgExpandedLowConfidence approved = true;
confidenceTaskSkill: RpgLiteSkill id = 'repair-test' attribute = rpgIQ difficulty = 1;
confidenceTask: RpgLiteContext skill = confidenceTaskSkill scoreFor(profile) { return 12; };
confidenceAttribute: RpgLiteContext attribute = rpgIQ;
modify FearTestAction
    exec(context)
    {
        local code = fearInput.code;
        if (code == 1100)
        { mentalAward.trait = confidencePurchase; mentalAward.tableTotal = 23; fearProfile.creationComplete = true;
          fearProfile.earnedPoints = 9; fearProfile.unspentPoints = 7; return nil; }
        if (code == 1101 || code == 1102)
        { confidenceTask.confidenceSituation = code == 1101 ? 'ordinary' : 'adverse';
          confidenceTask.confidenceEvidence = code == 1101 ? 'The actor expects to succeed in familiar surroundings' : 'The actor expects failure under pursuit'; return nil; }
        if (code == 1103 || code == 1104)
        { local result = rpgLiteCheck(fearProfile,confidenceTask); event('test.confidence-check');
          eventValue(result.score); eventValue(result.reason); eventValue(rpgRandom.draws);
          if (code == 1104) throw new RpgError(); return nil; }
        if (code == 1105)
        { event('test.low-confidence'); eventValue(fearProfile.traits.length());
          eventValue(fearProfile.postCreationDisadvantageAllowance()); eventValue(fearProfile.earnedPoints);
          eventValue(fearProfile.unspentPoints); eventValue(rpgLiteScore(fearProfile,confidenceTask));
          eventValue(rpgLiteScore(fearProfile,confidenceAttribute)); eventValue(rpgRandom.draws); return nil; }
        if (code == 1106) { confidencePurchase.mitigated = true; return nil; }
        if (code == 1107) { confidenceTask.modifier = -2; return nil; }
        if (code == 1108)
        { local copy = rpgExpandedTemplateTraits.copy(confidencePurchase); event('test.confidence-copy');
          eventValue(copy.creationCost()); eventValue(copy != confidencePurchase ? 1 : 0); return nil; }
        return inherited(context);
    }
;
