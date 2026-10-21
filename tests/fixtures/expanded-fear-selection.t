#include "expanded-fear-mental.t"
selectionHumor: RpgExpandedHumorlessness approved = true;
selectionDistrust: RpgExpandedPervasiveDistrust approved = true;
selectionSocial: RpgExpandedSocialInhibition level = 2 approved = true;
selectionCompany: RpgExpandedCompanionship level = 2 approved = true;
selectionAppearance: RpgExpandedAppearance tier = -4 approved = true;
selectionDistinctive: RpgExpandedDistinctiveFeatures level = 5 species = 'human' description = 'A permanently stark change in hair and skin'
    origin = 'The authored physical consequences of the incident' approved = true;
selectionPain: RpgExpandedRecurrentPain severity = 3 intervalHours = 2 frequency = 9 approved = true;
selectionSensitive: RpgExpandedPainSensitivity approved = true;
selectionHearing: RpgExpandedHearingImpairment approved = true;
selectionWound: RpgExpandedPersistentWound approved = true;
selectionHearingContext: RpgLiteContext attribute = rpgPerception kind = 'hearing';
selectionPainDay: RpgExpandedRecurrentPainDay id = 'new-pain-day' profile = fearProfile trait = selectionPain onsetAt = 0
    approved = true evidence = 'The first waking day after the acquired pain condition';
selectionPhysical: RpgExpandedFearPhysicalAcquisition id = 'selection-physical' eventId = 'apparition' profile = fearProfile
    approved = true evidence = 'The author selects these lasting physical effects of the incident';
selectionFaint: RpgExpandedFearFaint id = 'apparition' context = fearContext tableTotal = 18 approved = true
    evidence = 'The new mental condition accompanies the selected faint';
selectionCompound: RpgExpandedFearTraitCompound id = 'apparition' context = fearContext tableTotal = 27
    acquisition = mentalAward episode = selectionFaint;
selectionFallbackAward: RpgExpandedFearMentalAcquisition id = 'new-distrust' eventId = 'later-incident' profile = fearProfile
    trait = selectionDistrust approved = true evidence = 'The author selects a new concrete consequence because the existing trait has no self-control rating';
selectionFallback: RpgExpandedFearMentalWorsening id = 'fixed-trait-fallback' eventId = 'later-incident' profile = fearProfile
    previous = selectionHumor fallback = selectionFallbackAward related = true approved = true
    evidence = 'A fixed trait cannot have its nonexistent self-control rating reduced; the author selects the fallback';
