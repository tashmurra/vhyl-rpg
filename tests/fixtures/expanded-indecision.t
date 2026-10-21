#include "expanded-fear-mental.t"
indecisionTrait: RpgExpandedIndecision approved = true;
indecisionLeft: object;
indecisionRight: object;
indecisionRetryToken: object;
indecisionEpisode: RpgExpandedIndecisionEpisode id = 'junction' profile = fearProfile trait = indecisionTrait
    choices = [indecisionLeft,indecisionRight] approved = true evidence = 'Two visible routes confront the actor';
indecisionFirst: RpgExpandedIndecisionCheck id = 'junction-first' profile = fearProfile trait = indecisionTrait
    episode = indecisionEpisode trigger = indecisionEpisode stressRelation = 'unrelated' evidence = 'Initial route choice';
indecisionRetry: RpgExpandedIndecisionCheck id = 'junction-retry' profile = fearProfile trait = indecisionTrait
    episode = indecisionEpisode trigger = indecisionRetryToken stressRelation = 'unrelated' evidence = 'Retry at the required boundary';
indecisionInput: object rolls = 0;
modify rpgRandom
    roll() { self.draws += 3; indecisionInput.rolls += 1; return indecisionInput.rolls == 1 ? 11 : 3; }
;
modify FearTestAction
    exec(context)
    {
        local code = fearInput.code;
        if (code == 1120) { fearProfile.traits = [indecisionTrait]; return nil; }
        if (code == 1121 || code == 1122)
        { indecisionFirst.resolve(); if (code == 1122) throw new RpgError(); return nil; }
        if (code == 1123 || code == 1124)
        { indecisionRetry.resolve(); if (code == 1124) throw new RpgError(); return nil; }
        if (code == 1125)
        {
            event('test.indecision'); eventValue(indecisionEpisode.attempts.length());
            eventValue(fearProfile.activeIndecision() != nil ? 1 : 0); eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds);
            eventValue(fearProfile.healthManeuverReasonFor('move',nil));
            eventValue(indecisionFirst.check == nil ? nil : indecisionFirst.check.score); return nil;
        }
        if (code == 1126) { indecisionEpisode.highStress = true; return nil; }
        if (code == 1127) { rpgSpendTime(indecisionEpisode.highStress ? 1 : 59); return nil; }
        if (code == 1128) { rpgSpendTime(1); return nil; }
        if (code == 1129) { indecisionEpisode.choices = [indecisionLeft]; indecisionFirst.assess(); return nil; }
        if (code == 1130) { indecisionTrait.mitigated = true; return nil; }
        if (code == 1131) { indecisionTrait.mitigated = nil; return nil; }
        if (code == 1150)
        { mentalAward.trait = indecisionTrait; mentalAward.tableTotal = 23; fearProfile.creationComplete = true;
          fearProfile.earnedPoints = 9; fearProfile.unspentPoints = 7; return nil; }
        if (code == 1151)
        { event('test.indecision-acquisition'); eventValue(fearProfile.traits.length());
          eventValue(fearProfile.postCreationDisadvantageAllowance()); eventValue(fearProfile.earnedPoints);
          eventValue(fearProfile.unspentPoints); eventValue(rpgRandom.draws); return nil; }
        return inherited(context);
    }
;
