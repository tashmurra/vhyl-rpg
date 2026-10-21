#include "expanded-credulity.t"
#include <vhyl-rpg-expanded-skills.t>
#include <vhyl-rpg-expanded-development.t>
credulousLearningSkill: RpgExpandedSkill id = 'detect-lies' attribute = rpgPerception difficulty = 2 defaultPenalty = -6;
credulousTraining: RpgTraining skill = credulousLearningSkill points = 0;
modify fearProfile skills = [credulousTraining];
credulousOffer: RpgDevelopment id = 'learn-detection' profile = fearProfile kind = 'skill'
    training = credulousTraining target = 1 unlocked = true available(profile) { return nil; };
credulousStudy: RpgExpandedStudy profile = fearProfile training = credulousTraining permitted = true;
modify FearTestAction
    exec(context)
    {
        local code = fearInput.code;
        if (code == 1190)
        { mentalAward.trait = credulousTrait; mentalAward.tableTotal = 23; fearProfile.creationComplete = true;
          fearProfile.earnedPoints = 9; fearProfile.unspentPoints = 7; fearProfile.developmentOpen = true;
          fearProfile.skills = [credulousTraining]; return nil; }
        if (code == 1191) { credulousTraining.points = 1; return nil; }
        if (code == 1192)
        { local v = mentalAward.assess(); event('test.credulity-acquisition'); eventValue(v.status); eventValue(v.reason); return nil; }
        if (code == 1193 || code == 1194)
        { local v = rpgDevelop(credulousOffer); event('test.credulity-development'); eventValue(v.status); eventValue(v.reason);
          if (code == 1194) throw new RpgError(); return nil; }
        if (code == 1195)
        { event('test.credulity-learning'); eventValue(rpgLiteLearn(fearProfile,credulousLearningSkill,1,nil) ? 1 : 0);
          eventValue(credulousStudy.advance(3600).reason); return nil; }
        if (code == 1196)
        { event('test.credulity-learning-state'); eventValue(fearProfile.traits.length());
          eventValue(fearProfile.postCreationDisadvantageAllowance()); eventValue(credulousTraining.points);
          eventValue(fearProfile.earnedPoints); eventValue(fearProfile.unspentPoints); eventValue(credulousStudy.credit);
          eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil; }
        return inherited(context);
    }
;
