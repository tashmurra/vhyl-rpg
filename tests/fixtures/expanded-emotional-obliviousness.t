#include "expanded-bleeding.t"
#include <vhyl-rpg-expanded-traits.t>
obliviousActorTrait: RpgExpandedEmotionalObliviousness approved = true;
obliviousTargetTrait: RpgExpandedEmotionalObliviousness approved = true;
obliviousSkill: RpgLiteSkill id = 'fast-talk' attribute = rpgIQ difficulty = 1 defaultPenalty = -5 influence = true;
obliviousTraining: RpgTraining skill = obliviousSkill points = 2;
modify bleedProfile traits = [] skills = [obliviousTraining];
obliviousTarget: RpgExpandedProfile rules = bleedRules;
obliviousContext: RpgLiteContext skill = obliviousSkill;
obliviousSocial: RpgLiteSocialContext;
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 3100)
        {
            event('test.oblivious-preview'); eventValue(obliviousActorTrait.creationCost());
            eventValue(rpgLiteScore(bleedProfile,obliviousContext));
            eventValue(obliviousContext.influenceResistanceModifier(obliviousTarget)); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 3101) { bleedProfile.traits = [obliviousActorTrait]; return nil; }
        if (code == 3102) { obliviousTarget.traits = [obliviousTargetTrait]; return nil; }
        if (code == 3103 || code == 3104)
        {
            local value = rpgLiteInfluence(bleedProfile,obliviousTarget,obliviousContext,obliviousSocial);
            event('test.oblivious-contest'); eventValue(value.contest.score); eventValue(value.contest.oppositionScore);
            eventValue(value.contest.outcome); eventValue(rpgRandom.draws);
            if (code == 3104) throw new RpgError(); return nil;
        }
        if (code == 3105) { obliviousTargetTrait.mitigated = true; return nil; }
        if (code == 3106)
        {
            obliviousTarget.will = 3; event('test.oblivious-low');
            try { rpgLiteInfluence(bleedProfile,obliviousTarget,obliviousContext,obliviousSocial); eventValue('accepted'); }
            catch (RpgExpandedError error) { eventValue(error.reason); }
            eventValue(rpgRandom.draws); return nil;
        }
        if (code == 3107)
        { event('test.oblivious-state'); eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil; }
        return inherited(context);
    }
;
