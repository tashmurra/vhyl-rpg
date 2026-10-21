#include "expanded-fear-event.t"
#include <vhyl-rpg-expanded-characters.t>
#include <vhyl-rpg-expanded-traits.t>
eventQuirk: RpgExpandedMentalQuirk approved = true triggerText = 'An unfamiliar doorway'
    responseText = 'Check the far side with a light before entering';
eventQuirkAward: RpgExpandedFearQuirkAcquisition id = 'event-quirk' eventId = 'apparition' profile = fearProfile
    quirk = eventQuirk approved = true relationEvidence = 'The apparition appeared in an unlit doorway';
eventBelief: RpgExpandedFixedBelief level = 2 scope = 'echoes' approved = true
    beliefText = 'Echoes carry messages from the apparition' behaviorText = 'Pause to write down echoes before proceeding';
eventBeliefAward: RpgExpandedFixedBeliefAcquisition id = 'event-belief' eventId = 'apparition' profile = fearProfile
    trait = eventBelief approved = true evidence = 'The selected event changes the character interpretation of echoes';
modify FearTestAction
    exec(context)
    {
        local code = fearInput.code;
        if (code == 320 || code == 321)
        {
            fearProfile.creationComplete = true; fearProfile.disadvantageLimit = 0;
            fearProfile.earnedPoints = 9; fearProfile.unspentPoints = 7;
            fearEventInput.initialRoll = code == 320 ? 11 : 18;
            fearEventInput.tableRoll = code == 320 ? 12 : 14; return nil;
        }
        if (code == 322 || code == 323)
        {
            local request = ownedFearEvent.result.row == 13 ? eventQuirkAward : eventBeliefAward;
            ownedFearEvent.applyConsequence(request); if (code == 323) throw new RpgError(); return nil;
        }
        if (code == 324)
        {
            event('test.fear-event-traits'); eventValue(fearProfile.traits.length()); eventValue(fearProfile.earnedPoints);
            eventValue(fearProfile.unspentPoints); eventValue(fearProfile.developmentRevision);
            eventValue(fearProfile.postCreationDisadvantageAllowance()); eventValue(rpgRandom.draws); return nil;
        }
        return inherited(context);
    }
;
