#include "expanded-talent-study.t"
#include <vhyl-rpg-expanded-social.t>
talentObserver: RpgLiteProfile;
talentOtherObserver: RpgLiteProfile;
talentReactionContext: RpgExpandedTalentReactionContext
    subject = bleedProfile observer = talentObserver talent = studyTalent demonstratedSkill = studyTalentSkill
    observedPerformance = true eligibleAudience = true impressed = true approved = true
    evidence = 'The customer observed and appreciates the demonstrated workmanship'
;
talentEncounter: RpgExpandedReactionEncounter id = 'talent-encounter' subject = bleedProfile audience = talentObserver;
talentAttempt: RpgExpandedReactionAttempt encounter = talentEncounter approach = 'demonstration' socialContext = talentReactionContext;
modify bleedProfile reactionEncounters = [talentEncounter];
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 7000)
        {
            event('test.talent-reaction-preview'); eventValue(talentReactionContext.traitReactionModifier(bleedProfile));
            eventValue(talentAttempt.assess().status); eventValue(rpgRandom.draws); eventValue(talentEncounter.history.length()); return nil;
        }
        if (code == 7001 || code == 7002)
        {
            local value = talentAttempt.resolve(); event('test.talent-reaction'); eventValue(value.status);
            eventValue(value.total); eventValue(rpgRandom.draws); eventValue(talentEncounter.history.length());
            if (code == 7002) throw new RpgError(); return nil;
        }
        if (code == 7003) { studyTalent.mitigated = true; return nil; }
        if (code == 7004) { talentReactionContext.observedPerformance = nil; return nil; }
        if (code == 7005) { talentReactionContext.eligibleAudience = nil; return nil; }
        if (code == 7006) { talentReactionContext.impressed = nil; return nil; }
        if (code == 7007) { talentReactionContext.approved = nil; return nil; }
        if (code == 7008) { studyTalentSkill.id = 'unrelated'; return nil; }
        if (code == 7009) { talentReactionContext.observer = talentOtherObserver; return nil; }
        if (code == 7010)
        {
            event('test.talent-reaction-error');
            try { talentAttempt.resolve(); eventValue('accepted'); }
            catch (RpgExpandedError error) { eventValue(error.reason); }
            eventValue(rpgRandom.draws); eventValue(talentEncounter.history.length()); return nil;
        }
        if (code == 7011) { studyTalent.id = 'smooth-operator'; studyTalent.points = 15; studyTalentSkill.id = 'fast-talk'; return nil; }
        if (code == 7012) { talentReactionContext.manipulatingObserver = true; return nil; }
        return inherited(context);
    }
;
