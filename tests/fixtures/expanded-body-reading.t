#include "expanded-lie-detection.t"
bodyReadingSkill: RpgExpandedBodyReadingSkill;
bodyReadingTraining: RpgTraining skill = bodyReadingSkill points = 20;
modify lieObserver skills = [bodyReadingTraining];
bodyReading: RpgExpandedBodyReadingLieDetection id = 'visual-alibi' observer = lieObserver subject = lieSubject
    skill = bodyReadingSkill statement = 'The witness claims to have stayed home' truthKnown = true subjectLying = true
    approved = true evidence = 'Known scene facts' visible = true visualEvidence = 'One visible subject in clear light';
modify ExpandedTestAction
    exec(context)
    {
        local code = expandedInput.code;
        if (code == 18600)
        {
            local scores = [];
            foreach (local cover in ['none','baggy','shield','cloak','mask'])
            { bodyReading.concealment = cover; scores = scores + [bodyReading.assess().observerScore]; }
            event('test.body-reading-scores'); eventValue(scores); return nil;
        }
        if (code == 18601) { bodyReading.visible = nil; return nil; }
        if (code == 18602) { bodyReading.concealment = 'mask'; bodyReading.bodyVisible = nil; return nil; }
        if (code == 18603) { bodyReading.physiology = 'machine'; return nil; }
        if (code == 18604) { bodyReading.combat = true; return nil; }
        if (code == 18605)
        {
            local value = bodyReading.apply(); event('test.body-reading-result'); eventValue(value.status); eventValue(value.reason);
            eventValue(value.conclusion); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 18606)
        {
            bodyReading.physiology = 'similar'; bodyReading.speciesModifier = -3;
            bodyReading.visionModifier = -2; bodyReading.easyToRead = true;
            event('test.body-reading-modified'); eventValue(bodyReading.assess().observerScore); return nil;
        }
        if (code == 18607)
        {
            event('test.body-reading-default'); eventValue(lieObserver.skillScore(lieSkill)); return nil;
        }
        if (code == 18608)
        {
            lieObserver.skills = [lieTraining];
            event('test.body-reading-default'); eventValue(lieObserver.skillScore(bodyReadingSkill)); return nil;
        }
        return inherited(context);
    }
;
