#include "expanded-phobia.t"
#include <vhyl-rpg-expanded-skills.t>
phobiaSubject: RpgExpandedSkill id = 'authored-subject' attribute = rpgIQ difficulty = 1;
machinePhobia: RpgExpandedPhobia scope = 'machinery' technology = 4 points = -5 approved = true;
magicPhobia: RpgExpandedPhobia scope = 'magic' prevalence = 'common' points = -15 approved = true;
modify FearTestAction
    exec(context)
    {
        local code = fearInput.code;
        if (code == 490) { fearProfile.traits = [machinePhobia]; return nil; }
        if (code == 491) { fearProfile.traits = [magicPhobia]; return nil; }
        if (code == 492)
        { event('test.phobia-learning'); eventValue(fearProfile.skillLearningReason(phobiaSubject)); eventValue(rpgRandom.draws); return nil; }
        if (code == 493) { phobiaSubject.phobiaLearningKinds = ['machine-repair']; phobiaSubject.phobiaLearningEvidence = 'Repairs machines'; return nil; }
        if (code == 494) { phobiaSubject.phobiaLearningKinds = ['complex-machine-use']; phobiaSubject.phobiaLearningEvidence = 'Operates complex machinery'; return nil; }
        if (code == 495) { phobiaSubject.phobiaLearningKinds = ['simple-machine-use']; phobiaSubject.phobiaLearningEvidence = 'Bicycle-level operation'; return nil; }
        if (code == 496) { phobiaSubject.phobiaLearningKinds = ['magic']; phobiaSubject.phobiaLearningEvidence = 'Uses magic'; return nil; }
        if (code == 497) { phobiaSubject.phobiaLearningKinds = ['other']; phobiaSubject.phobiaLearningEvidence = 'Unrelated subject'; return nil; }
        return inherited(context);
    }
;
