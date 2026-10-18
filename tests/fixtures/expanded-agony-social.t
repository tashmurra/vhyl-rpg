#include "expanded-agony.t"
agonyThreatSkill: RpgLiteSkill id = 'intimidation' attribute = rpgWill difficulty = 1 influence = true;
agonyThreatTraining: RpgTraining skill = agonyThreatSkill points = 2;
agonyQuestionSkill: RpgLiteSkill id = 'interrogation' attribute = rpgIQ difficulty = 1;
agonyQuestionTraining: RpgTraining skill = agonyQuestionSkill points = 2;
modify bleedHealer skills = [agonyThreatTraining,agonyQuestionTraining];
agonyThreat: RpgExpandedAgonyThreatContext episode = agonyEpisode target = bleedProfile
    skill = agonyThreatSkill modifier = 2 credible = true threatEvidence = 'The speaker can credibly repeat the resolved effect';
agonyThreatSocial: RpgLiteSocialContext;
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 510)
        {
            event('test.agony-social'); eventValue(rpgLiteScore(bleedHealer,agonyThreat));
            eventValue(agonyThreat.modifier); eventValue(bleedProfile.fatigue);
            eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 511) { agonyThreat.skill = agonyQuestionSkill; return nil; }
        if (code == 512 || code == 513)
        {
            rpgLiteInfluence(bleedHealer,code == 512 ? bleedProfile : bleedHealer,agonyThreat,agonyThreatSocial);
            return nil;
        }
        if (code == 514) { agonyThreat.threatEvidence = nil; return nil; }
        if (code == 515) { agonyThreat.credible = nil; return nil; }
        if (code == 516) { agonyThreat.target = bleedHealer; return nil; }
        return inherited(context);
    }
;
