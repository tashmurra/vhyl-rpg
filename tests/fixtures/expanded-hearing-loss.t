#include "expanded-communication-study.t"
hearingLoss: RpgExpandedHearingLoss approved = true;
modify gestureRecipient traits = [hearingLoss] skills = [hearingTraining] developmentOpen = true;
hearingTraining: RpgTraining skill = learningSkill points = 1;
hearingStudy: RpgExpandedStudy profile = gestureRecipient training = hearingTraining permitted = true;
hearingCredit: RpgExpandedCommunicationStudy id = 'recipient-gesture-study' source = gestureExchange study = hearingStudy
    approved = true evidence = 'The recipient practices the skill used to understand the visual exchange';
hearingDuplicate: RpgExpandedCommunicationStudy id = 'duplicate-recipient-study' source = gestureExchange study = hearingStudy
    approved = true evidence = 'A duplicate must not grant credit for the same participant and interval';
hearingContext: RpgLiteContext attribute = rpgPerception kind = 'hearing';
hearingSpeechContext: RpgLiteContext attribute = rpgIQ understandsSpeech = true;
hearingWritingContext: RpgLiteContext attribute = rpgIQ understandsSpeech = true written = true;
hearingSign: RpgLiteLanguage id = 'courtyard-sign' spoken = 3 written = 0;
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 4050)
        {
            local check = rpgLiteCheck(gestureRecipient,hearingContext);
            event('test.hearing-loss'); eventValue(hearingLoss.creationCost()); eventValue(check.reason);
            eventValue(rpgLiteScore(gestureRecipient,hearingSpeechContext)); eventValue(rpgLiteScore(gestureRecipient,hearingWritingContext));
            eventValue(rpgRandom.draws); return nil;
        }
        if (code == 4051 || code == 4052 || code == 4061)
        { local value = code == 4061 ? hearingDuplicate.apply() : hearingCredit.apply();
          event('test.hearing-credit'); eventValue(value.status); eventValue(value.reason);
          if (code == 4052) throw new RpgError(); return nil; }
        if (code == 4053)
        {
            event('test.hearing-credit-state'); eventValue(learningStudy.credit); eventValue(hearingStudy.credit);
            eventValue(learningTraining.points); eventValue(hearingTraining.points);
            eventValue(gestureExchange.creditedStudies.length()); eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 4054) { learningStudy.credit = 2879960; hearingStudy.credit = 2879960; return nil; }
        if (code == 4055) { gestureExchange.result.recipientStudyEligible = nil; gestureExchange.assess(); return nil; }
        if (code == 4056) { hearingLoss.mitigated = true; return nil; }
        if (code == 4057)
        {
            hearingStudy.mode = 'education'; hearingStudy.teacher = bleedProfile; hearingStudy.teachingScore = 12;
            local value = hearingStudy.assess(1); event('test.hearing-study'); eventValue(value.status); eventValue(value.reason); return nil;
        }
        if (code == 4058) { hearingStudy.communicationMode = 'visual'; hearingStudy.communicationEvidence = 'The complete lesson is demonstrated visibly'; return nil; }
        if (code == 4059) { hearingStudy.communicationMode = 'signed'; hearingStudy.communicationLanguage = 'courtyard-sign';
            hearingStudy.communicationEvidence = 'Both participants use the declared sign language'; return nil; }
        if (code == 4060) { bleedProfile.languages = [hearingSign]; gestureRecipient.languages = [hearingSign]; return nil; }
        if (code == 4062) { gestureExchange.creditedStudy = nil; gestureExchange.studyCredit(gestureRecipient); return nil; }
        return inherited(context);
    }
;
