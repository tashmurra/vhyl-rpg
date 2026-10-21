#include "expanded-free-fall-skill.t"
#include <vhyl-rpg-expanded-traits.t>
orientationTrait: RpgExpandedOrientationSense approved = true;
orientationLand: RpgExpandedSkill id = 'navigation' specialty = 'land' attribute = rpgIQ difficulty = 1;
orientationSpace: RpgExpandedSkill id = 'navigation' specialty = 'space' attribute = rpgIQ difficulty = 1;
orientationBody: RpgExpandedSkill id = 'body-sense' attribute = rpgDX difficulty = 2;
orientationPilot: RpgExpandedSkill id = 'piloting' specialty = 'light-aircraft' attribute = rpgDX difficulty = 1;
orientationAero: RpgExpandedSkill id = 'aerobatics' attribute = rpgDX difficulty = 2;
orientationTask: RpgLiteContext skill = fallSkill;
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 9400) { bleedProfile.traits = [orientationTrait]; bleedProfile.orientationEnvironment = 'local'; return nil; }
        if (code == 9401) { orientationTrait.level = 2; return nil; }
        if (code == 9402) { bleedProfile.orientationEnvironment = 'deep-space'; return nil; }
        if (code == 9403) { bleedProfile.orientationEnvironment = 'cross-dimensional'; return nil; }
        if (code == 9404)
        {
            event('test.orientation'); eventValue(orientationTrait.creationCost());
            foreach (local skill in [fallSkill,orientationLand,orientationSpace,orientationBody,orientationPilot,orientationAero])
                eventValue(bleedProfile.orientationSkillModifier(skill));
            eventValue(bleedProfile.skillScore(fallSkill)); eventValue(rpgLiteScore(bleedProfile,orientationTask));
            eventValue(rpgRandom.draws); return nil;
        }
        if (code == 9405)
        {
            local copy = rpgExpandedTemplateTraits.copy(orientationTrait);
            event('test.orientation-copy'); eventValue(copy != orientationTrait ? 1 : 0); eventValue(copy.creationCost()); return nil;
        }
        if (code == 9406)
        {
            bleedProfile.orientationEnvironment = nil; event('test.orientation-environment');
            try { bleedProfile.skillScore(fallSkill); eventValue('accepted'); }
            catch (RpgExpandedError error) { eventValue(error.reason); }
            bleedProfile.orientationEnvironment = 'local'; return nil;
        }
        return inherited(context);
    }
;
