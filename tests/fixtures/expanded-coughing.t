#include "expanded-bleeding.t"
coughStealth: RpgLiteSkill id = 'stealth' attribute = rpgDX difficulty = 1;
coughStealthTraining: RpgTraining skill = coughStealth points = 2;
coughDance: RpgLiteSkill id = 'dancing' attribute = rpgDX difficulty = 1;
coughDanceTraining: RpgTraining skill = coughDance points = 2;
modify bleedProfile skills = [coughStealthTraining,coughDanceTraining];
coughEpisode: RpgExpandedCoughing id = 'irritation' profile = bleedProfile durationSeconds = 60
    approved = true evidence = 'An original irritant causes coughing for sixty seconds';
coughOther: RpgExpandedCoughing id = 'another-irritation' profile = bleedProfile durationSeconds = 60
    approved = true evidence = 'A separately resolved irritant';
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 410) { coughEpisode.assess(); return nil; }
        if (code == 411 || code == 412)
        { coughEpisode.apply(); if (code == 412) throw new RpgError(); return nil; }
        if (code == 413)
        {
            local check = new RpgLiteContext(); event('test.coughing'); eventValue(bleedProfile.coughing() ? 1 : 0);
            foreach (local attribute in [rpgDX,rpgIQ,rpgPerception,rpgWill])
            { check.attribute = attribute; eventValue(rpgLiteScore(bleedProfile,check)); }
            check.skill = coughStealth; eventValue(rpgLiteScore(bleedProfile,check));
            check.skill = coughDance; eventValue(rpgLiteScore(bleedProfile,check));
            check.skill = nil; check.attribute = rpgDX; check.defensiveReaction = true;
            eventValue(rpgLiteScore(bleedProfile,check)); eventValue(bleedProfile.basicSpeedQuarters());
            eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 414) { rpgSpendTime(59); return nil; }
        if (code == 415) { rpgSpendTime(1); return nil; }
        if (code == 416) { coughOther.apply(); return nil; }
        return inherited(context);
    }
;
