/* Original persistence and boundary fixtures for the optional modules. */
#define RPG_GATE_CUSTOM_ACT 1
#include "../../examples/resilience/main.t"

unusedSkill: RpgSkill attribute = rpgIQ defaultPenalty = -5;
unusedTraining: RpgTraining skill = unusedSkill points = 0;
modify gateHero skills = [gateAidTraining, gateBrawlTraining, gateTalkTraining, unusedTraining];
testBank: RpgMilestone id = 'test.bank' points = 60;
testBankReceipt: RpgAward profile = gateHero milestone = testBank;
testThrowAward: RpgMilestone id = 'test.throw-award' points = 3
    apply(profile) { gateUnlock(); throw new RpgError(); }
;
testThrowReceipt: RpgAward profile = gateHero milestone = testThrowAward;
testIQOffer: RpgDevelopment id = 'test.iq' profile = gateHero
    kind = 'attribute' attribute = rpgIQ target = 12 unlocked = true;
testHTOffer: RpgDevelopment id = 'test.ht' profile = gateHero
    kind = 'attribute' attribute = rpgHT target = 11 unlocked = true;
testSTOffer: RpgDevelopment id = 'test.st' profile = gateHero
    kind = 'attribute' attribute = rpgST target = 11 unlocked = true;
testNewOffer: RpgDevelopment id = 'test.new-skill' profile = gateHero
    training = unusedTraining target = 2 unlocked = true;
testThrowOffer: RpgDevelopment id = 'test.throw-purchase' profile = gateHero
    training = gateAidTraining target = 8 unlocked = true
    apply(profile) { gateState.permit = true; throw new RpgError(); }
;
testNpcReceipt: RpgAward profile = gateGuardProfile milestone = testBank;

class ResilienceTestAction: Action
    code = 0
    exec(c)
    {
        local value = nil;
        if (self.code == 500) value = rpgWound(gateHero, 2, 0, 1, 1);
        else if (self.code == 501) value = rpgWound(gateHero, 6, 0, 1, 1);
        else if (self.code == 502) value = rpgWound(gateHero, 20, 0, 1, 1);
        else if (self.code == 503)
        { rpgWound(gateHero, 1, 0, 1, 1); value = rpgWound(gateHero, 2, 0, 1, 1); }
        else if (self.code == 504) gateHero.energy = 0;
        else if (self.code == 505) gateHeroBody.stunned = true;
        else if (self.code == 506)
        {
            rpgPublishProgress(rpgAwardMilestone(gateHero, testBank)); gateUnlock();
            gateHero.developmentOpen = true;
        }
        else if (self.code == 507) rpgAwardMilestone(gateHero, testThrowAward);
        else if (self.code == 508) rpgDevelop(testThrowOffer);
        else if (self.code == 509) rpgPublishProgress(rpgDevelop(testIQOffer));
        else if (self.code == 510) rpgPublishProgress(rpgDevelop(testHTOffer));
        else if (self.code == 511) rpgPublishProgress(rpgDevelop(testSTOffer));
        else if (self.code == 512) rpgPublishProgress(rpgDevelop(testNewOffer));
        else if (self.code == 513) gateHero.developmentOpen = nil;
        else if (self.code == 514) gateHero.will = 100;
        else if (self.code == 515) gateState.refuses = true;
        else if (self.code == 516) gateConflict.discloseRolls = true;
        else if (self.code == 517)
        { gateHeroBody.lethal = true; value = rpgWound(gateHero, 100, 0, 1, 1); }
        else if (self.code == 518)
        { value = rpgRest(gateHero, 599); }
        else if (self.code == 519)
        { value = rpgRest(gateHero, 1); }
        else if (self.code == 520)
        { gateHeroBody.endAction(); }
        else if (self.code == 521)
        { value = rpgRecoverStun(gateHero); }
        else if (self.code == 522)
        { rpgPublishProgress(rpgAwardMilestone(gateGuardProfile, testBank)); }
        else if (self.code == 523)
        {
            gateGuardProfile.skills = [gateAidTraining]; rpgProgressionValidation.execute();
        }
        else if (self.code == 524)
        { gateHeroBody.profile = gateGuardProfile; rpgResilienceValidation.execute(); }
        else if (self.code == 525)
        { gateConflict.opposition = gateHeroFighter; rpgConflictValidation.execute(); }
        else if (self.code == 526)
        { gateTreatment.charges = -1; rpgResilienceValidation.execute(); }
        else if (self.code == 527)
        { gateHero.energy = 10; gateHeroBody.injury = 0; gateHeroBody.aidRemaining = 0; }
        else if (self.code == 528)
        { gateGuardFighter.armor = 100; gateHeroFighter.armor = 100; gateConflict.maxExchanges = 2; }
        else if (self.code == 529)
        { gateGuardProfile.will = 18; }
        else if (self.code == 530) gateTreatment.modifier = -12;
        else if (self.code == 531) rpgRandom.seed(4);
        else if (self.code == 532) value = rpgWound(gateGuardProfile, 100, 0, 1, 1);
        if (value != nil)
        {
            event('test.care'); eventValue(value.status); eventValue(value.reason);
            eventValue(value.injury); eventValue(value.healed); eventValue(value.energyRestored);
            eventValue(value.seconds);
        }
        return nil;
    }
