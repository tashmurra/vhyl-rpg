#include "expanded-bleeding.t"
#include <vhyl-rpg-expanded-traits.t>
aidTrait: RpgExpandedCompelledAid approved = true;
modify bleedProfile traits = [aidTrait];
aidOccurrence: object;
aidTrigger: RpgExpandedAidTrigger
    id = 'aid-opportunity' profile = bleedProfile trait = aidTrait trigger = aidOccurrence
    recipient = bleedHealer assistance = 'Offer to carry the healer’s empty case'
    aidAvailable = true shouldResist = true approved = true
    evidence = 'The case is accessible, but the actor has orders to leave'
;
aidDecision: RpgExpandedAidDecision source = aidTrigger choice = 'decline';
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 4300 || code == 4301 || code == 4302)
        {
            local value = code == 4300 ? aidTrigger.assess() : aidTrigger.resolve();
            event('test.aid-trigger'); eventValue(value.status); eventValue(value.reason); eventValue(aidTrait.creationCost());
            if (code == 4302) throw new RpgError(); return nil;
        }
        if (code == 4303)
        { local value = aidDecision.apply(); event('test.aid-choice'); eventValue(value.status); eventValue(value.reason); return nil; }
        if (code == 4304) { aidDecision.choice = 'offer'; return nil; }
        if (code == 4305) { aidTrigger.giveIn = true; return nil; }
        if (code == 4306) { aidTrigger.aidAvailable = nil; return nil; }
        if (code == 4307) { aidTrait.selfControlRating = 6; return nil; }
        if (code == 4308)
        {
            event('test.aid-state'); eventValue(aidTrigger.active ? 1 : 0); eventValue(bleedProfile.selfControlTriggers.length());
            eventValue(aidTrigger.decision == aidDecision ? 1 : 0); eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
        }
        return inherited(context);
    }
;
