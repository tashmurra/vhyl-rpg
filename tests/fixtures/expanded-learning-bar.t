#include "expanded-bleeding.t"
#include <vhyl-rpg-expanded-skills.t>
#include <vhyl-rpg-expanded-traits.t>
#include <vhyl-rpg-expanded-development.t>
learningBar: RpgExpandedLearningBar approved = true;
learningSkill: RpgExpandedSkill id = 'test-learning' attribute = rpgIQ difficulty = 1 defaultPenalty = -5;
learningTraining: RpgTraining skill = learningSkill points = 1;
learningNewTrait: RpgLiteTrait id = 'authored-benefit' points = 5;
modify bleedProfile
    traits = [learningBar] skills = [learningTraining] familiarities = [learningFamiliarity]
    earnedPoints = 100 unspentPoints = 100 developmentOpen = true
;
learningOffer: RpgDevelopment
    id = 'learning-offer' profile = bleedProfile kind = 'attribute' attribute = rpgDX
    target = 11 unlocked = true training = learningTraining trait = learningNewTrait cost = 5
    available(profile) { return nil; }
;
learningStudy: RpgExpandedStudy profile = bleedProfile training = learningTraining permitted = true;
learningEquipment: object;
learningFamiliarity: RpgExpandedFamiliarity
    owner = bleedProfile skill = learningSkill equipmentType = learningEquipment available = true
;
learningRecognition: RpgExpandedFamiliarityRecognition familiarity = learningFamiliarity approved = true;
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 3300 || code == 3301 || code == 3313)
        {
            local value = code == 3300 ? rpgAssessDevelopment(learningOffer) : rpgDevelop(learningOffer);
            event('test.learning-offer'); eventValue(value.status); eventValue(value.reason);
            eventValue(bleedProfile.unspentPoints); eventValue(bleedProfile.developmentRevision);
            if (code == 3313) throw new RpgError(); return nil;
        }
        if (code == 3302) { learningOffer.attribute = rpgST; return nil; }
        if (code == 3303) { learningOffer.attribute = rpgIQ; return nil; }
        if (code == 3304) { learningOffer.kind = 'skill'; learningOffer.target = 2; return nil; }
        if (code == 3305) { learningOffer.kind = 'trait'; return nil; }
        if (code == 3306) { learningOffer.expandedTraitNature = 'mental'; learningOffer.expandedTraitEvidence = 'Approved classification'; return nil; }
        if (code == 3307) { learningOffer.expandedTraitNature = 'physical'; learningOffer.expandedTraitEvidence = 'Approved classification'; return nil; }
        if (code == 3308) { learningBar.mitigated = true; return nil; }
        if (code == 3309)
        {
            event('test.learning-paths'); eventValue(learningBar.creationCost());
            eventValue(bleedProfile.skillLearningReason(learningSkill));
            eventValue(bleedProfile.skillScore(learningSkill));
            eventValue(rpgLiteLearn(bleedProfile,learningSkill,2,nil) ? 1 : 0);
            eventValue(learningStudy.advance(3600).reason);
            eventValue(learningFamiliarity.advance(3600).reason);
            eventValue(learningRecognition.resolve().reason);
            eventValue(bleedProfile.learningAcquisitionReason('technique')); return nil;
        }
        if (code == 3310)
        {
            event('test.learning-state'); eventValue(bleedProfile.unspentPoints); eventValue(learningTraining.points);
            eventValue(learningStudy.credit); eventValue(learningFamiliarity.practicedSeconds);
            eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); eventValue(bleedProfile.st);
            eventValue(bleedProfile.developmentRevision); return nil;
        }
        return inherited(context);
    }
;
