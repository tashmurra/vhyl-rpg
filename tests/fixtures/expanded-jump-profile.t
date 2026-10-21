#include "expanded-bleeding.t"
#include <vhyl-rpg-expanded-exploration.t>
#include <vhyl-rpg-expanded-traits.t>
jumpTrait: RpgExpandedEnhancedJump approved = true level = 2;
jumpSkill: RpgLiteSkill id = 'jumping' attribute = rpgDX difficulty = 0;
jumpTraining: RpgTraining skill = jumpSkill points = 8;
jumpDistance: RpgExpandedJumpDistance profile = bleedProfile prepared = true;
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 1300)
        {
            local value = jumpDistance.assess(); event('test.jump-profile'); eventValue(value.status);
            eventValue(value.reason); eventValue(value.basis); eventValue(value.highInchTenths);
            eventValue(value.broadInchTenths); eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
        }
        if (code == 1301) { bleedProfile.traits = [jumpTrait]; return nil; }
        if (code == 1302) { jumpTrait.mitigated = true; return nil; }
        if (code == 1303) { jumpDistance.runYards = 10; return nil; }
        if (code == 1304) { jumpDistance.prepared = nil; return nil; }
        if (code == 1305)
        {
            bleedProfile.st = 40; jumpDistance.strengthOption = true;
            jumpDistance.bodyWeightHundredths = 10000; jumpDistance.bodyWeightEvidence = 'Measured body weight'; return nil;
        }
        if (code == 1306) { jumpDistance.bodyWeightHundredths = 32000; return nil; }
        if (code == 1307) { jumpDistance.bodyWeightHundredths = 31999; return nil; }
        if (code == 1308) { jumpDistance.strengthOption = nil; return nil; }
        if (code == 1309) { bleedProfile.skills = [jumpTraining]; jumpDistance.skill = jumpSkill; return nil; }
        if (code == 1310) { jumpTrait.level = 100; return nil; }
        if (code == 1311) { event('test.jump-cost'); eventValue(jumpTrait.creationCost()); return nil; }
        if (code == 1312)
        {
            jumpDistance.skill = jumpSkill; event('test.jump-untrained');
            try { jumpDistance.assess(); eventValue('accepted'); }
            catch (RpgExpandedError error) { eventValue(error.reason); }
            return nil;
        }
        return inherited(context);
    }
;

modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 1330) { jumpTrait.level = 4; bleedProfile.traits = [jumpTrait]; return nil; }
        if (code == 1331 || code == 1332)
        {
            local value = jumpDistance.travelAssessment(code == 1331 ? 10000 : 20000);
            event('test.jump-travel'); eventValue(value.status); eventValue(value.reason);
            if (value.ofKind(RpgExpandedJumpTravelAssessment))
            { eventValue(value.speedNumerator); eventValue(value.speedDenominator); eventValue(value.seconds); }
            eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
        }
        if (code == 1333)
        {
            local cases = [[5,36000,36000],[25,36000,36000],[0,36001,36001],
                [0,36001,7200],[0,36001,7201],[5,36000,0],[5,36000,36001],
                [0,2147483647,2147483647]];
            foreach (local row in cases)
            {
                local value = rpgExpandedAssessJumpTravel(row[1],row[2],row[3]);
                event('test.jump-travel-table'); eventValue(value.status); eventValue(value.reason);
                eventValue(value.speedNumerator); eventValue(value.speedDenominator); eventValue(value.seconds);
            }
            return nil;
        }
        return inherited(context);
    }
;
