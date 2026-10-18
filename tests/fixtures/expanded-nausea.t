#include "expanded-radiation.t"
nauseaSkill: RpgLiteSkill id = 'nausea-skill' attribute = rpgIQ difficulty = 0;
nauseaTraining: RpgTraining skill = nauseaSkill points = 1;
modify radiationProfile skills = [nauseaTraining];
nauseaFirst: RpgExpandedNausea id = 'first-cause' profile = radiationProfile durationSeconds = 60
    approved = true causeEvidence = 'A confirmed sixty-second affliction';
nauseaSecond: RpgExpandedNausea id = 'second-cause' profile = radiationProfile durationSeconds = 120
    approved = true causeEvidence = 'A separate confirmed two-minute affliction';
modify RadiationTestAction
    exec(context)
    {
        local code = radiationInput.code;
        if (code >= 20 && code <= 24)
        {
            local episode = code == 24 ? nauseaSecond : nauseaFirst;
            local value = code == 21 ? episode.assess() : episode.apply();
            event('test.nausea-result'); eventValue(value.status); eventValue(value.reason);
            if (code == 22) throw new RpgError(); return nil;
        }
        if (code == 25) { nauseaSecond.endEvidence = 'The cause was removed'; nauseaSecond.end(); return nil; }
        if (code == 30) { rpgSpendTime(radiationInput.days); return nil; }
        if (code == 32)
        {
            local skill = new RpgLiteContext(); skill.skill = nauseaSkill;
            local defense = new RpgLiteContext(); defense.kind = 'defense';
            local control = new RpgLiteContext(); control.kind = 'self-control'; control.attribute = rpgWill;
            event('test.nausea-contexts'); eventValue(rpgLiteScore(radiationProfile,skill));
            eventValue(rpgLiteScore(radiationProfile,defense)); eventValue(rpgLiteScore(radiationProfile,control)); return nil;
        }
        if (code == 31)
        {
            event('test.nausea');
            foreach (local attribute in [rpgST,rpgDX,rpgIQ,rpgHT,rpgWill,rpgPerception])
            {
                local context = new RpgLiteContext(); context.attribute = attribute;
                eventValue(rpgLiteScore(radiationProfile,context));
            }
            eventValue(radiationProfile.healthDefensePenalty()); eventValue(radiationProfile.nauseaEpisodes.length());
            eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        return inherited(context);
    }
;
