#include "expanded-emotional-obliviousness.t"
#include <vhyl-rpg-expanded-social.t>
callousTrait: RpgExpandedCallousness approved = true;
callousDuplicate: RpgExpandedCallousness approved = true;
modify bleedProfile traits = [callousTrait];
callousSkill: RpgLiteSkill id = 'teaching' attribute = rpgIQ difficulty = 1 defaultPenalty = -5;
callousContext: RpgExpandedCallousnessContext
    subject = bleedProfile target = obliviousTarget skill = callousSkill
    approved = true evidence = 'Authored interaction with the selected participant.'
;
callousReaction: RpgExpandedCallousnessReactionContext
    subject = bleedProfile observer = obliviousTarget approved = true
    evidence = 'Authored history and emotional perception of this observer.'
;
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 3200)
        {
            event('test.callousness'); eventValue(callousTrait.creationCost());
            eventValue(callousContext.socialTraitModifier(bleedProfile));
            eventValue(callousReaction.traitReactionModifier(bleedProfile)); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 3201) { callousSkill.id = 'psychology'; return nil; }
        if (code == 3202) { callousContext.helpfulPsychology = true; return nil; }
        if (code == 3203) { callousContext.pastVictim = true; callousReaction.pastVictim = true; return nil; }
        if (code == 3204) { callousSkill.id = 'intimidation'; callousContext.coercive = true; return nil; }
        if (code == 3205) { callousReaction.empathicObserver = true; return nil; }
        if (code == 3206) { callousTrait.mitigated = true; return nil; }
        if (code == 3207) { callousContext.approved = nil; return nil; }
        if (code == 3208) { bleedProfile.traits = [callousTrait,callousDuplicate]; return nil; }
        if (code == 3209)
        {
            event('test.callousness-error');
            try { callousContext.socialTraitModifier(bleedProfile); eventValue('accepted'); }
            catch (RpgExpandedError error) { eventValue(error.reason); }
            eventValue(rpgRandom.draws); return nil;
        }
        return inherited(context);
    }
;