;
testAction500: ResilienceTestAction code = 500;
vTest500: Verb code = 500 action = testAction500 label = 'test-500';
testAction501: ResilienceTestAction code = 501;
vTest501: Verb code = 501 action = testAction501 label = 'test-501';
testAction502: ResilienceTestAction code = 502;
vTest502: Verb code = 502 action = testAction502 label = 'test-502';
testAction503: ResilienceTestAction code = 503;
vTest503: Verb code = 503 action = testAction503 label = 'test-503';
testAction504: ResilienceTestAction code = 504;
vTest504: Verb code = 504 action = testAction504 label = 'test-504';
testAction505: ResilienceTestAction code = 505;
vTest505: Verb code = 505 action = testAction505 label = 'test-505';
testAction506: ResilienceTestAction code = 506;
vTest506: Verb code = 506 action = testAction506 label = 'test-506';
testAction507: ResilienceTestAction code = 507;
vTest507: Verb code = 507 action = testAction507 label = 'test-507';
testAction508: ResilienceTestAction code = 508;
vTest508: Verb code = 508 action = testAction508 label = 'test-508';
testAction509: ResilienceTestAction code = 509;
vTest509: Verb code = 509 action = testAction509 label = 'test-509';
testAction510: ResilienceTestAction code = 510;
vTest510: Verb code = 510 action = testAction510 label = 'test-510';
testAction511: ResilienceTestAction code = 511;
vTest511: Verb code = 511 action = testAction511 label = 'test-511';
testAction512: ResilienceTestAction code = 512;
vTest512: Verb code = 512 action = testAction512 label = 'test-512';
testAction513: ResilienceTestAction code = 513;
vTest513: Verb code = 513 action = testAction513 label = 'test-513';
testAction514: ResilienceTestAction code = 514;
vTest514: Verb code = 514 action = testAction514 label = 'test-514';
testAction515: ResilienceTestAction code = 515;
vTest515: Verb code = 515 action = testAction515 label = 'test-515';
testAction516: ResilienceTestAction code = 516;
vTest516: Verb code = 516 action = testAction516 label = 'test-516';
testAction517: ResilienceTestAction code = 517;
vTest517: Verb code = 517 action = testAction517 label = 'test-517';
testAction518: ResilienceTestAction code = 518;
vTest518: Verb code = 518 action = testAction518 label = 'test-518';
testAction519: ResilienceTestAction code = 519;
vTest519: Verb code = 519 action = testAction519 label = 'test-519';
testAction520: ResilienceTestAction code = 520;
vTest520: Verb code = 520 action = testAction520 label = 'test-520';
testAction521: ResilienceTestAction code = 521;
vTest521: Verb code = 521 action = testAction521 label = 'test-521';
testAction522: ResilienceTestAction code = 522;
vTest522: Verb code = 522 action = testAction522 label = 'test-522';
testAction523: ResilienceTestAction code = 523;
vTest523: Verb code = 523 action = testAction523 label = 'test-523';
testAction524: ResilienceTestAction code = 524;
vTest524: Verb code = 524 action = testAction524 label = 'test-524';
testAction525: ResilienceTestAction code = 525;
vTest525: Verb code = 525 action = testAction525 label = 'test-525';
testAction526: ResilienceTestAction code = 526;
vTest526: Verb code = 526 action = testAction526 label = 'test-526';
testAction527: ResilienceTestAction code = 527;
vTest527: Verb code = 527 action = testAction527 label = 'test-527';
testAction528: ResilienceTestAction code = 528;
vTest528: Verb code = 528 action = testAction528 label = 'test-528';
testAction529: ResilienceTestAction code = 529;
vTest529: Verb code = 529 action = testAction529 label = 'test-529';

