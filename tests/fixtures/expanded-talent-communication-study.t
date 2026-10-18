#include "expanded-communication-study.t"
communicationTalent: RpgLiteTrait id = 'artificer' points = 10 level = 2;
modify bleedProfile traits = [speechLimitation,communicationTalent];
modify learningSkill id = 'mechanic';
modify communicationStudy evidence = 'Approved mechanical work instruction using gestures';
modify BleedTestAction
    exec(context)
    {
        if (bleedInput.code == 6900)
        { learningStudy.credit = 2303960; learningStudy.creditThreshold = 2304000; return nil; }
        return inherited(context);
    }
;
