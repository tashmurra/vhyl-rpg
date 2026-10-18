#include "expanded-coughing.t"
painEpisode: RpgExpandedPain id = 'pain' profile = bleedProfile durationSeconds = 60
    approved = true evidence = 'An original resolved cause inflicts temporary pain';
painSkill: RpgLiteSkill id = 'health-task' attribute = rpgHT difficulty = 1;
painTraining: RpgTraining skill = painSkill points = 2;
painBehavior: RpgLiteTrait id = 'original-controlled-behavior' controlled = true points = -5;
modify bleedProfile skills = [painTraining] traits = [painBehavior];
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 550) { painEpisode.assess(); return nil; }
        if (code == 551 || code == 552)
        { painEpisode.apply(); if (code == 552) throw new RpgError(); return nil; }
        if (code == 553)
        {
            local check = new RpgLiteContext(); event('test.pain'); eventValue(bleedProfile.painPenalty());
            foreach (local attribute in [rpgDX,rpgIQ,rpgPerception,rpgWill,rpgHT])
            { check.attribute = attribute; eventValue(rpgLiteScore(bleedProfile,check)); }
            check.skill = painSkill; eventValue(rpgLiteScore(bleedProfile,check));
            check.skill = nil; check.attribute = rpgDX; check.defensiveReaction = true;
            eventValue(rpgLiteScore(bleedProfile,check)); eventValue(bleedProfile.basicSpeedQuarters());
            eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
        }
        if (code == 554) { painEpisode.severity = 'severe'; return nil; }
        if (code == 555) { painEpisode.severity = 'terrible'; return nil; }
        if (code == 556 || code == 557)
        {
            local trait = new RpgLiteTrait(); trait.id = code == 556 ? 'low-pain-threshold' : 'high-pain-threshold';
            bleedProfile.traits = bleedProfile.traits + [trait]; return nil;
        }
        if (code == 558 || code == 559)
        {
            local value = rpgLiteSelfControl(bleedProfile,painBehavior,0,code == 559);
            event('test.pain-control'); eventValue(value.status); eventValue(value.score);
            eventValue(value.outcome); eventValue(rpgRandom.draws); return nil;
        }
        return inherited(context);
    }
;
