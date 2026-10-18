#include "expanded.t"
boatingHero: RpgExpandedProfile rules = expandedRules techLevel = 8 campaignTL = 8 dx = 12 iq = 14;
modify ExpandedTestAction
    exec(context)
    {
        local code = expandedInput.code;
        if (code == 16800)
        {
            local skills = [];
            foreach (local name in ['large-powerboat','motorboat','sailboat','unpowered'])
            { local skill = new RpgExpandedBoatingSkill(); skill.specialty = name; skill.techLevel = 8; skills = skills + [skill]; }
            event('test.boating-matrix');
            foreach (local target in skills)
                foreach (local source in skills)
                {
                    local training = new RpgExpandedTraining(); training.skill = source; training.points = 32;
                    boatingHero.skills = [training]; eventValue(boatingHero.skillScore(target));
                }
            return nil;
        }
        if (code == 16801)
        {
            local skill = new RpgExpandedBoatingSkill(); skill.specialty = 'sailboat'; skill.techLevel = 8;
            local c = new RpgExpandedBoatingContext(); c.skill = skill; c.eventKind = 'enter';
            boatingHero.skills = []; event('test.boating-checks'); eventValue(c.checkRequired(boatingHero));
            eventValue(rpgLiteScore(boatingHero,c));
            local training = new RpgExpandedTraining(); training.skill = skill; training.points = 8;
            boatingHero.skills = [training]; eventValue(c.checkRequired(boatingHero));
            eventValue(c.unavailableReason(boatingHero));
            c.eventKind = 'hazard'; c.conditionsPenalty = -3; c.evidence = 'Foul weather';
            eventValue(c.checkRequired(boatingHero)); eventValue(rpgLiteScore(boatingHero,c));
            c.eventKind = 'routine'; eventValue(c.checkRequired(boatingHero)); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 16802)
        {
            local seamanship = new RpgExpandedSkill(); seamanship.id = 'seamanship'; seamanship.attribute = rpgIQ;
            seamanship.difficulty = 0; seamanship.techLevel = 8;
            local training = new RpgExpandedTraining(); training.skill = seamanship; training.points = 8;
            boatingHero.skills = [training]; event('test.boating-crew-default');
            foreach (local name in ['large-powerboat','motorboat'])
            { local skill = new RpgExpandedBoatingSkill(); skill.techLevel = 8; skill.specialty = name; eventValue(boatingHero.skillScore(skill)); }
            return nil;
        }
        return inherited(context);
    }
;
