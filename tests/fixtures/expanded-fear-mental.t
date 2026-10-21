#include "expanded-fear-event-traits.t"
mentalVoices: RpgExpandedPhantomVoices approved = true level = 2 points = -10;
mentalDanger: RpgExpandedDangerAvoidance approved = true selfControlRating = 12;
mentalPleasure: RpgExpandedPleasureLoss approved = true;
mentalTruth: RpgExpandedTruthfulness approved = true selfControlRating = 6;
mentalCuriosity: RpgExpandedCuriosity approved = true selfControlRating = 6;
mentalAid: RpgExpandedCompelledAid approved = true selfControlRating = 12;
mentalMotivation: RpgExpandedLowMotivation approved = true selfControlRating = 12;
mentalBattle: RpgExpandedPostbattleStress approved = true selfControlRating = 6;
mentalAward: RpgExpandedFearMentalAcquisition id = 'lasting-mental' eventId = 'apparition' profile = fearProfile
    approved = true evidence = 'The author selects this concrete lasting mental response to the incident';
mentalWorseDanger: RpgExpandedDangerAvoidance approved = true selfControlRating = 9;
mentalWorsening: RpgExpandedFearMentalWorsening id = 'mental-worsening' eventId = 'later-incident' profile = fearProfile
    previous = mentalDanger replacement = mentalWorseDanger related = true approved = true
    evidence = 'A later physical threat worsens the existing logically related avoidance';
modify FearTestAction
    exec(context)
    {
        local code = fearInput.code;
        if (code == 580)
        {
            local choices = [mentalVoices,mentalVoices,mentalDanger,mentalPleasure,mentalTruth,mentalCuriosity,mentalAid,mentalMotivation,mentalBattle];
            rpgInteger(fearInput.row,1,9); mentalAward.trait = choices[fearInput.row];
            mentalAward.tableTotal = holds([2,4,7,8],fearInput.row) ? 35 : 23;
            if (fearInput.row == 2) { mentalVoices.level = 3; mentalVoices.points = -15; }
            fearProfile.creationComplete = true; fearProfile.disadvantageLimit = 0;
            fearProfile.earnedPoints = 9; fearProfile.unspentPoints = 7; return nil;
        }
        if (code == 581 || code == 582) { mentalAward.apply(); if (code == 582) throw new RpgError(); return nil; }
        if (code == 583)
        {
            event('test.fear-mental'); eventValue(fearProfile.traits.length()); eventValue(fearProfile.postCreationDisadvantageAllowance());
            eventValue(fearProfile.phantomVoiceSeverity()); eventValue(fearProfile.pleasureLossActive() ? 1 : 0);
            eventValue(fearProfile.physicalDangerFearPenalty()); eventValue(fearProfile.developmentRevision);
            eventValue(fearProfile.earnedPoints); eventValue(fearProfile.unspentPoints); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 584) { fearProfile.validateFeatures(); return nil; }
        if (code == 585 || code == 586) { mentalWorsening.apply(); if (code == 586) throw new RpgError(); return nil; }
        if (code == 587) { mentalAward.trait.active = nil; mentalAward.apply(); return nil; }
        if (code == 588)
        { local v = mentalAward.assess(); event('test.fear-mental-preview'); eventValue(v.status); eventValue(v.reason); return nil; }
        return inherited(context);
    }
;
