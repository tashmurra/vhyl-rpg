#include "../../examples/magic/world.h"
engineWorld: RpgMagicWorld;
engineRoom: Room 'Magic destination';
enginePlace: RpgMagicPlace id = 'laboratory' barrier = 8;
engineOtherPlace: RpgMagicPlace id = 'outside' barrier = 4;
engineSubject: RpgMagicSubject id = 'caster' world = engineWorld profile = worker magic = workMagic
    alive = true sapient = true location = enginePlace kind = 'complex-life';
engineTarget: RpgMagicSubject id = 'target' world = engineWorld location = enginePlace profile = engineProfile
    alive = true sapient = true kind = 'complex-life';
engineProfile: RpgExpandedProfile rules = workRules pointBudget = 10000 disadvantageLimit = 0 magicSubject = engineTarget;
engineProperty: RpgMagicProperty id = 'density' value = 10 minimum = 0 maximum = 1000;
engineInput: object args = [];
engineLast: object value = nil;
engineProvider: RpgGmAuthoredProvider;
engineEffect: RpgMagicOperation id = 'engine-effect' target = engineTarget operation = 'reshape-life' propertyId = 'density' amount = 2 duration = 30;
engineRelationship: RpgMagicRelationship spirit = engineTarget strength = 2 identified = true;
engineDisposition: object attitude = 1 permits(actor,approach) { return nil; };
engineItem: RpgMagicItem id = 'test-item';
engineAbility: RpgMagicItemAbility effect = inspectMaterial;
engineCraft: RpgMagicCraft lead = workMagic item = engineItem;
engineBatch: RpgMagicConsequenceBatch id = 'physical' band = 2;
engineExposure: RpgMagicExposure target = engineTarget yards = 1 armor = 0;
engineSupply: RpgMagicSupply id = 'portion' quantity = 8;
engineSource: RpgMagicSource id = 'source' output = 12;
engineCounter: RpgMagicCounter state = workMagic;

