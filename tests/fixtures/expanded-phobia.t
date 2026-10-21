#include "expanded-fear-stress.t"
phobiaPurchase: RpgExpandedPhobia approved = true selfControlRating = 12;
phobiaExposure: RpgExpandedPhobiaExposure id = 'blood-scene' profile = fearProfile trait = phobiaPurchase
    cause = fearOccurrence approved = true evidence = 'The character sees blood in the chamber';
phobiaFirstContext: RpgExpandedPhobiaContext profile = fearProfile exposure = phobiaExposure approved = true
    evidence = 'Blood remains visible';
phobiaNextContext: RpgExpandedPhobiaContext profile = fearProfile exposure = phobiaExposure approved = true
    evidence = 'The same stimulus is still present ten minutes later';
phobiaFirstOccurrence: object;
phobiaNextOccurrence: object;
phobiaFirst: RpgExpandedPhobiaCheck id = 'phobia-first' context = phobiaFirstContext occurrence = phobiaFirstOccurrence;
phobiaNext: RpgExpandedPhobiaCheck id = 'phobia-next' context = phobiaNextContext occurrence = phobiaNextOccurrence;
phobiaStun: RpgExpandedFearStun id = 'phobia-first' context = phobiaFirstContext approved = true evidence = 'Retained table row four';
phobiaSkill: RpgLiteContext attribute = rpgDX;
modify FearTestAction
    exec(context)
    {
        local code = fearInput.code;
        if (code == 380) { fearProfile.traits = [phobiaPurchase]; fearEventInput.initialRoll = 10; return nil; }
        if (code == 381) { phobiaExposure.start(); return nil; }
        if (code == 382 || code == 383) { phobiaFirst.resolve(); if (code == 383) throw new RpgError(); return nil; }
        if (code == 384)
        {
            event('test.phobia'); eventValue(phobiaExposure.checks.length()); eventValue(phobiaExposure.penalty());
            eventValue(rpgLiteScore(fearProfile,phobiaSkill)); eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
        }
        if (code == 385) { rpgSpendTime(600); return nil; }
        if (code == 386) { phobiaNext.resolve(); return nil; }
        if (code == 387) { phobiaExposure.end(true,'The blood is covered and no longer perceived'); return nil; }
        if (code == 388) { fearEventInput.initialRoll = 13; fearProfile.traits = [phobiaPurchase,eventVoices]; return nil; }
        if (code == 389) { phobiaFirst.applyConsequence(phobiaStun); return nil; }
        if (code == 390)
        { phobiaFirstContext.threatOnly = true; fearEventInput.initialRoll = 14; return nil; }
        if (code == 391) { phobiaPurchase.selfControlRating = fearInput.row; return nil; }
        if (code == 392) { rpgSpendTime(601); return nil; }
        if (code == 500) { rpgLiteSelfControl(fearProfile,phobiaPurchase,0,nil); return nil; }
        if (code == 400)
        {
            event('test.phobia-tables');
            eventValue(rpgExpandedPhobiaBase('machinery',4,'unknown')); eventValue(rpgExpandedPhobiaBase('machinery',5,'unknown'));
            eventValue(rpgExpandedPhobiaBase('sharp',5,'unknown')); eventValue(rpgExpandedPhobiaBase('sharp',6,'unknown'));
            foreach (local prevalence in ['common','uncommon','unknown']) eventValue(rpgExpandedPhobiaBase('magic',0,prevalence));
            foreach (local count in [13,25,26,99,100,999,1000,9999,10000]) eventValue(rpgExpandedPhobiaModifier('crowds','ordinary',count));
            eventValue(rpgExpandedPhobiaModifier('dead','known-body',0)); eventValue(rpgExpandedPhobiaModifier('dead','animated-or-ghost',0));
            eventValue(rpgExpandedPhobiaModifier('dirt','unfamiliar-food',0)); eventValue(rpgExpandedPhobiaModifier('heights','fall-risk',0));
            eventValue(rpgExpandedPhobiaModifier('insects','large-or-poisonous',0)); eventValue(rpgExpandedPhobiaModifier('reptiles','horde',0));
            return nil;
        }
        return inherited(context);
    }
;
