#include "expanded-packing-skill.t"
beggingSkill: RpgExpandedBeggingSkill;
beggingTraining: RpgTraining skill = beggingSkill points = 1;
beggingSpeech: RpgExpandedSkill id = 'public-speaking' attribute = rpgIQ difficulty = 1 defaultPenalty = -5;
beggingSpeechTraining: RpgTraining skill = beggingSpeech points = 8;
beggingPersuasion: RpgExpandedSkill id = 'quick-persuasion' attribute = rpgIQ difficulty = 1 defaultPenalty = -5;
beggingPersuasionTraining: RpgTraining skill = beggingPersuasion points = 8;
beggingContext: RpgExpandedBeggingContext skill = beggingSkill approved = true evidence = 'Ordinary crowd and authored personal presentation';
modify PhysicianFixtureAction
    exec(context)
    {
        local code = healthInput.code;
        if (code == 24200)
        { event('test.begging-score'); eventValue(crossPhysician.skillScore(beggingSkill)); eventValue(rpgLiteScore(crossPhysician,beggingContext)); eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil; }
        if (code == 24201) { crossPhysician.skills = [beggingTraining]; return nil; }
        if (code == 24202) { crossPhysician.skills = [beggingSpeechTraining]; return nil; }
        if (code == 24203) { crossPhysician.skills = [beggingPersuasionTraining]; return nil; }
        if (code == 24204)
        { beggingContext.pitiable = true; beggingContext.shynessPenalty = -2; beggingContext.invertAppearance = true; beggingContext.appearanceModifier = -2; beggingContext.crowdModifier = 1; return nil; }
        if (code == 24205)
        {
            beggingContext.extremeAppearance = true;
            try { rpgLiteScore(crossPhysician,beggingContext); }
            catch (RpgExpandedError error) { event('test.begging-error'); eventValue(error.reason); }
            return nil;
        }
        return inherited(context);
    }
;
