#include "expanded-health-transactions.t"
#include <vhyl-rpg-expanded-skills.t>
crossAidSkill: RpgExpandedSkill id = 'first-aid' attribute = rpgIQ difficulty = 0 techLevel = 8;
crossAidTraining: RpgTraining skill = crossAidSkill points = 1;
crossPhysiologySkill: RpgExpandedPhysiologySkill techLevel = 8 specialty = 'river-folk';
crossPhysiologyTraining: RpgTraining skill = crossPhysiologySkill points = 4;
crossHealer: RpgExpandedProfile rules = healthRules iq = 12 techLevel = 8 skills = [crossAidTraining,crossPhysiologyTraining];
crossKnowledge: RpgExpandedPhysiologyCheck id = 'aid-knowledge' profile = crossHealer subject = aidPatient operation = aidRequest
    species = 'river-folk' skill = crossPhysiologySkill approved = true evidence = 'Relevant patient specialty';
modify aidBandage healer = crossHealer;
modify aidRequest healer = crossHealer skill = crossAidSkill physiology = 'similar' speciesModifier = -3 subjectSpecies = 'river-folk';
modify rpgRandom
    crossRoll = 3
    roll() { self.draws += 3; return self.crossRoll; }
;
modify AidFixtureAction
    exec(context)
    {
        local code = healthInput.code;
        if (code == 19400) { aidWound.apply(); aidBandage.apply(); return nil; }
        if (code == 19401 || code == 19402)
        { aidRequest.physiologyCheck = crossKnowledge; rpgRandom.crossRoll = code == 19401 ? 3 : 18; crossKnowledge.apply(); return nil; }
        if (code == 19403)
        {
            local value = aidRequest.assess(); event('test.aid-physiology'); eventValue(value.status); eventValue(value.reason);
            eventValue(value.context == nil ? nil : rpgLiteScore(crossHealer,value.context)); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 19404) { aidRequest.physiology = 'machine'; return nil; }
        if (code == 19407) { aidRequest.physiologyCheck = crossKnowledge; return nil; }
        if (code == 19405 || code == 19406)
        {
            rpgRandom.crossRoll = 3; aidRequest.apply();
            if (code == 19406) throw new RpgError();
            return nil;
        }
        return inherited(context);
    }
;
