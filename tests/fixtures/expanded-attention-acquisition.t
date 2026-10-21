#include "expanded-attention-work.t"
attentionWorse: RpgExpandedShortAttention approved = true selfControlRating = 9;
attentionWorsening: RpgExpandedFearMentalWorsening id = 'attention-worse' eventId = 'later-distraction' profile = fearProfile
    previous = attentionTrait replacement = attentionWorse related = true approved = true evidence = 'A related later incident worsens the same trait';
modify FearTestAction
    exec(context)
    {
        local code = fearInput.code;
        if (code == 1290)
        {
            mentalAward.trait = attentionTrait; mentalAward.tableTotal = 23; fearProfile.creationComplete = true;
            fearProfile.earnedPoints = 9; fearProfile.unspentPoints = 7; fearProfile.money = 100; return nil;
        }
        if (code == 1291 || code == 1292)
        { attentionWorsening.apply(); if (code == 1292) throw new RpgError(); return nil; }
        if (code == 1293)
        {
            event('test.attention-acquisition'); eventValue(fearProfile.traits.length());
            eventValue(fearProfile.postCreationDisadvantageAllowance()); eventValue(fearProfile.earnedPoints);
            eventValue(fearProfile.unspentPoints); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 1294) { attentionWorkControl.trait = attentionWorse; attentionWork.begin(); return nil; }
        return inherited(context);
    }
;
