#include "expanded-phantom-voices.t"
#include <vhyl-rpg-expanded-characters.t>
beliefOne: RpgExpandedFixedBelief level = 2 scope = 'doors' approved = true
    beliefText = 'Every unopened doorway conceals an observer' behaviorText = 'Address the unseen observer before opening a door';
beliefTwo: RpgExpandedFixedBelief level = 3 scope = 'mirrors' approved = true
    beliefText = 'Reflections exchange messages about the expedition' behaviorText = 'Cover reflective surfaces before making plans';
beliefThree: RpgExpandedFixedBelief level = 3 scope = 'bells' approved = true
    beliefText = 'Bells reveal hidden instructions' behaviorText = 'Record each bell before continuing';
beliefFour: RpgExpandedFixedBelief level = 1 scope = 'lamps' approved = true
    beliefText = 'Lamps remember conversations' behaviorText = 'Turn lamps away before speaking';
beliefAward: RpgExpandedFixedBeliefAcquisition id = 'door-belief' eventId = 'door-fright' profile = bleedProfile trait = beliefOne
    approved = true evidence = 'The authored fright outcome selected row twenty-two';
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 11200)
        {
            bleedProfile.traits = []; bleedProfile.creationComplete = true; bleedProfile.disadvantageLimit = 0;
            bleedProfile.earnedPoints = 9; bleedProfile.unspentPoints = 7; return nil;
        }
        if (code == 11201) { event('test.belief-preview'); eventValue(beliefAward.assess().points); eventValue(rpgRandom.draws); return nil; }
        if (code == 11202 || code == 11203)
        {
            beliefAward.apply(); if (code == 11203) throw new RpgError(); return nil;
        }
        if (code == 11204)
        {
            event('test.belief-state'); eventValue(bleedProfile.traits.length()); eventValue(bleedProfile.earnedPoints);
            eventValue(bleedProfile.unspentPoints); eventValue(bleedProfile.developmentRevision);
            eventValue(bleedProfile.postCreationDisadvantageAllowance()); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 11205) { rpgExpandedValidateCharacter(bleedProfile); return nil; }
        if (code == 11206) { bleedProfile.traits = [beliefOne,beliefTwo,beliefThree]; return nil; }
        if (code == 11207) { bleedProfile.traits = bleedProfile.traits + [beliefFour]; return nil; }
        if (code == 11208)
        {
            event('test.belief-limit');
            try { bleedProfile.validateFixedBeliefs(nil); rpgLiteValidateTraits(bleedProfile); eventValue('accepted'); }
            catch (RpgExpandedError error) { eventValue(error.reason); } return nil;
        }
        if (code == 11209) { beliefTwo.scope = beliefOne.scope; return nil; }
        if (code == 11210) { beliefAward.tableTotal = 34; beliefAward.trait = beliefTwo; return nil; }
        return inherited(context);
    }
;