engineSetup()
{
    workMagic.world = engineWorld; workMagic.subject = engineSubject; worker.magicSubject = engineSubject;
    workMagic.mastery = 10; workMagic.channel = 3; workMagic.requiresPractice = nil; workMagic.reserve = 10;
    worker.pointBudget = 10000;
    workMagic.knowledge = []; worker.skills = [craftTraining];
    foreach (local d in [rpgMagicSpace,rpgMagicChance,rpgMagicEnergy,rpgMagicLife,rpgMagicMatter,rpgMagicMind,rpgMagicPower,rpgMagicSpirits,rpgMagicTime])
    {
        local k = new RpgMagicKnowledge(); k.owner = workMagic; k.domain = d; k.rank = 5;
        workMagic.knowledge = workMagic.knowledge + [k];
        local training = new RpgExpandedTraining(); training.skill = d; training.points = 24; worker.skills = worker.skills + [training];
    }
    engineWorld.subjects = [engineSubject,engineTarget]; engineWorld.places = [enginePlace,engineOtherPlace]; engineWorld.states = [workMagic];
    engineTarget.properties = [engineProperty]; engineSubject.properties = [engineProperty]; engineProperty.mental = nil; workScene.world = engineWorld; workScene.place = enginePlace;
    inspectIntent.practice = nil; rpgRandom.seed(1); return nil;
}
engineRule(effect)
{
    inspectIntent.effects = [effect]; engineProvider.data = [effect.id,'subtle',0,'Test authored declaration.'];
    return rpgGmResolve(inspectIntent,engineProvider);
}
engineEmit(value) { eventValue(value); return nil; }
class EngineAction: Action
    exec(context)
    {
        engineSetup(); local a = engineInput.args; local op = a[1]; if (op != 25) event('test.engine');
        if (op == 1)
        {
            foreach (local n in [0,1,2,3,4,5,6,7,8]) engineEmit(rpgMagicDuration(n,nil));
            engineEmit(rpgMagicMass(0,nil,nil)); engineEmit(rpgMagicMass(0,true,nil));
            engineEmit(rpgMagicMass(3,true,true)); engineEmit(rpgMagicSightMargin(9));
            engineEmit(rpgMagicTraitMargin(-21)); engineEmit(rpgMagicDamageDice(rpgMagicEnergy,5,3,nil));
        }
        else if (op == 2)
        {
            local one = rpgMagicLayer(workMagic,engineTarget,'density',3,10,nil);
            local two = rpgMagicLayer(workMagic,engineTarget,'density',5,5,nil);
            engineEmit(engineTarget.value('density')); engineWorld.advance('first',5); engineEmit(engineTarget.value('density'));
            engineWorld.advance('first',5); engineEmit(engineWorld.seconds); engineWorld.advance('second',5); engineEmit(engineTarget.value('density'));
            engineEmit(engineProperty.value); engineEmit(one.active); engineEmit(two.active);
        }
        else if (op == 3)
        {
            rpgMagicWound(engineTarget,2,'backlash',nil); rpgMagicWound(engineTarget,2,'ordinary',nil);
            local healed = rpgHealMagic(engineTarget,2,nil,workMagic); engineEmit(healed.points); engineEmit(engineProfile.injury);
            engineEmit(rpgHealMagic(engineTarget,2,nil,workMagic).points); engineEmit(rpgLiteHeal(engineProfile,2)); engineEmit(engineProfile.injury);
        }
        else if (op == 4)
        {
            local donor = new RpgMagicState(); donor.reserve = 10; donor.channel = 4; workMagic.reserve = 0;
            engineEmit(rpgTransferMagicReserve(donor,workMagic,'transfer',20,2,nil));
            engineEmit(rpgTransferMagicReserve(donor,workMagic,'transfer',20,2,nil));
            engineEmit(donor.reserve); engineEmit(workMagic.reserve);
            rpgAbsorbMagicSupply(engineSupply,[[workMagic,8]]); engineEmit(engineSupply.quantity); engineEmit(workMagic.reserve);
            engineEmit(rpgAbsorbMagicSupply(engineSupply,[[workMagic,8]]).status);
            engineEmit(rpgCollectMagicSource(engineSource,'month-1')); engineEmit(rpgCollectMagicSource(engineSource,'month-1'));
            engineEmit(engineSource.rating()); engineEmit(engineSource.barrier());
        }
        else if (op == 5)
        {
            local e = new RpgMagicOperation(); e.id = 'permission'; e.target = engineTarget; e.operation = a[2];
            e.propertyId = a[3] == 'none' ? nil : a[3];
            if (e.operation == 'enhance-mind') engineProperty.mental = true;
            if (a[4] == 'matter') { engineTarget.alive = nil; engineTarget.sapient = nil; engineTarget.kind = 'matter'; }
            if (a[4] == 'simple') engineTarget.kind = 'simple-life';
            if (a[4] == 'self') e.target = engineSubject;
            e.domain = rpgMagicEnergy;
            if (a.length() >= 5) foreach (local d in [rpgMagicSpace,rpgMagicChance,rpgMagicEnergy,rpgMagicLife,rpgMagicMatter,rpgMagicMind,rpgMagicPower,rpgMagicSpirits,rpgMagicTime])
                if (d.id == a[5]) e.domain = d;
            engineTarget.energyKind = a[4] == 'motion' ? 'motion' : 'light';
            rpgPrepareMagicOperation(e,workMagic);
            foreach (local p in e.requirements) { engineEmit(p[1].id); engineEmit(p[2]); }
            engineEmit(e.minimumMargin); engineEmit(e.delivery);
        }
        else if (op == 6)
        {
            local d = rpgMagicResist(engineTarget,25,a[2],10,nil); engineEmit(d.resisted); engineEmit(d.margin); engineEmit(rpgRandom.draws);
            engineTarget.willing = true; local consent = rpgMagicResist(engineTarget,25,17,10,nil); engineEmit(consent.resisted); engineEmit(rpgRandom.draws);
        }
        else if (op == 7)
        {
            inspectIntent.conspicuous = true; inspectMaterial.minimumMargin = 20; engineRule(inspectMaterial);
            local ritual = rpgBeginMagicRitual(inspectIntent,'brief'); local r = nil;
            for (local i = 1; i <= 13 && !ritual.ended; i++)
            { r = rpgRollMagicRitual(ritual); engineWorld.advance(i,300); }
            engineEmit(ritual.rolls); engineEmit(ritual.progress); engineEmit(ritual.ended);
            engineEmit(inspectGoal.attempts); engineEmit(workState.applied); engineEmit(workMagic.provisional);
            engineEmit(r.status); engineEmit(r.outcome); engineEmit(rpgRollMagicRitual(ritual).outcome); engineEmit(workScene.coincidences);
        }
        else if (op == 8)
        {
            engineRule(inspectMaterial);
            local work = rpgBeginMagicWork(inspectIntent); engineEmit(work.required);
            local r = rpgAdvanceMagicWork(work,work.required);
            engineEmit(r.status); engineEmit(r.outcome); engineEmit(rpgLedger.seconds); engineEmit(workState.applied);
            engineEmit(rpgAdvanceMagicWork(work,0).outcome); engineEmit(workState.applied);
        }
        else if (op == 9)
        {
            local r = rpgBeginMagicCraft(engineCraft,engineAbility); engineEmit(r.status); engineEmit(engineAbility.rating); engineEmit(r.seconds);
            r = rpgAdvanceMagicCraft(engineCraft,engineCraft.required); engineEmit(r.status); engineEmit(engineItem.abilities.length());
            engineEmit(rpgBeginMagicItemCharge(engineCraft).status); rpgChargeMagicItem(engineCraft,2); rpgInterruptMagicCraft(engineCraft);
            engineEmit(engineItem.capacity); engineEmit(engineItem.charge); engineEmit(engineItem.sealed); engineEmit(rpgMagicItemPrice(engineItem));
        }
        else if (op == 10)
        {
            local backlash = new RpgMagicBacklash(); backlash.strength = 10; workMagic.pendingBacklash = backlash;
            engineBatch.exposures = [engineExposure]; local r = rpgResolveMagicBacklash(workMagic,engineBatch);
            engineEmit(r.status); engineEmit(worker.injury); engineEmit(engineProfile.injury);
            engineEmit(rpgResolveMagicBacklash(workMagic,engineBatch).status); engineEmit(worker.injury);
        }
        else if (op == 11)
        {
            engineRelationship.disposition = engineDisposition; engineRelationship.familiarity = 1;
            engineEmit(engineRelationship.contactMargin()); engineEmit(rpgContactMagicSpirit(engineRelationship,workMagic,2,true));
            rpgMagicSpiritIncident(engineRelationship,'favor',1); rpgMagicSpiritIncident(engineRelationship,'favor',1);
            engineEmit(engineDisposition.attitude); engineEmit(engineRelationship.permits(player,nil));
            engineEmit(rpgMagicCanMaterialize(2,13)); engineEmit(rpgMagicCanMaterialize(3,17));
        }
        else if (op == 12)
        {
            engineTarget.memories = [['real','old memory']];
            local layer = rpgMagicLayer(workMagic,engineTarget,'memory',1,5,nil);
            layer.content = [['suppress','real'],['add','false','authored belief']];
            engineEmit(rpgMagicRemember(engineTarget)[1][1]); engineEmit(engineTarget.memories[1][1]);
            engineWorld.advance('expiry',5); engineEmit(rpgMagicRemember(engineTarget)[1][1]);
            local hold = rpgMagicLayer(workMagic,engineTarget,'suspend',1,5,nil);
            local timer = rpgMagicLayer(workMagic,engineTarget,'density',1,3,nil); timer.subjective = true;
            engineWorld.advance('hold',5); engineEmit(timer.active); engineEmit(timer.expires); engineWorld.advance('finish',3); engineEmit(timer.active);
        }
        else if (op == 13)
        {
            rpgPrepareMagicOperation(engineEffect,workMagic); engineRule(engineEffect); local r = rpgCastMagic(inspectIntent);
            engineEmit(r.status); engineEmit(r.outcome); engineEmit(engineTarget.value('density')); engineEmit(inspectGoal.attempts);
        }
        else if (op == 14)
        {
            workMagic.strain = 4; engineWorld.advance('week',604800); engineEmit(workMagic.strain);
            workMagic.strain = 5; engineWorld.advance('blocked-week',604800); engineEmit(workMagic.strain);
            engineEmit(workMagic.recoveryClock);
        }
        else if (op == 15)
        {
            engineRule(inspectMaterial); local r = rpgAssessMagic(inspectIntent);
            r.check = rpgCheck(20,10); inspectIntent.counters = [engineCounter];
            engineEmit(rpgMagicCounterScope(inspectIntent,r)); engineEmit(r.defenses.length()); engineEmit(workMagic.reserve);
        }
        else if (op == 16 || op == 17 || op == 30)
        {
            local state = new RpgMagicState(); local profile = new RpgExpandedProfile();
            state.owner = profile; state.id = 'helper'; state.mastery = 10; state.requiresPractice = nil;
            state.world = engineWorld; profile.rules = workRules; profile.iq = 13;
            profile.pointBudget = 10000; profile.skills = worker.skills; profile.contributions = [state];
            foreach (local k in workMagic.knowledge)
            { local copy = new RpgMagicKnowledge(); copy.owner = state; copy.domain = k.domain; copy.rank = 5; state.knowledge = state.knowledge + [copy]; }
            local goal = new RpgMagicGoal(); goal.id = 'helper-goal'; goal.owner = state;
            local slot = new RpgMagicOpportunity(); slot.id = 'helper-attempt'; slot.owner = state; slot.goal = goal;
            state.opportunities = [slot]; local intent = new RpgMagicIntent(); intent.id = 'helper-intent';
            intent.state = state; intent.scene = workScene; intent.opportunity = slot; intent.effects = [inspectMaterial];
            if (op == 17) { state.mastery = 5; inspectMaterial.minimumMargin = 30; }
            if (op == 30) { inspectMaterial.minimumMargin = 10; inspectIntent.counters = [engineCounter]; rpgRandom.seed(2933); }
            engineRule(inspectMaterial); rpgGmResolve(intent,engineProvider);
            local group = new RpgMagicGroup(); group.intents = [inspectIntent,intent]; local r = nil;
            if (op == 16) r = rpgCastMagicGroup(group);
            else
            { local ritual = rpgBeginMagicGroupRitual(group,'brief');
              for (local i = 1; i <= 3 && !ritual.ended; i++) { r = rpgRollMagicGroupRitual(ritual); engineWorld.advance(i,300); }
              engineEmit(ritual.progress); engineEmit(ritual.rolls); engineEmit(ritual.ended);
              engineEmit(ritual.members[1].limit); engineEmit(ritual.members[2].limit); }
            engineEmit(r.status); engineEmit(r.outcome); engineEmit(workState.applied);
            engineEmit(inspectGoal.attempts); engineEmit(goal.attempts); engineEmit(workMagic.strain); engineEmit(state.strain);
            engineEmit(rpgLedger.seconds);
            if (op == 30) { engineEmit(r.defenses.length()); engineEmit(inspectGoal.completed); engineEmit(goal.completed); }
        }
        else if (op == 18)
        {
            worker.ht = 18; inspectMaterial.minimumMargin = 100; engineRule(inspectMaterial);
            local ritual = rpgBeginMagicRitual(inspectIntent,'major'); rpgRollMagicRitual(ritual);
            rpgPauseMagicRitual(ritual); engineWorld.advance('pause',172801); rpgResumeMagicRitual(ritual,true);
            engineEmit(ritual.ended); engineEmit(workState.applied); engineEmit(workMagic.ritual == nil); engineEmit(inspectGoal.attempts);
        }
        else if (op == 19)
        {
            local first = new RpgMagicComplication(); first.id = 'one'; first.description = 'An authored visible sign.'; first.severity = 5;
            workMagic.strain = 9; engineEmit(rpgAcceptMagicComplications(workMagic,'batch',[first]).status);
            engineEmit(workMagic.strain); engineEmit(first.active); engineEmit(rpgAcceptMagicComplications(workMagic,'batch',[first]).status);
        }
        else if (op == 20)
        {
            inspectMaterial.seconds = 10; engineRule(inspectMaterial);
            local work = rpgBeginMagicWork(inspectIntent); rpgAdvanceMagicWork(work,4); rpgInterruptMagic(workMagic,'stun');
            engineEmit(work.ended); engineEmit(rpgLedger.seconds); engineEmit(workMagic.reserve); engineEmit(rpgRandom.draws); engineEmit(inspectGoal.attempts);
        }
        else if (op == 21)
        {
            inspectMaterial.minimumMargin = 100; engineRule(inspectMaterial);
            local ritual = rpgBeginMagicRitual(inspectIntent,'major'); rpgRollMagicRitual(ritual);
            engineEmit(ritual.ended); engineEmit(ritual.rolls); engineEmit(ritual.endurance); engineEmit(rpgLedger.seconds); engineEmit(workMagic.reserve);
        }
        else if (op == 22)
        {
            local r = new RpgMagicResult(); r.delivered = true; r.scope = 6; r.ruling = [nil,['aid','subtle',0,'Authored.']];
            local aid = new RpgMagicAssistance(); aid.result = r; aid.task = 'climb';
            engineEmit(rpgUseMagicAssistance(aid,'jump')); engineEmit(rpgUseMagicAssistance(aid,'climb')); engineEmit(rpgUseMagicAssistance(aid,'climb'));
            local maneuver = new RpgMagicManeuver(); maneuver.magicResult = r;
            engineEmit(maneuver.damageModifier(nil,nil,nil)); maneuver.apply(nil,nil); engineEmit(maneuver.damageModifier(nil,nil,nil));
        }
        else if (op == 23)
        {
            inspectMaterial.defensive = true; inspectIntent.purpose = 'defense'; engineRule(inspectMaterial); local r = rpgImmediateMagicDefense(inspectIntent);
            engineEmit(r.status); engineEmit(r.delivered); engineEmit(r.score); engineEmit(workMagic.reserve); engineEmit(workMagic.lastTurn);
            engineEmit(rpgImmediateMagicDefense(inspectIntent).status); engineEmit(rpgRandom.draws);
        }
        else if (op == 24)
        {
            engineProperty.id = 'st'; rpgMagicLayer(workMagic,engineTarget,'st',5,2,nil);
            engineEmit(engineProfile.st); engineEmit(engineProfile.attributeScore(rpgST)); engineEmit(engineProfile.maxHP); engineEmit(engineProfile.basicLiftHundredths());
            engineWorld.advance('end-strength',2); engineEmit(engineProfile.maxHP); engineEmit(engineProfile.attributeScore(rpgST));
        }
        else if (op == 25)
        {
            engineOtherPlace.room = engineRoom; engineTarget.entity = workAssistant; engineTarget.willing = true;
            engineEffect.operation = 'relocate'; engineEffect.propertyId = nil; engineEffect.destination = engineOtherPlace;
            rpgPrepareMagicOperation(engineEffect,workMagic); engineRule(engineEffect); local r = rpgCastMagic(inspectIntent);
            event('test.engine'); engineEmit(r.status); engineEmit(r.delivered);
            engineEmit(location.get(workAssistant) == engineRoom); engineEmit(engineTarget.location == engineOtherPlace);
        }
        else if (op == 26)
        {
            local defender = new RpgLiteFighter(); defender.profile = engineProfile;
            local maneuver = new RpgMagicManeuver(); maneuver.applyInjury(defender,2);
            local first = new RpgLiteCombatResult(); first.attack = rpgCheck(10,10);
            local second = new RpgLiteCombatResult(); second.attack = rpgCheck(10,18); first.strikes = [second];
            engineEmit(engineProfile.injury); maneuver.apply(nil,first); engineEmit(engineProfile.injury); engineEmit(first.outcome);
            local good = new RpgMagicManeuver(); good.applyInjury(defender,2); first.strikes = []; first.attack = rpgCheck(10,10);
            good.apply(nil,first); engineEmit(engineProfile.injury);
        }
        else if (op == 27)
        {
            rpgPrepareMagicOperation(engineEffect,workMagic); engineEffect.amount = 3;
            engineEmit(engineEffect.available(inspectIntent)); rpgPrepareMagicOperation(engineEffect,workMagic); engineEmit(engineEffect.available(inspectIntent));
        }
        else if (op == 28)
        {
            engineEffect.operation = 'memory'; engineEffect.propertyId = nil; engineEffect.content = [['add','id']];
            try { rpgPrepareMagicOperation(engineEffect,workMagic); engineEmit('unexpected-success'); }
            catch (RpgExpandedError error) { engineEmit(error.reason); }
            engineEffect.content = [['add','id','First authored memory.']]; rpgPrepareMagicOperation(engineEffect,workMagic); engineRule(engineEffect);
            engineEffect.content = [['add','id','Changed authored memory.']]; rpgPrepareMagicOperation(engineEffect,workMagic);
            engineEmit(rpgGmRead(inspectIntent).status); engineEmit(rpgRandom.draws);
        }
        else if (op == 29)
        {
            worker.unspentPoints = 100; worker.developmentOpen = true; local before = rpgExpandedCharacterCost(worker,nil);
            local offer = new RpgMagicSupplyPurchase(); offer.id = 'source-share'; offer.state = workMagic; offer.source = engineSource; offer.units = 5; offer.unlocked = true;
            engineEmit(rpgBuyMagicSupply(offer).points); engineEmit(rpgBuyMagicSupply(offer).status); engineEmit(worker.unspentPoints); engineEmit(engineSource.output);
            local excess = new RpgMagicSupplyPurchase(); excess.id = 'excess'; excess.state = workMagic; excess.source = engineSource; excess.unlocked = true;
            engineEmit(rpgBuyMagicSupply(excess).reason);
            local portable = new RpgMagicSupplyPurchase(); portable.id = 'starting-portion'; portable.state = workMagic; portable.portion = engineSupply; portable.units = 2; portable.creation = true; portable.unlocked = true;
            engineEmit(rpgBuyMagicSupply(portable).points); engineEmit(engineSupply.quantity); engineEmit(worker.unspentPoints); engineEmit(workMagic.portableInvestment); engineEmit(rpgExpandedCharacterCost(worker,nil) - before);
        }
        else if (op == 31)
        {
            inspectMaterial.minimumMargin = 100; engineRule(inspectMaterial); local ritual = rpgBeginMagicRitual(inspectIntent,'brief');
            engineProvider.data = ['redirect-light','subtle',0,'Feasible additional working.']; rpgGmResolve(redirectIntent,engineProvider);
            local r = rpgCastDuringMagicRitual(ritual,redirectIntent,true);
            engineEmit(r.status); engineEmit(r.delivered); engineEmit(workMagic.ritual == ritual); engineEmit(inspectGoal.attempts); engineEmit(redirectGoal.completed);
        }
        else if (op == 32)
        {
            workMagic.concentration = 2; engineRule(inspectMaterial); local r = rpgBeginMagicRitual(inspectIntent,'brief');
            engineEmit(r.status); engineEmit(r.reason); engineEmit(inspectGoal.attempts); engineEmit(workMagic.ritual == nil);
        }
        else if (op == 33)
        {
            enginePlace.source = engineSource; engineRule(inspectMaterial); engineEmit(rpgAssessMagic(inspectIntent).score); engineEmit(workScene.sourceBonus());
        }
        else if (op == 34)
        {
            workMagic.reserve = 0; workMagic.channel = 20;
            engineEffect.operation = 'replenish'; engineEffect.target = engineSubject; engineEffect.propertyId = nil; engineEffect.amount = 20;
            rpgPrepareMagicOperation(engineEffect,workMagic); engineRule(engineEffect); local r = rpgCastMagic(inspectIntent);
            engineEmit(r.outcome); engineEmit(workMagic.reserve); engineEmit(engineEffect.minimumMargin);
        }
        else if (op == 35)
        {
            engineEffect.amount = 10; rpgPrepareMagicOperation(engineEffect,workMagic);
            local r = new RpgMagicResult(); r.effect = engineEffect; r.score = 22; r.check = rpgCheck(22,3);
            rpgMagicFinishScope(inspectIntent,r); engineEmit(r.outcome); engineEmit(r.delivered); engineEmit(r.scope); engineEmit(engineEffect.criticalMinimum);
        }
        else if (op == 36)
        {
            engineSupply.channelled = true; engineTarget.supply = engineSupply; engineEffect.operation = 'receive'; engineEffect.propertyId = nil; engineEffect.amount = 1;
            rpgPrepareMagicOperation(engineEffect,workMagic); local r = new RpgMagicResult(); r.check = rpgCheck(10,12);
            engineEffect.afterRoll(inspectIntent,r); engineEmit(engineEffect.available(inspectIntent)); engineEmit(workMagic.reserve); engineEmit(engineSupply.quantity);
        }
        return nil;
    }
;
engineAction: EngineAction;
engineVerb: Verb code = 720 action = engineAction label = 'magic-engine-test';
startup() { return vhylStart(); }
act(verb,args)
{
    if (verb == 721)
    { event('test.engine-saved'); eventValue(engineWorld.seconds); eventValue(engineTarget.value('density'));
      eventValue(workMagic.reserve); eventValue(workMagic.strain); eventValue(workState.applied); return nil; }
    engineInput.args = args; return vhylAct(verb,[]);
}
