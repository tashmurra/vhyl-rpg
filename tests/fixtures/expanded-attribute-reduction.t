#include "expanded-bleeding.t"
attributeEpisode: RpgExpandedAttributeReduction id = 'resolved-weakening' profile = bleedProfile
    attribute = rpgIQ penalty = 2 durationSeconds = 60 approved = true
    evidence = 'An authored resolved effect temporarily reduces intelligence by two';
attributeSkill: RpgLiteSkill id = 'observation' attribute = rpgPerception difficulty = 1;
attributeTraining: RpgTraining skill = attributeSkill points = 2;
modify bleedProfile skills = [attributeTraining];
attributeContext: RpgLiteContext attribute = rpgIQ;
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 7800 || code == 7801)
        {
            local value = code == 7800 ? attributeEpisode.assess() : attributeEpisode.apply();
            event('test.attribute-reduction'); eventValue(value.status); eventValue(value.reason); return nil;
        }
        if (code == 7802)
        {
            event('test.attribute-state'); eventValue(rpgLiteScore(bleedProfile,attributeContext));
            eventValue(bleedProfile.iq); eventValue(bleedProfile.maxHP); eventValue(bleedProfile.maxEnergy);
            eventValue(bleedProfile.basicSpeedQuarters()); eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 7803) { attributeContext.attribute = rpgWill; return nil; }
        if (code == 7804) { attributeContext.skill = attributeSkill; return nil; }
        if (code == 7805) { attributeContext.kind = 'resistance'; return nil; }
        if (code == 7806) { attributeContext.defensiveReaction = true; return nil; }
        if (code == 7807) { rpgSpendTime(59); return nil; }
        if (code == 7808) { rpgSpendTime(1); return nil; }
        if (code == 7809) { attributeEpisode.apply(); throw new RpgError(); }
        if (code == 7810) { attributeEpisode.attribute = rpgDX; attributeContext.attribute = rpgDX; return nil; }
        if (code == 7811) { attributeEpisode.attribute = rpgHT; attributeContext.attribute = rpgHT; return nil; }
        return inherited(context);
    }
;