selectionSkill: RpgLiteSkill id = 'acting' attribute = rpgIQ difficulty = 1;
selectionTraining: RpgTraining skill = selectionSkill points = 2;
selectionContext: RpgLiteContext skill = selectionSkill company = selectionAlone;
selectionAlone: RpgExpandedCompany subject = fearProfile members = [fearProfile] approved = true evidence = 'The actor is currently alone';
modify FearTestAction
    exec(context)
    {
        local code = fearInput.code;
        if (code == 650)
        {
            rpgInteger(fearInput.row,1,4); mentalAward.trait = [selectionHumor,selectionDistrust,selectionSocial,selectionCompany][fearInput.row];
            mentalAward.tableTotal = 23; fearProfile.creationComplete = true; fearProfile.disadvantageLimit = 0;
            fearProfile.skills = [selectionTraining]; return nil;
        }
        if (code == 651)
        {
            rpgInteger(fearInput.row,1,5); fearProfile.creationComplete = true; fearProfile.disadvantageLimit = 0;
            selectionPhysical.tableTotal = fearInput.row == 1 ? 36 : fearInput.row == 2 ? 37 : 24;
            selectionPhysical.purchases = fearInput.row <= 2 ? [selectionAppearance]
                : fearInput.row == 3 ? [selectionSensitive,selectionDistinctive]
                : fearInput.row == 4 ? [selectionPain] : [selectionHearing,selectionWound];
            if (fearInput.row == 2) { selectionAppearance.tier = -5; selectionAppearance.universal = true; }
            return nil;
        }
        if (code == 652 || code == 653)
        { selectionPhysical.apply(); if (code == 653) throw new RpgError(); return nil; }
        if (code == 654)
        {
            event('test.fear-selection'); eventValue(fearProfile.traits.length()); eventValue(fearProfile.postCreationDisadvantageAllowance());
            eventValue(fearProfile.humorlessnessActive() ? 1 : 0); eventValue(fearProfile.pervasiveDistrustActive() ? 1 : 0);
            eventValue(fearProfile.socialInhibitionPenalty()); eventValue(fearProfile.companionshipLevel());
            eventValue(fearProfile.developmentRevision); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 655)
        {
            event('test.fear-selection-effect'); local appearance = fearProfile.appearanceTrait();
            eventValue(appearance == nil ? 0 : appearance.modifierForObserver(true,true,nil,nil,0));
            eventValue(fearProfile.distinctiveFeatureLevels());
            eventValue(holds(fearProfile.traits,selectionPain) ? selectionPain.awakePenalty() : 0); return nil;
        }
        if (code == 656) { selectionAppearance.universal = !selectionAppearance.universal; selectionPhysical.assess(); return nil; }
        if (code == 657) { selectionPain.frequency = 12; selectionPhysical.assess(); return nil; }
        if (code == 659)
        { fearEventInput.initialRoll = 3; selectionPainDay.resolve(); return nil; }
        if (code == 660)
        { event('test.fear-selection-pain'); eventValue(fearProfile.recurrentPainPenalty()); eventValue(rpgRandom.draws); return nil; }
        if (code == 662 || code == 663)
        { selectionCompound.apply(); if (code == 663) throw new RpgError(); return nil; }
        if (code == 664)
        { event('test.fear-selection-compound'); eventValue(fearProfile.unconscious ? 1 : 0);
          eventValue(fearProfile.fearBeliefCompounds.length()); return nil; }
        if (code == 665 || code == 666)
        { selectionFallback.apply(); if (code == 666) throw new RpgError(); return nil; }
        if (code == 661)
        { event('test.fear-selection-hearing'); eventValue(rpgLiteScore(fearProfile,selectionHearingContext)); return nil; }
        if (code == 658) { event('test.fear-selection-skill'); eventValue(rpgLiteScore(fearProfile,selectionContext)); return nil; }
        return inherited(context);
    }
;

selectionUnderstanding: RpgExpandedEmotionalUnderstandingDeficit approved = true;
selectionOblivious: RpgExpandedEmotionalObliviousness approved = true;
selectionCallous: RpgExpandedCallousness approved = true;
selectionLearning: RpgExpandedLearningBar approved = true;
selectionFixedSkill: RpgLiteSkill id = 'acting' attribute = rpgIQ difficulty = 1;
selectionFixedContext: RpgLiteContext skill = selectionFixedSkill;
modify FearTestAction
    exec(context)
    {
        local code = fearInput.code;
        if (code == 820)
        {
            rpgInteger(fearInput.row,1,4);
            selectionFallback.previous = [selectionUnderstanding,selectionOblivious,selectionCallous,selectionLearning][fearInput.row];
            fearProfile.traits = [selectionFallback.previous]; fearProfile.creationComplete = true;
            fearProfile.earnedPoints = 9; fearProfile.unspentPoints = 7;
            selectionFixedSkill.id = fearInput.row == 2 ? 'fast-talk' : fearInput.row == 3 ? 'teaching' : 'acting';
            return nil;
        }
        if (code == 821)
        {
            event('test.fixed-mental-fallback'); eventValue(holds(fearProfile.traits,selectionFallback.previous) ? 1 : 0);
            eventValue(fearProfile.traits.length()); eventValue(selectionFallback.previous.creationCost());
            eventValue(fearProfile.postCreationDisadvantageAllowance()); eventValue(fearProfile.developmentRevision);
            eventValue(fearProfile.earnedPoints); eventValue(fearProfile.unspentPoints);
            eventValue(selectionFixedContext.socialTraitModifier(fearProfile));
            eventValue(fearProfile.learningAcquisitionReason('skill')); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 822) { selectionFallback.previous.approved = nil; selectionFallback.assess(); return nil; }
        if (code == 823)
        { local value = selectionFallback.assess(); event('test.fixed-mental-preview'); eventValue(value.status); eventValue(value.reason); return nil; }
        return inherited(context);
    }
;
