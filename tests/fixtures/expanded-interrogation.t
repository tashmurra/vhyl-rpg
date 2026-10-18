#include "expanded-bleeding.t"
#include <vhyl-rpg-expanded-social.t>
questionSkill: RpgLiteSkill id = 'interrogation' attribute = rpgIQ difficulty = 1;
questionTraining: RpgTraining skill = questionSkill points = 2;
questionActor: RpgExpandedProfile rules = bleedRules skills = [questionTraining];
questionSession: RpgExpandedInterrogation id = 'questioning' interrogator = questionActor prisoner = bleedProfile skill = questionSkill;
questionRequest: RpgExpandedInterrogationQuestion id = 'first' session = questionSession question = 'first-question'
    truthfulAnswer = 'original-true-answer' falseAnswer = 'original-false-answer'
    approved = true evidence = 'The author establishes the question, known truth, possible lie and ordinary questioning conditions';
questionInput: object request = questionRequest rolls = [8,12] index = 1 nextId = 'next';
modify rpgRandom
    roll()
    {
        self.draws += 3; local value = questionInput.rolls[questionInput.index];
        questionInput.index = questionInput.index == 1 ? 2 : 1; return value;
    }
;
questionKnowledge: RpgExpandedKnowledge owner = questionActor;
modify questionActor knowledge = questionKnowledge;
questionDelivery: RpgExpandedInterrogationDelivery id = 'heard-answer' question = questionRequest recipient = questionActor;
questionOtherDelivery: RpgExpandedInterrogationDelivery id = 'same-answer-again' question = questionRequest recipient = questionActor;
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code; local request = questionInput.request;
        if (code == 520)
        { local value = request.assess(); event('test.interrogation-preview'); eventValue(value.status); eventValue(value.modifier); eventValue(value.statement); return nil; }
        if (code == 521 || code == 522)
        { request.apply(); if (code == 522) throw new RpgError(); return nil; }
        if (code == 523)
        {
            event('test.interrogation'); eventValue(questionSession.questions.length()); eventValue(questionSession.elapsed());
            eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws);
            eventValue(request.result == nil ? nil : request.result.responseKind);
            eventValue(request.result == nil ? nil : request.result.statement);
            eventValue(request.result == nil ? nil : request.result.modifier); return nil;
        }
        if (code == 524) { questionInput.rolls = [17,6]; return nil; }
        if (code == 525) { questionInput.rolls = [10,10]; return nil; }
        if (code == 526) { request.failureResponse = 'lie'; return nil; }
        if (code == 527) { request.means = 'severe-threat'; return nil; }
        if (code == 528) { request.means = 'torture'; return nil; }
        if (code == 529) { request.loyaltyResists = true; return nil; }
        if (code == 530 || code == 531)
        {
            local trait = new RpgLiteTrait(); trait.id = code == 530 ? 'low-empathy' : 'callous';
            questionActor.traits = questionActor.traits + [trait]; return nil;
        }
        if (code == 532)
        {
            local next = new RpgExpandedInterrogationQuestion(); next.id = questionInput.nextId;
            next.question = questionInput.nextId; questionInput.nextId += '-next'; next.session = questionSession;
            next.truthfulAnswer = 'original-true-answer'; next.falseAnswer = 'original-false-answer';
            next.approved = true; next.evidence = 'A separate authored question'; questionInput.request = next; return nil;
        }
        if (code == 533) { request.evidence = nil; return nil; }
        if (code == 540)
        { local value = questionDelivery.assess(); event('test.interrogation-delivery-preview'); eventValue(value.status); eventValue(value.statements.length()); return nil; }
        if (code == 541 || code == 542)
        { questionDelivery.deliver(); if (code == 542) throw new RpgError(); return nil; }
        if (code == 543)
        {
            event('test.interrogation-delivery'); eventValue(questionKnowledge.received.length());
            eventValue(questionKnowledge.beliefs.length()); eventValue(questionKnowledge.fabrications.length());
            eventValue(questionKnowledge.received.length() == 0 ? nil : questionKnowledge.received[1][3][1]);
            eventValue(questionRequest.delivery == questionDelivery ? 1 : 0);
            eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 544) { questionDelivery.id = 'changed'; return nil; }
        if (code == 545) { questionOtherDelivery.deliver(); return nil; }
        return inherited(context);
    }
;