testAction530: ResilienceTestAction code = 530;
vTest530: Verb code = 530 action = testAction530 label = 'test-530';

testAction531: ResilienceTestAction code = 531;
vTest531: Verb code = 531 action = testAction531 label = 'test-531';

testAction532: ResilienceTestAction code = 532;
vTest532: Verb code = 532 action = testAction532 label = 'test-532';

act(verb, args)
{
    if (verb == 950)
    {
        event('test.resilience');
        eventValue(turnCount.value);
        eventValue(undoDepth());
        eventValue(rpgRandom.state);
        eventValue(rpgRandom.draws);
        eventValue(rpgLedger.seconds);
        eventValue(gateHeroBody.injury);
        eventValue(gateHeroBody.hp());
        eventValue(gateHeroBody.shock);
        eventValue(gateHeroBody.stunned);
        eventValue(gateHeroBody.unconscious);
        eventValue(gateHeroBody.dead);
        eventValue(gateHeroBody.aidRemaining);
        eventValue(gateHeroBody.restSeconds);
        eventValue(gateHeroBody.healingSeconds);
        eventValue(gateHero.energy);
        eventValue(gateTreatment.charges);
        eventValue(gateHero.earnedPoints);
        eventValue(gateHero.unspentPoints);
        eventValue(gateHero.developmentRevision);
        eventValue(gateAidTraining.points);
        eventValue(gateBrawlTraining.points);
        eventValue(gateHero.will);
        eventValue(gateHero.iq);
        eventValue(gateHero.ht);
        eventValue(gateHero.maxEnergy);
        eventValue(gateState.passage);
        eventValue(gateState.permit);
        eventValue(gatePassage.revision);
        eventValue(gateParleySlot.revision);
        eventValue(gateConflict.active);
        eventValue(gateConflict.finished);
        eventValue(gateConflict.outcome);
        eventValue(gateConflict.exchanges);
        eventValue(gateGuardBody.injury);
        eventValue(gateGuardBody.stunned);
        eventValue(gateGuardBody.unconscious);
        eventValue(gateMood.attitude);
        eventValue(gateStudyAid.purchased);
        eventValue(gateLearnPoise.purchased);
        eventValue(gateOvercomeNerves.purchased);
        eventValue(testBankReceipt.claimed);
        eventValue(testThrowReceipt.claimed);
        eventValue(unusedTraining.points);
        eventValue(gateHero.skillScore(unusedSkill));
        eventValue(gateHero.st);
        eventValue(gateHero.maxHP);
        eventValue(gateGuardProfile.unspentPoints);
        eventValue(gateHero.perception);
        eventValue(testThrowOffer.purchased);
        eventValue(gateHero.developmentOpen);
        return nil;
    }
    if (verb == 951)
    {
        event('test.injury'); eventValue(rpgInjuryFor(args[1], args[2], args[3], args[4])); return nil;
    }
    if (verb == 952)
    {
        local method = new RpgApproach(); method.attribute = rpgST;
        local value = rpgCalculate(rpgContext(gateHero, method, nil));
        event('test.strength'); eventValue(value.baseScore); eventValue(value.effectiveScore);
        foreach (local modifier in value.modifiers) eventValue(modifier);
        return nil;
    }
    if (verb == 954)
    {
        local value = rpgRecordedResult(gateHero, gateParley);
        if (value != nil) rpgPublishRoll(value, nil);
        return nil;
    }
    return gateAct(verb, args);
}
