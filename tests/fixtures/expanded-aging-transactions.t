#include <vhyl.h>
#include <vhyl.t>
#include <vhyl-en.t>
#include <vhyl-actions.t>
#include <vhyl-rpg.t>
#include <vhyl-rpg-progression.t>
#include <vhyl-rpg-lite.t>
#include <vhyl-rpg-expanded.t>
#include <vhyl-rpg-expanded-characters.t>
#include <vhyl-rpg-expanded-skills.t>
#include <vhyl-rpg-expanded-health.t>
#include <vhyl-rpg-expanded-hazards.t>
agingRoom: Room 'Observatory';
agingRules: RpgExpandedRules;
agingPatient: RpgExpandedProfile rules = agingRules unspentPoints = 7 earnedPoints = 7;
agingEvent: RpgExpandedAgingEvent profile = agingPatient calendarId = 'civil-calendar'
    boundaryId = 'anniversary-one' ageYears = 50 ordinal = 1 reached = true
    evidence = 'First aging anniversary reached' medicalTL = 3;
agingPurchase: RpgDevelopment id = 'later-dexterity' profile = agingPatient kind = 'attribute'
    attribute = rpgDX target = 10 unlocked = true requiresDowntime = nil;
youthRequest: RpgExpandedRejuvenation id = 'first-youth' profile = agingPatient calendarId = 'civil-calendar'
    oldAgeYears = 51 newAgeYears = 49 effectEvidence = 'Completed youth restoration';
laterAging: RpgExpandedAgingEvent profile = agingPatient calendarId = 'civil-calendar'
    boundaryId = 'anniversary-two' ageYears = 50 ordinal = 2 reached = true
    evidence = 'Aging anniversary after restored youth' medicalTL = 3;
laterYouth: RpgExpandedRejuvenation id = 'second-youth' profile = agingPatient calendarId = 'civil-calendar'
    oldAgeYears = 51 newAgeYears = 49 effectEvidence = 'Second completed restoration';
agingInput: object code = 0;
class AgingFixtureAction: Action
    exec(context)
    {
        local code = agingInput.code;
        if (code == 0) { agingPatient.st = 1; agingPatient.ht = 3; return nil; }
        if (code == 7)
        {
            agingPatient.unspentPoints = 20; agingPatient.earnedPoints = 20;
            rpgDevelop(agingPurchase); return nil;
        }
        if (code == 8 || code == 9 || code == 10 || code == 12 || code == 13)
        {
            if (code == 10) youthRequest.effectEvidence = 'Changed evidence';
            local youth = code == 12 ? laterYouth : youthRequest;
            if (code == 13)
            {
                youth = new RpgExpandedRejuvenation(); youth.id = youthRequest.id; youth.profile = agingPatient;
                youth.calendarId = 'civil-calendar'; youth.oldAgeYears = 51; youth.newAgeYears = 49;
                youth.effectEvidence = 'Duplicate request';
            }
            local result = youth.apply(); event('test.youth-operation'); eventValue(result.status); eventValue(result.pointGain);
            if (code == 9) throw new RpgError(); return nil;
        }
        if (code == 11)
        {
            if (laterAging.result == nil) rpgRandom.seed(1);
            laterAging.apply(); return nil;
        }
        if (code == 4) agingEvent.ageYears = 51;
        if (code == 6) { agingPatient.validateFeatures(); return nil; }
        local request = agingEvent;
        if (code == 3)
        {
            request = new RpgExpandedAgingEvent(); request.profile = agingPatient;
            request.calendarId = agingEvent.calendarId; request.boundaryId = agingEvent.boundaryId;
            request.ordinal = 2; request.ageYears = 51; request.reached = true; request.evidence = 'Duplicate boundary';
        }
        local value = code == 5 ? request.assess() : request.apply();
        event('test.aging-operation'); eventValue(value.status); eventValue(value.reason);
        if (code == 2) throw new RpgError();
        return nil;
    }
;
agingAction: AgingFixtureAction;
agingVerb: Verb code = 1820 action = agingAction label = 'aging-fixture';
modify gameMain initialRoom = agingRoom;
startup() { rpgRandom.seed(1); return vhylStart(); }
turn(tokens) { return vhylTurn(tokens); }
act(verb,args)
{
    if (verb == 1820) { agingInput.code = args[1]; return vhylAct(verb,args); }
    if (verb == 1821)
    {
        event('test.aging-state'); eventValue(agingPatient.st); eventValue(agingPatient.dx);
        eventValue(agingPatient.iq); eventValue(agingPatient.ht); eventValue(agingPatient.dead ? 1 : 0);
        eventValue(agingPatient.agingHistory.length()); eventValue(rpgExpandedCharacterCost(agingPatient,nil));
        eventValue(agingPatient.unspentPoints); eventValue(agingPatient.earnedPoints);
        eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); eventValue(agingEvent.ageYears);
        return nil;
    }
    if (verb == 1822)
    {
        event('test.youth-state'); eventValue(agingPatient.dx); eventValue(rpgExpandedCharacterCost(agingPatient,nil));
        eventValue(agingPatient.unspentPoints); eventValue(agingPatient.earnedPoints); eventValue(agingPatient.rejuvenations.length());
        eventValue(agingEvent.restoredBy == youthRequest ? 1 : 0); eventValue(laterAging.restoredBy == laterYouth ? 1 : 0);
        eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
    }
    return vhylAct(verb,args);
}
