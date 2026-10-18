#include "expanded-fishing-forage.t"
huntingSkill: RpgLiteSkill id = 'crossbow' attribute = rpgDX difficulty = 0 defaultPenalty = -4;
huntingTraining: RpgTraining skill = huntingSkill points = 12;
modify bleedProfile skills = [plantTraining,plantOtherTraining,fishingTraining,huntingTraining] equipment = [huntingWeapon];
huntingMode: RpgLiteAttackMode skillId = 'crossbow' ranged = true hands = 2 minimumST = 7 capacity = 3;
huntingWeapon: RpgLiteWeapon id = 'repeating-crossbow' ready = true modes = [huntingMode] ammunition = 3;
huntingAttempt: RpgExpandedHuntingForageAttempt id = 'hunt-one' profile = bleedProfile site = plantSite skill = huntingSkill
    weapon = huntingWeapon mode = huntingMode ammunitionUsed = 2 ordinaryHunt = true
    ammunitionEvidence = 'Two loaded bolts expended in an ordinary hunt; no special projectile effects or retrieval'
    approved = true evidence = 'Ordinary small-game hunt beside the travel route';
modify plantSite gameAvailable = true;
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 1800 || code == 1801)
        {
            local value = huntingAttempt.resolve(); event('test.hunting-result'); eventValue(value.status); eventValue(value.reason);
            if (code == 1801) throw new RpgError(); return nil;
        }
        if (code == 1802)
        {
            local value = huntingAttempt.assess(); event('test.hunting-preview'); eventValue(value.status);
            eventValue(value.reason); eventValue(value.score); return nil;
        }
        if (code == 1803)
        {
            event('test.hunting-owned'); eventValue(huntingWeapon.ammunition);
            eventValue(bleedProfile.animalFoodForageAttempts.length()); eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds);
            eventValue(huntingAttempt.result == nil || huntingAttempt.result.forage == nil ? nil : huntingAttempt.result.forage.meals);
            eventValue(huntingAttempt.result == nil || huntingAttempt.result.forage == nil ? nil : huntingAttempt.result.forage.score);
            return nil;
        }
        if (code == 1804) { huntingWeapon.ammunition = 1; return nil; }
        if (code == 1805) { huntingMode.thrown = true; return nil; }
        if (code == 1806) { huntingAttempt.hands = 1; return nil; }
        if (code == 1807) { bleedInput.forcedRoll = 17; return nil; }
        if (code == 1808) { huntingAttempt.ammunitionEvidence = nil; return nil; }
        return inherited(context);
    }
;
