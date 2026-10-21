#include "expanded-bleeding.t"
#include <vhyl-rpg-expanded-social.t>
masteryDiplomacy: RpgLiteSkill id = 'diplomacy' attribute = rpgIQ difficulty = 2 defaultPenalty = -6;
masteryFastTalk: RpgLiteSkill id = 'fast-talk' attribute = rpgIQ difficulty = 1 defaultPenalty = -5;
masteryDiplomacyTraining: RpgTraining skill = masteryDiplomacy points = 44;
masteryFastTalkTraining: RpgTraining skill = masteryFastTalk points = 40;
masteryAudience: object;
masteryEncounter: RpgExpandedReactionEncounter id = 'audience' subject = bleedProfile audience = masteryAudience;
modify bleedProfile skills = [masteryDiplomacyTraining,masteryFastTalkTraining] reactionEncounters = [masteryEncounter];
masteryBonus: RpgExpandedReactionMastery encounter = masteryEncounter skill = masteryDiplomacy canSpeak = true
    approved = true evidence = 'The speaker is allowed to talk to this audience';
masteryApproach: object;
masteryAttempt: RpgExpandedReactionAttempt encounter = masteryEncounter approach = masteryApproach mastery = masteryBonus;
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 2400)
        { local value = masteryBonus.assess(); event('test.reaction-mastery'); eventValue(value.status); eventValue(value.score); eventValue(value.modifier); return nil; }
        if (code == 2401) { masteryDiplomacyTraining.points = 40; return nil; }
        if (code == 2402) { masteryBonus.skill = masteryFastTalk; return nil; }
        if (code == 2403 || code == 2404)
        { masteryAttempt.resolve(); if (code == 2404) throw new RpgError(); return nil; }
        if (code == 2405)
        {
            event('test.reaction-mastery-state'); eventValue(masteryEncounter.history.length()); eventValue(masteryEncounter.masteryHistory.length());
            eventValue(rpgRandom.draws); eventValue(masteryEncounter.history.length() == 0 ? nil : masteryEncounter.history[1][3]); return nil;
        }
        if (code == 2406) { masteryBonus.canSpeak = nil; return nil; }
        if (code == 2407) { masteryEncounter.predeterminedBand = 4; return nil; }
        if (code == 2410) { bleedInput.forcedRoll = 12; return nil; }
        return inherited(context);
    }
;
