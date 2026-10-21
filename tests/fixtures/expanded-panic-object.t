#include "expanded-extreme-panic.t"
#include <vhyl-rpg-expanded-equipment.t>
#include <vhyl-rpg-expanded-technology.t>
panicObject: RpgLiteItem id = 'wooden-case' weight = 100 quantity = 1 ready = true artifactCondition = panicObjectCondition;
panicObjectCondition: RpgExpandedArtifactCondition item = panicObject capacity = 10 approved = true
    evidence = 'One ordinary non-fragile solid wooden case without machinery or subsystems';
panicObjectWound: RpgExpandedObjectWound id = 'case-impact' condition = panicObjectCondition amount = 60 approved = true
    evidence = 'The author has resolved the unopposed impact, protection and material effects to sixty injury';
panicObjectPermission: RpgExpandedPanicObjectPermission gate = panicObjectGate;
panicObjectGate: RpgExpandedPanicObjectGate id = 'panic-case-impact' profile = fearProfile
    panicReaction = extremeFirst permission = panicObjectPermission evidence = 'Physical effort to strike the case';
panicObjectParalysis: RpgExpandedParalysis id = 'case-paralysis' profile = fearProfile durationSeconds = 60
    positionAssessed = true balanced = true approved = true evidence = 'Conscious paralysis prevents the destructive action';
panicObjectOperation: RpgExpandedPanicObjectOperation permission = panicObjectPermission profile = fearProfile targetOwner = fearProfile wound = panicObjectWound
    approved = true evidence = 'The case is carried by the panicking actor; the authored destructive impact is reachable and unopposed';
modify fearProfile equipment = [panicObject];
modify extremeFirst kind = 'world-operation' operation = panicObjectOperation;
objectStress: RpgExpandedArtifactStress id = 'case-use' condition = panicObjectCondition approved = true
    evidence = 'The damaged case is used under load during this second';
objectStressNext: RpgExpandedArtifactStress id = 'case-use-next' condition = panicObjectCondition approved = true
    evidence = 'The case is still being used one second later';
modify FearTestAction
    exec(context)
    {
        local code = fearInput.code;
        if (code == 630)
        { local value = extremeFirst.assess(); event('test.panic-object-preview'); eventValue(value.status); eventValue(value.reason); return nil; }
        if (code == 631)
        {
            event('test.panic-object'); eventValue(panicObjectCondition.injury); eventValue(panicObjectCondition.destroyed ? 1 : 0);
            eventValue(panicObjectCondition.disabled ? 1 : 0); eventValue(panicObject.usableBy(fearProfile) ? 1 : 0);
            eventValue(panicObjectCondition.wounds.length()); eventValue(panicObjectCondition.stresses.length());
            eventValue(fearProfile.equipment.length()); eventValue(panicObject.quantity);
            eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 632) { panicObjectWound.amount = 20; return nil; }
        if (code == 633) { panicObjectWound.amount = 10; panicObjectWound.apply(); return nil; }
        if (code == 634) { panicDice.rolls = [3,18]; return nil; }
        if (code == 635 || code == 636)
        { objectStress.apply(); if (code == 636) throw new RpgError(); return nil; }
        if (code == 637) { rpgSpendTime(1); objectStressNext.apply(); return nil; }
        if (code == 638) { panicObjectCondition.injury = 0; panicObjectCondition.validate(); return nil; }
        if (code == 639) { panicObjectCondition.sentient = true; panicObjectWound.assess(); return nil; }
        if (code == 640) { panicObjectParalysis.apply(); return nil; }
        if (code == 641) { panicObjectGate.apply(); return nil; }
        if (code == 642) { fearProfile.injury = fearProfile.maxHP; panicDice.rolls = [18,18,3]; return nil; }
        if (code == 643)
        { event('test.panic-object-permission'); eventValue(fearProfile.effortHistory.length());
          eventValue(fearProfile.unconscious ? 1 : 0); eventValue(panicObjectGate.result == nil ? nil : panicObjectGate.result.allowed);
          eventValue(extremeEpisode.completedAt); return nil; }
        if (code == 644) { panicObjectOperation.apply(extremeFirst); return nil; }
        return inherited(context);
    }
;
