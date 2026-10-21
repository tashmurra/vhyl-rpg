#include "expanded-indecision.t"
decisionConfusionTrait: RpgExpandedOverstimulation approved = true;
decisionConfusionToken: object;
decisionConfusion: RpgExpandedDecisionConfusion id = 'junction-confusion' profile = fearProfile trait = decisionConfusionTrait
    decisionEpisode = indecisionEpisode trigger = decisionConfusionToken approved = true
    evidence = 'The decision is followed by a separate confusion check' stressRelation = 'unrelated';
decisionConfusionInput: object succeed = nil;
modify rpgRandom
    roll()
    { self.draws += 3; indecisionInput.rolls += 1;
      return indecisionInput.rolls == 1 ? 11 : indecisionInput.rolls == 2 || decisionConfusionInput.succeed ? 3 : 13; }
;
modify FearTestAction
    exec(context)
    {
        local code = fearInput.code;
        if (code == 1140)
        { fearProfile.traits = [indecisionTrait,decisionConfusionTrait]; indecisionEpisode.confusion = decisionConfusion; return nil; }
        if (code == 1141) { decisionConfusion.resolve(); return nil; }
        if (code == 1142) { decisionConfusionInput.succeed = true; return nil; }
        if (code == 1143)
        {
            event('test.decision-confusion'); eventValue(indecisionEpisode.attempts.length());
            eventValue(fearProfile.selfControlTriggers.length()); eventValue(decisionConfusion.result != nil ? 1 : 0);
            eventValue(fearProfile.activeOverstimulation() != nil ? 1 : 0); eventValue(rpgRandom.draws);
            eventValue(rpgLedger.seconds); eventValue(fearProfile.healthManeuverReasonFor('move',nil)); return nil;
        }
        if (code == 1144) { decisionConfusion.end('quiet-familiar-place','The actor reaches a quiet familiar shelter'); return nil; }
        if (code == 1145) { indecisionEpisode.confusion = nil; return nil; }
        if (code == 1146) { indecisionRetry.boundConfusion = nil; indecisionRetry.assess(); return nil; }
        return inherited(context);
    }
;
