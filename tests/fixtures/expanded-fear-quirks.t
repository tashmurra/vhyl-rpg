#include <vhyl.h>
#include <vhyl.t>
#include <vhyl-en.t>
#include <vhyl-actions.t>
#include <vhyl-rpg.t>
#include <vhyl-rpg-progression.t>
#include <vhyl-rpg-lite.t>
#include <vhyl-rpg-expanded.t>
#include <vhyl-rpg-expanded-characters.t>
#include <vhyl-rpg-expanded-traits.t>
quirkRoom: Room 'Threshold';
quirkRules: RpgExpandedRules;
quirkOne: RpgLiteTrait id = 'quirk';
quirkTwo: RpgLiteTrait id = 'quirk';
quirkThree: RpgLiteTrait id = 'quirk';
quirkFour: RpgLiteTrait id = 'quirk';
quirkFive: RpgLiteTrait id = 'quirk';
quirkProfile: RpgExpandedProfile rules = quirkRules creationComplete = true pointBudget = 0 disadvantageLimit = 5
    earnedPoints = 10 unspentPoints = 7 traits = [quirkOne,quirkTwo,quirkThree,quirkFour,quirkFive];
fearQuirk: RpgExpandedMentalQuirk approved = true triggerText = 'Entering an unlit room' responseText = 'Ask a companion to inspect the doorway first';
quirkAcquisition: RpgExpandedFearQuirkAcquisition id = 'threshold-fear' eventId = 'apparition' profile = quirkProfile quirk = fearQuirk
    approved = true relationEvidence = 'The apparition emerged from an unlit doorway';
quirkPortrayal: RpgExpandedQuirkPortrayal id = 'next-room' profile = quirkProfile quirk = fearQuirk triggerPresent = true
    decision = 'followed' approved = true observedBehavior = 'Asked the guide to inspect the threshold';
quirkInput: object code = 0;
class QuirkTestAction: Action
    exec(context)
    {
        local code = quirkInput.code;
        if (code == 3) { rpgExpandedValidateCharacter(quirkProfile); event('test.quirk-valid'); eventValue(quirkProfile.traits.length()); return nil; }
        if (code == 7) { quirkPortrayal.decision = 'inapplicable'; return nil; }
        if (code == 8) { quirkAcquisition.approved = nil; return nil; }
        if (code == 9) { quirkProfile.creationComplete = nil; return nil; }
        if (code == 10) { quirkProfile.traits = [quirkOne,quirkTwo,quirkThree,quirkFour,quirkFive]; return nil; }
        if (code == 11) { quirkProfile.traits = quirkProfile.traits + [fearQuirk]; return nil; }
        if (code == 12) { fearQuirk.responseText = ''; return nil; }
        if (code <= 2)
        {
            local value = code == 1 ? quirkAcquisition.assess() : quirkAcquisition.apply();
            event('test.quirk-acquisition'); eventValue(value.status); eventValue(value.reason); eventValue(value.points);
            if (code == 2) throw new RpgError(); return nil;
        }
        local value = code == 5 ? quirkPortrayal.assess() : quirkPortrayal.apply();
        event('test.quirk-portrayal'); eventValue(value.status); eventValue(value.reason);
        if (code == 6) throw new RpgError(); return nil;
    }
;
quirkAction: QuirkTestAction;
quirkVerb: Verb code = 2264 action = quirkAction label = 'quirk consequence';
modify gameMain initialRoom = quirkRoom;
startup() { rpgRandom.seed(1); return vhylStart(); }
turn(tokens) { return vhylTurn(tokens); }
act(verb,args)
{
    if (verb == 2264) { quirkInput.code = args[1]; return vhylAct(verb,args); }
    if (verb == 2265)
    {
        event('test.quirk-state'); eventValue(rpgExpandedCharacterCost(quirkProfile,nil));
        eventValue(quirkProfile.traits.length()); eventValue(quirkProfile.earnedPoints); eventValue(quirkProfile.unspentPoints);
        eventValue(quirkProfile.developmentRevision); eventValue(quirkProfile.fearQuirkAcquisitions.length());
        eventValue(quirkProfile.quirkPortrayals.length()); eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
    }
    return nil;
}
