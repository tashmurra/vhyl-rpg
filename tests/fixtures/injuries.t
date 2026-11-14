#include "../../examples/magic/world.h"
#include <vhyl-rpg-injuries.t>
#include <vhyl-rpg-injuries-magic.t>
#include <vhyl-rpg-expanded-running.t>
injWorld: RpgMagicWorld;
injMedic: RpgLiteProfile;
injPlace: RpgMagicPlace id = 'clinic';
injSubject: RpgMagicSubject id = 'patient' world = injWorld location = injPlace profile = worker
    alive = true sapient = true kind = 'complex-life';
injEffect: RpgInjuryLifeEffect id = 'repair' target = injSubject amount = 3;
injIntent: RpgMagicIntent state = workMagic effect = injEffect;
injResult: RpgMagicResult;
injFighter: RpgLiteFighter profile = worker;
injOpponent: RpgLiteFighter profile = worker;
injRequest: RpgLiteManeuver hands = 1;
injRun: RpgExpandedRunning profile = worker;
injProvider: RpgGmAuthoredProvider;
injLast: object record = nil result = nil;
injInput: object args = [];
class InjuryTestAction: Action
    exec(context)
    {
        local a = injInput.args; local code = a[1];
        if (code == 1 || code == 9)
        {
            injLast.result = rpgInflictInjury(worker,a[2],a[3] == 'none' ? nil : a[3],a[4],a[5],a[6]);
            injLast.record = injLast.result.record;
            if (code == 9) throw new RpgError();
        }
        if (code == 2) rpgLiteHeal(worker,100);
        if (code == 3) rpgLiteHealthTime(worker,a[2]);
        if (code == 4) injLast.result = rpgTreatInjury(injLast.record,injMedic,18,0,a[2],a[3] != 0);
        if (code == 5) rpgRandom.seed(a[2]);
        if (code == 6) injLast.result = rpgAssessInjury(injLast.record);
        if (code == 7)
        {
            workMagic.subject = injSubject; workMagic.world = injWorld; worker.magicSubject = injSubject;
            injWorld.subjects = [injSubject]; injWorld.places = [injPlace];
            injEffect.injuryRecord = injLast.record;
            rpgPrepareMagicOperation(injEffect,workMagic);
            event('test.life'); eventValue(injEffect.requirements[1][2]);
            eventValue(injEffect.available(injIntent));
            if (injEffect.available(injIntent) == nil)
            { injResult.ruling = [nil,[nil,'coincidental']]; injEffect.apply(injIntent,injResult); }
        }
        if (code == 12)
        {
            try
            {
            workMagic.subject = injSubject; workMagic.world = injWorld; worker.magicSubject = injSubject;
            workMagic.requiresPractice = nil; workMagic.mastery = 5; worker.pointBudget = 10000;
            injWorld.subjects = [injSubject]; injWorld.places = [injPlace]; injWorld.states = [workMagic];
            workScene.world = injWorld; workScene.place = injPlace;
            local k = new RpgMagicKnowledge(); k.owner = workMagic; k.domain = rpgMagicLife; k.rank = a[2];
            workMagic.knowledge = workMagic.knowledge + [k];
            local training = new RpgExpandedTraining(); training.skill = rpgMagicLife; training.points = 24;
            worker.skills = worker.skills + [training];
            injEffect.injuryRecord = injLast.record; rpgPrepareMagicOperation(injEffect,workMagic);
            inspectIntent.practice = nil; inspectIntent.effects = [injEffect];
            injProvider.data = [injEffect.id,'subtle',0,'Repair the authored injury.'];
            rpgGmResolve(inspectIntent,injProvider); rpgRandom.seed(a[3]);
            local r = rpgCastMagic(inspectIntent);
            event('test.cast'); eventValue(r.reason); eventValue(r.delivered);
            }
            catch (RpgExpandedError error)
            { event('test.cast'); eventValue(error.reason); eventValue(nil); }
        }
        if (code == 8) worker.posture = a[2];
        if (code == 10) { rpgTreatInjury(injLast.record,injMedic,18,0,7,true); throw new RpgError(); }
        if (code == 11)
        {
            injFighter.weapon = rpgLiteMakeWeapon('shortsword',10); injFighter.weapon.ready = true;
            event('test.attack'); eventValue(rpgLiteStrike(injFighter,injOpponent,injRequest).reason);
        }
        return nil;
    }
;
injAction: InjuryTestAction;
injVerb: Verb code = 770 action = injAction label = 'injury-test';
startup() { return vhylStart(); }
modify gameMain initialRoom = workroom;
act(verb,args)
{
    if (verb == 770) { injInput.args = args; return vhylAct(770,[]); }
    if (verb == 990)
    {
        local i = injLast.record;
        event('test.injuries');
        foreach (local v in [worker.injury,worker.injuryHands(),worker.injuryLegsUsable(),
            worker.injuryExertionAllowed(),worker.move(),worker.posture,worker.mortal,
            i == nil ? nil : i.active,i == nil ? nil : i.severity,i == nil ? 0 : i.remainingSeconds,
            rpgRandom.draws,rpgLedger.seconds,worker.injuries.length(),
            rpgLiteJumpDistance(worker,nil,0,nil),rpgLiteLift(worker,'two-hands',nil),
            injRun.stopReason()]) eventValue(v);
        return nil;
    }
    return vhylAct(verb,args);
}
