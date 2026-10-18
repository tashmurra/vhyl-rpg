#include "expanded-bleeding.t"
#include <vhyl-rpg-expanded-exploration.t>
hikingSkill: RpgLiteSkill id = 'hiking' attribute = rpgHT difficulty = 1 defaultPenalty = -5;
hikingSkiSkill: RpgLiteSkill id = 'skiing' attribute = rpgHT difficulty = 2 defaultPenalty = -6;
hikingLeaderSkill: RpgLiteSkill id = 'leadership' attribute = rpgIQ difficulty = 1 defaultPenalty = -5;
hikingTraining: RpgTraining skill = hikingSkill points = 4;
hikingLeaderTraining: RpgTraining skill = hikingLeaderSkill points = 8;
modify bleedProfile skills = [hikingTraining,hikingLeaderTraining];
hikingPartner: RpgExpandedProfile rules = bleedRules dx = 6;
hikingAttempt: RpgExpandedHikingAttempt id = 'daily-walk' members = [[bleedProfile,hikingSkill,0,nil]]
    approved = true evidence = 'Ordinary daily march; no extra effort or terrain skill bonus';
hikingSecond: RpgExpandedHikingAttempt id = 'second-walk' members = [[bleedProfile,hikingSkill,0,nil]]
    approved = true evidence = 'Another request for the same traveler';
hikingConditions: RpgExpandedHikingConditions;
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 1100)
        {
            local value = hikingAttempt.assess(); event('test.hiking-preview'); eventValue(value.status);
            eventValue(value.reason); eventValue(value.score); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 1101 || code == 1102)
        { hikingAttempt.resolve(); if (code == 1102) throw new RpgError(); return nil; }
        if (code == 1103)
        {
            event('test.hiking-owned'); eventValue(bleedProfile.hikingAttempts.length());
            eventValue(hikingPartner.hikingAttempts.length()); eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds);
            eventValue(hikingAttempt.result == nil ? nil : hikingAttempt.result.score);
            eventValue(hikingAttempt.result != nil && hikingAttempt.result.check.achieved ? 1 : 0);
            eventValue(hikingAttempt.result == nil ? nil : hikingAttempt.result.day); return nil;
        }
        if (code == 1104)
        {
            event('test.hiking-second');
            try { eventValue(hikingSecond.resolve().status); }
            catch (RpgExpandedError error) { eventValue(error.reason); }
            return nil;
        }
        if (code == 1105)
        {
            hikingAttempt.members = [[bleedProfile,hikingSkill,0,nil],[hikingPartner,hikingSkill,0,nil]];
            hikingAttempt.leader = bleedProfile; hikingAttempt.leadershipSkill = hikingLeaderSkill; return nil;
        }
        if (code == 1106) { hikingLeaderTraining.points = 4; return nil; }
        if (code == 1107)
        {
            local multipliers = hikingAttempt.members.length() == 1 ? [100] : [100,100];
            local value = hikingAttempt.assessPace(hikingConditions,multipliers);
            event('test.hiking-pace'); eventValue(value.milesHundredths); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 1108) { rpgSpendTime(86400); return nil; }
        if (code == 1109) { hikingSecond.members = [[bleedProfile,hikingSkiSkill,0,nil]]; return nil; }
        if (code == 1110) { hikingAttempt.members = [[bleedProfile,hikingSkill,1,nil]]; return nil; }
        if (code == 1111) { hikingConditions.weather = 'deep-snow'; hikingConditions.equipment = 'skis'; return nil; }
        if (code == 1112) { hikingSecond.members = [[hikingPartner,hikingSkill,0,nil]]; return nil; }
        if (code == 1113)
        {
            event('test.hiking-pace-error');
            try { hikingAttempt.assessPace(hikingConditions,[100]); eventValue('ready'); }
            catch (RpgExpandedError error) { eventValue(error.reason); }
            return nil;
        }
        return inherited(context);
    }
;
