#include "expanded-fear-mental.t"
fixationTrait: RpgExpandedGoalFixation approved = true initialGoal = 'Recover the lost survey';
fixationPursue: object;
fixationDetour: object;
fixationControl: RpgExpandedFixationTrigger id = 'collapsing-archive' profile = fearProfile trait = fixationTrait
    goal = 'Recover the lost survey' deviationWise = true pursuitActions = [fixationPursue]
    trigger = 'evacuation' evidence = 'Leaving the unsafe archive would be wise';
fixationPermission: RpgExpandedFixationActionPermission profile = fearProfile trait = fixationTrait
    goal = 'Recover the lost survey' action = fixationDetour deviation = fixationControl approved = true
    rationale = 'Leave the collapsing archive rather than continue searching';
fixationComplete: RpgExpandedFixationFulfillment id = 'survey-recovered' profile = fearProfile trait = fixationTrait
    previousGoal = 'Recover the lost survey' nextGoal = 'Map the uncharted valley' approved = true
    evidence = 'The recovered survey has been identified and secured';
fixationSecondComplete: RpgExpandedFixationFulfillment id = 'valley-mapped' profile = fearProfile trait = fixationTrait
    previousGoal = 'Map the uncharted valley' approved = true evidence = 'The map is finished and verified';
fixationBasis: RpgExpandedBuyoffBasis owner = fearProfile trait = fixationTrait originalBonus = 0 approved = true
    evidence = 'This fear acquisition awarded no spendable character points';
fixationWorld: object leftArchive = nil;
modify FearTestAction
    exec(context)
    {
        local code = fearInput.code;
        if (code == 840)
        { mentalAward.trait = fixationTrait; mentalAward.tableTotal = 23; fearProfile.creationComplete = true;
          fearProfile.earnedPoints = 9; fearProfile.unspentPoints = 7; return nil; }
        if (code == 841 || code == 842)
        { fixationControl.resolve(); if (code == 842) throw new RpgError(); return nil; }
        if (code == 843)
        {
            local value = fixationPermission.assess(); event('test.fixation-permission'); eventValue(value.status); eventValue(value.reason);
            if (value.status == 'ready') fixationWorld.leftArchive = true; return nil;
        }
        if (code == 844 || code == 845)
        { fixationComplete.apply(); if (code == 845) throw new RpgError(); return nil; }
        if (code == 846)
        {
            event('test.fixation'); eventValue(fearProfile.fixationGoal(fixationTrait)); eventValue(fearProfile.traits.length());
            eventValue(fearProfile.fixationFulfillments.length()); eventValue(fearProfile.unspentPoints);
            eventValue(fixationWorld.leftArchive ? 1 : 0); eventValue(rpgRandom.draws);
            eventValue(fixationControl.result == nil ? nil : fixationControl.permits(fixationPursue) ? 1 : 0); return nil;
        }
        if (code == 847) { fixationControl.giveIn = true; return nil; }
        if (code == 848) { fearProfile.developmentOpen = true; fearProfile.buyoffBases = [fixationBasis]; return nil; }
        if (code == 849 || code == 850)
        { fixationSecondComplete.apply(); if (code == 850) throw new RpgError(); return nil; }
        if (code == 851) { fixationComplete.nextGoal = 'Changed receipt'; fixationComplete.assess(); return nil; }
        if (code == 858) { fearEventInput.initialRoll = 13; return nil; }
        if (code == 853)
        { fearProfile.traits = [fixationTrait]; fearProfile.earnedPoints = 9; fearProfile.unspentPoints = 7;
          fixationBasis.originalBonus = 10; return nil; }
        if (code == 854) { fearProfile.earnedPoints = 15; fearProfile.unspentPoints = 15; return nil; }
        if (code == 855)
        { local value = fixationSecondComplete.assess(); event('test.fixation-buyoff'); eventValue(value.status); eventValue(value.reason); return nil; }
        if (code == 852)
        {
            event('test.fixation-costs');
            foreach (local term in ['short-term','long-term'])
                foreach (local rating in [6,9,12,15])
                {
                    local trait = new RpgExpandedGoalFixation(); trait.approved = true; trait.term = term;
                    trait.points = term == 'short-term' ? -5 : -10; trait.initialGoal = 'An authored goal'; trait.selfControlRating = rating;
                    eventValue(trait.creationCost());
                }
            return nil;
        }
        return inherited(context);
    }
;
