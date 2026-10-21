#include "expanded-reaction-mastery.t"
preparationAdmin: RpgLiteSkill id = 'administration' attribute = rpgIQ difficulty = 1 defaultPenalty = -5;
preparationCarousing: RpgLiteSkill id = 'carousing' attribute = rpgHT difficulty = 0 defaultPenalty = -4;
preparationAdminTraining: RpgTraining skill = preparationAdmin points = 2;
preparationCarousingTraining: RpgTraining skill = preparationCarousing points = 1;
modify bleedProfile skills = [preparationAdminTraining,preparationCarousingTraining];
modify masteryAttempt mastery = nil;
reactionPreparation: RpgExpandedReactionPreparation id = 'contextual-task' encounter = masteryEncounter skill = preparationAdmin
    reactionKind = 'bureaucracy' seconds = 60 approved = true evidence = 'The author assigns sixty seconds to the task with the bureaucratic audience';
secondApproach: object;
secondReaction: RpgExpandedReactionAttempt encounter = masteryEncounter approach = secondApproach approvedChange = true;
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 2500 || code == 2501)
        { reactionPreparation.resolve(); if (code == 2501) throw new RpgError(); return nil; }
        if (code == 2502)
        { local value = reactionPreparation.assess(); event('test.reaction-preparation'); eventValue(value.status); eventValue(value.reason); eventValue(value.score); return nil; }
        if (code == 2503)
        {
            event('test.reaction-preparation-state'); eventValue(masteryEncounter.preparationHistory.length());
            eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds);
            eventValue(reactionPreparation.result == nil ? nil : reactionPreparation.result.modifier); return nil;
        }
        if (code == 2504) { reactionPreparation.skill = preparationCarousing; reactionPreparation.reactionKind = 'general'; return nil; }
        if (code == 2505) { reactionPreparation.reactionKind = 'trade'; return nil; }
        if (code == 2507) { secondReaction.resolve(); return nil; }
        if (code == 2508)
        { event('test.reaction-second'); eventValue(masteryEncounter.history[2][3]); return nil; }
        return inherited(context);
    }
;
