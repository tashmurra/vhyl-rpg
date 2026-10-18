#include "expanded-truthfulness.t"
#include <vhyl-rpg-expanded-social.t>
statementListener: RpgExpandedProfile rules = bleedRules knowledge = statementKnowledge;
statementKnowledge: RpgExpandedKnowledge owner = statementListener;
statementDelivery: RpgExpandedStatementDelivery id = 'heard-answer' recipient = statementListener
    heard = true evidence = 'The listener heard and understood this authored utterance';
statementDuplicate: RpgExpandedStatementDelivery id = 'same-answer' recipient = statementListener
    heard = true evidence = 'Same utterance and listener';
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 660) { statementDelivery.communication = truthTrigger.communication; return nil; }
        if (code == 661)
        {
            local value = statementDelivery.assess(); event('test.statement-preview');
            eventValue(value.status); eventValue(value.reason); eventValue(value.statements.length()); return nil;
        }
        if (code == 662 || code == 663)
        { statementDelivery.deliver(); if (code == 663) throw new RpgError(); return nil; }
        if (code == 664)
        {
            event('test.statement-state'); eventValue(statementKnowledge.received.length());
            eventValue(statementKnowledge.beliefs.length()); eventValue(statementKnowledge.fabrications.length());
            eventValue(statementKnowledge.received.length() == 0 ? nil : statementKnowledge.received[1][3][1]);
            eventValue(truthTrigger.communication == nil ? 0 : truthTrigger.communication.deliveries.length());
            eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 665) { statementDelivery.heard = nil; return nil; }
        if (code == 666) { statementDelivery.id = 'changed-id'; return nil; }
        if (code == 667)
        { statementDuplicate.communication = truthTrigger.communication; statementDuplicate.deliver(); return nil; }
        if (code == 668) { truthTrigger.communication.statement = 'altered-answer'; return nil; }
        return inherited(context);
    }
;
