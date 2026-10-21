#include "expanded-fear-compound.t"
compoundVoices: RpgExpandedPhantomVoices approved = true level = 2 points = -10;
compoundMentalAward: RpgExpandedFearMentalAcquisition id = 'compound-mental' eventId = 'apparition' profile = fearProfile
    trait = compoundVoices approved = true evidence = 'The incident causes lasting phantom voices as well as loss of consciousness';
modify FearTestAction
    exec(context)
    {
        local code = fearInput.code;
        if (code == 590)
        {
            if (!holds([27,39,40],fearInput.row)) rpgExpandedReject('fixture-compound-row');
            fearProfile.creationComplete = true; fearProfile.disadvantageLimit = 0;
            fearProfile.earnedPoints = 9; fearProfile.unspentPoints = 7;
            compoundFear.tableTotal = fearInput.row; compoundFear.acquisition = compoundMentalAward;
            compoundFear.episode = fearInput.row == 27 ? compoundFaint : compoundComa;
            if (fearInput.row != 27)
            { compoundVoices.level = 3; compoundVoices.points = -15; compoundMentalAward.tableTotal = 35; }
            return nil;
        }
        if (code == 591)
        { event('test.mental-compound'); eventValue(fearProfile.phantomVoiceSeverity()); eventValue(fearProfile.iq);
          eventValue(fearProfile.postCreationDisadvantageAllowance()); return nil; }
        return inherited(context);
    }
;
