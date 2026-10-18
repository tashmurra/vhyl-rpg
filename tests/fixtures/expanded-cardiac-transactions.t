#include <vhyl.h>
#include <vhyl.t>
#include <vhyl-en.t>
#include <vhyl-actions.t>
#include <vhyl-rpg.t>
#include <vhyl-rpg-progression.t>
#include <vhyl-rpg-lite.t>
#include <vhyl-rpg-expanded.t>
#include <vhyl-rpg-expanded-health.t>
cardiacRoom: Room 'Treatment Room';
cardiacRules: RpgExpandedRules;
cardiacPatient: RpgExpandedProfile rules = cardiacRules fatigue = 3 injury = 2;
cardiacHealer: RpgLiteProfile iq = 14 techLevel = 7 skills = [cardiacTraining];
cardiacSkill: RpgLiteSkill id = 'physician' attribute = rpgIQ difficulty = 2 techLevel = 7;
cardiacTraining: RpgTraining skill = cardiacSkill points = 1;
cardiacCase: RpgExpandedCardiacArrest id = 'arrest' profile = cardiacPatient evidence = 'Confirmed triggering condition';
cardiacSuccess: RpgExpandedCardiacResuscitation id = 'successful-attempt' arrest = cardiacCase
    healer = cardiacHealer skill = cardiacSkill careEvidence = 'Uninterrupted suitable care';
cardiacFailure: RpgExpandedCardiacResuscitation id = 'failed-attempt' arrest = cardiacCase
    healer = cardiacHealer skill = cardiacSkill careEvidence = 'Uninterrupted suitable care';
cardiacInput: object code = 0;
class CardiacFixtureAction: Action
    exec(context)
    {
        local code = cardiacInput.code; local value = nil;
        if (code == 0 || code == 1) value = cardiacCase.start();
        else if (code == 2 || code == 3)
        {
            if (cardiacSuccess.result == nil) rpgRandom.seed(1);
            value = cardiacSuccess.apply();
        }
        else if (code == 4 || code == 5)
        {
            if (cardiacFailure.result == nil) rpgRandom.seed(5);
            value = cardiacFailure.apply();
        }
        else if (code == 6 || code == 7) value = cardiacCase.expire();
        else if (code == 8) { if (rpgLedger.seconds < 200) rpgSpendTime(200 - rpgLedger.seconds); return nil; }
        else if (code == 9) { cardiacPatient.validateFeatures(); return nil; }
        else if (code == 10) { cardiacSuccess.careEvidence = 'Changed care'; value = cardiacSuccess.assess(); }
        else if (code == 11) value = cardiacSuccess.assess();
        else if (code == 12) { rpgLiteRest(cardiacPatient,600,true,true,nil,true); return nil; }
        event('test.cardiac-operation'); eventValue(value.status); eventValue(value.reason);
        if (code == 1 || code == 3 || code == 5 || code == 7) throw new RpgError();
        return nil;
    }
;
cardiacAction: CardiacFixtureAction;
cardiacVerb: Verb code = 1930 action = cardiacAction label = 'cardiac-fixture';
modify gameMain initialRoom = cardiacRoom;
startup() { rpgRandom.seed(1); return vhylStart(); }
turn(tokens) { return vhylTurn(tokens); }
act(verb,args)
{
    if (verb == 1930) { cardiacInput.code = args[1]; return vhylAct(verb,args); }
    if (verb == 1931)
    {
        event('test.cardiac-state'); eventValue(cardiacPatient.fatigue); eventValue(cardiacPatient.injury);
        eventValue(cardiacPatient.cardiacArrest == nil ? 0 : 1); eventValue(cardiacCase.attempts.length());
        eventValue(cardiacCase.revivedBy == nil ? 0 : 1); eventValue(cardiacPatient.dead ? 1 : 0);
        eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); eventValue(cardiacCase.onset == nil ? 0 : 1);
        eventValue(cardiacPatient.unconscious ? 1 : 0); return nil;
    }
    return vhylAct(verb,args);
}
