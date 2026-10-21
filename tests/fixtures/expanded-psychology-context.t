#include "expanded-psychology-skill.t"
#include <vhyl-rpg-expanded-traits.t>
psychologySubject: RpgExpandedProfile rules = healthRules;
psychologyCallousness: RpgExpandedCallousness approved = true;
psychologyContext: RpgExpandedPsychologyContext skill = psychologyApplied subject = psychologySubject subjectSpecies = 'river-folk'
    approved = true evidence = 'The subject and applicable relationship facts are established';
modify psychologyTraining skill = psychologyApplied;
modify crossPhysician skills = [psychologyTraining];
modify PhysicianFixtureAction
    exec(context)
    {
        local code = healthInput.code;
        if (code == 20900)
        {
            try { event('test.psychology-context'); eventValue(rpgLiteScore(crossPhysician,psychologyContext)); eventValue(rpgRandom.draws); }
            catch (RpgExpandedError error) { event('test.psychology-context-error'); eventValue(error.reason); }
            return nil;
        }
        if (code == 20901) { psychologyContext.knownWell = true; return nil; }
        if (code == 20902) { psychologyContext.knownPersonalityType = true; return nil; }
        if (code == 20903) { psychologyContext.purpose = 'diagnosis'; psychologyContext.subjectPresent = true; psychologyContext.empathyModifier = 3; return nil; }
        if (code == 20904) { crossPhysician.traits = [psychologyCallousness]; return nil; }
        if (code == 20905) { psychologyContext.purpose = 'exploit-weakness'; return nil; }
        if (code == 20906) { psychologyContext.subjectPresent = nil; return nil; }
        if (code == 20907) { psychologyContext.skill = psychologyExperimental; return nil; }
        if (code == 20908) { psychologyContext.empathyModifier = -3; return nil; }
        if (code == 20909) { psychologyContext.empathyModifier = 1; return nil; }
        return inherited(context);
    }
;
