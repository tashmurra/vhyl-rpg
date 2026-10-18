#include "expanded-persistent-dressing.t"
poisonDefinition: RpgLiteHazard kind = 'poison' delay = 60 cycles = 1 dice = 1 adds = 0 resistanceModifier = -2;
poisonDelivery: RpgExpandedPoisonEntry patient = bleedProfile route = 'blood' persistentWoundReached = true
    approved = true evidence = 'The fictional agent actually reached the persistent opening';
poisonExposure: RpgExpandedPoisonExposure id = 'fictional-agent' profile = bleedProfile hazard = poisonDefinition entry = poisonDelivery
    approved = true effectEvidence = 'Original fictional single-cycle agent: one die of toxic injury after one minute, resisted at HT-2';
poisonSecondCycle: RpgExpandedPoisonCycle id = 'second' exposure = poisonExposure;
poisonAntidote: RpgExpandedAntidote id = 'fictional-antidote' targetHazard = poisonDefinition quantity = 1
    resistanceBonus = 3 effectEvidence = 'Original agent-specific fictional remedy grants three to resistance';
poisonCare: RpgExpandedAntidoteAdministration id = 'fictional-care' exposure = poisonExposure medicine = poisonAntidote
    approved = true identificationEvidence = 'The sealed fictional sample identifies the admitted agent'
    administrationEvidence = 'An authored action administered one available dose';
poisonCareRepeat: RpgExpandedAntidoteAdministration id = 'fictional-repeat' exposure = poisonExposure medicine = poisonAntidote
    approved = true identificationEvidence = 'Same identified fictional agent'
    administrationEvidence = 'A proposed repeat administration';
poisonTreatment: RpgExpandedPoisonTreatment id = 'fictional-treatment' exposure = poisonExposure
    healer = surgicalHealer skill = surgicalAid approved = true suitable = true
    identificationEvidence = 'The original fictional agent is identified'
    suitabilityEvidence = 'The fictional agent permits this treatment without a harmful exception';
coatingMode: RpgLiteAttackMode skillId = 'first-aid' base = 'fixed' dice = 1 adds = 0 damageType = 'imp';
coatingWeapon: RpgLiteWeapon id = 'fictional-point' modes = [coatingMode] ready = true;
coatingStock: RpgExpandedPoisonStock id = 'fictional-stock' hazard = poisonDefinition quantity = 6;
weaponCoating: RpgExpandedWeaponCoating id = 'point-coating' profile = surgicalHealer weapon = coatingWeapon
    stock = coatingStock mode = coatingMode approved = true evidence = 'Ordinary coating on this fictional weapon';
coatingFighter: RpgLiteFighter profile = surgicalHealer weapon = coatingWeapon;
coatingTarget: RpgLiteFighter profile = bleedProfile;
coatingAttack: RpgLiteManeuver kind = 'attack' target = coatingTarget defense = 'dodge' defenseModifier = 20;
poisonCatalogueInput: object nextId = 'cycle';
poisonKnowledge: RpgExpandedSkill id = 'poisons' attribute = rpgIQ difficulty = 2 techLevel = 8;
poisonKnowledgeTraining: RpgExpandedTraining skill = poisonKnowledge points = 4;
poisonDiagnosis: RpgExpandedSkill id = 'diagnosis' attribute = rpgIQ difficulty = 2 techLevel = 8;
poisonDiagnosisTraining: RpgExpandedTraining skill = poisonDiagnosis points = 4;
poisonNaturalist: RpgExpandedSkill id = 'naturalist' attribute = rpgIQ difficulty = 2;
poisonNaturalistTraining: RpgExpandedTraining skill = poisonNaturalist points = 4;
poisonIdentification: RpgExpandedPoisonIdentification id = 'identified-agent' exposure = poisonExposure
    examiner = surgicalHealer skill = poisonKnowledge approved = true durationSeconds = 5
    evidence = 'An available residue sample from the same original fictional agent';
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 260) { poisonExposure.start(); return nil; }
        if (code == 261) { poisonExposure.assessResolution(); return nil; }
        if (code == 262 || code == 263)
        { poisonExposure.resolve(); if (code == 263) throw new RpgError(); return nil; }
        if (code == 264)
        {
            event('test.poison-exposure'); eventValue(poisonExposure.startedAt); eventValue(poisonExposure.dueAt);
            eventValue(poisonExposure.completedAt); eventValue(bleedProfile.poisonExposures.length());
            eventValue(bleedProfile.injury); eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 265) { bleedInput.forcedRoll = 17; surgicalOperationInput.fixedDie = 4; return nil; }
        if (code == 266) { bleedInput.forcedRoll = 8; return nil; }
        if (code == 267) { poisonExposure.sizeModifier = -1; return nil; }
        if (code == 268) { rpgSpendTime(30); return nil; }
        if (code == 269) { poisonDefinition.cycles = 2; poisonDefinition.interval = 60; return nil; }
        if (code == 270) { poisonDefinition.resistible = nil; surgicalOperationInput.fixedDie = 4; return nil; }
        if (code == 271) { poisonDefinition.delay = 1; poisonExposure.sizeModifier = -1; return nil; }
        if (code == 272 || code == 273)
        { poisonSecondCycle.apply(); if (code == 273) throw new RpgError(); return nil; }
        if (code == 274) { rpgLiteHeal(bleedProfile,1); return nil; }
        if (code == 275)
        {
            event('test.poison-cycle'); eventValue(poisonExposure.cycleHistory.length());
            eventValue(poisonExposure.remaining); eventValue(bleedProfile.cyclicPoisonInjury());
            eventValue(bleedProfile.injury); eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 276)
        { poisonDelivery.route = 'digestive'; poisonDelivery.swallowed = true; poisonExposure.doseDoublings = 1; return nil; }
        if (code == 277) { poisonExposure.doseDoublings = 1; return nil; }
        if (code == 278)
        {
            local value = poisonExposure.doseAssessment(); event('test.poison-dose'); eventValue(value.status);
            eventValue(value.doses); eventValue(value.damageMultiplier); eventValue(value.costMultiplier);
            eventValue(value.delaySeconds); eventValue(value.intervalSeconds);
            eventValue(value.resistanceModifier); eventValue(value.detectionModifier); return nil;
        }
        if (code == 279) { poisonExposure.doseDoublings = 2; return nil; }
        if (code == 280) { bleedProfile.equipment = bleedProfile.equipment + [poisonAntidote]; return nil; }
        if (code == 281) { poisonCare.assess(); return nil; }
        if (code == 282 || code == 283)
        { poisonCare.apply(); if (code == 283) throw new RpgError(); return nil; }
        if (code == 284)
        { poisonAntidote.resistanceBonus = 0; poisonAntidote.endsExposure = true; return nil; }
        if (code == 285) { poisonAntidote.targetHazard = nil; return nil; }
        if (code == 286)
        {
            event('test.poison-antidote'); eventValue(poisonAntidote.quantity);
            eventValue(bleedProfile.poisonAntidotes.length()); eventValue(poisonExposure.antidoteBonus());
            eventValue(poisonExposure.finished ? 1 : 0); eventValue(bleedProfile.injury);
            eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 287) { bleedInput.forcedRoll = 10; return nil; }
        if (code == 288) { poisonCareRepeat.apply(); return nil; }
        if (code == 290) { poisonTreatment.assess(); return nil; }
        if (code == 291 || code == 292)
        { poisonTreatment.apply(); if (code == 292) throw new RpgError(); return nil; }
        if (code == 293)
        { poisonTreatment.kind = 'digestive'; poisonDelivery.route = 'digestive'; poisonDelivery.swallowed = true; return nil; }
        if (code == 294)
        {
            poisonTreatment.kind = 'medical'; poisonTreatment.skill = surgicalPhysician;
            surgicalHealer.skills = [surgicalPhysicianTraining]; poisonTreatment.medicalTechnology = 8;
            poisonTreatment.medicalSeconds = 20; poisonTreatment.medicalBonus = 4; return nil;
        }
        if (code == 295) { poisonTreatment.suitable = nil; return nil; }
        if (code == 296)
        {
            event('test.poison-treatment'); eventValue(bleedProfile.poisonTreatments.length());
            eventValue(poisonExposure.treatmentBonus()); eventValue(bleedProfile.injury);
            eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 297) { poisonTreatment.medicalBonus = 5; return nil; }
        if (code == 298) { rpgSpendTime(50); return nil; }
        if (code == 300) { rpgSpendTime(40); return nil; }
        if (code == 310) { surgicalHealer.equipment = [coatingWeapon,coatingStock]; return nil; }
        if (code == 311) { weaponCoating.assess(); return nil; }
        if (code == 312 || code == 313)
        { weaponCoating.apply(); if (code == 313) throw new RpgError(); return nil; }
        if (code == 314) { rpgLiteStrike(coatingFighter,coatingTarget,coatingAttack); return nil; }
        if (code == 315) { coatingAttack.defenseModifier = -20; surgicalOperationInput.fixedDie = 4; return nil; }
        if (code == 316) { coatingMode.damageType = 'cut'; weaponCoating.reachYards = 2; return nil; }
        if (code == 317)
        {
            event('test.poison-coating'); eventValue(coatingStock.quantity); eventValue(weaponCoating.contacts.length());
            eventValue(weaponCoating.defendedContacts); eventValue(weaponCoating.depleted ? 1 : 0); return nil;
        }
        if (code == 318)
        {
            local strike = new RpgLiteCombatResult(); strike.status = 'resolved'; strike.outcome = 'defended';
            strike.successfulDefense = 'parry'; weaponCoating.recordStrike(strike); weaponCoating.recordStrike(strike); return nil;
        }
        if (code == 320 || code == 322)
        {
            poisonExposure.hazard = rpgExpandedPoisonCatalogue(code == 320 ? 'delayed-ingested-agent' : 'rapid-systemic-agent','digestive');
            poisonDelivery.route = 'digestive'; poisonDelivery.swallowed = true; return nil;
        }
        if (code == 321)
        {
            poisonExposure.hazard = rpgExpandedPoisonCatalogue('rapid-systemic-agent','respiratory');
            poisonDelivery.route = 'respiratory'; poisonDelivery.inhaled = true; return nil;
        }
        if (code == 323)
        {
            local stock = rpgExpandedPoisonCatalogueStock('catalogue-lot','rapid-systemic-agent','digestive',3);
            event('test.poison-stock'); eventValue(stock.quantity); eventValue(stock.cost);
            eventValue(stock.techLevel); eventValue(stock.legality); return nil;
        }
        if (code == 324)
        {
            local h = poisonExposure.hazard; event('test.poison-catalogue'); eventValue(h.techLevel);
            eventValue(h.unitCost); eventValue(h.legality); eventValue(h.delay); eventValue(h.interval);
            eventValue(h.cycles); eventValue(h.dice); eventValue(h.resistible ? 1 : 0); eventValue(h.resistanceModifier); return nil;
        }
        if (code == 325) { rpgSpendTime(3600); return nil; }
        if (code == 326) { rpgSpendTime(900); return nil; }
        if (code == 327) { poisonExposure.hazard.delay = 1; return nil; }
        if (code == 328)
        {
            local names = ['one','two','three','four','five','six','seven','eight'];
            local cycle = new RpgExpandedPoisonCycle(); cycle.exposure = poisonExposure;
            cycle.id = names[poisonExposure.cycleHistory.length() + 1]; rpgSpendTime(3600); cycle.apply(); return nil;
        }
        if (code == 330 || code == 331)
        {
            poisonDelivery.route = code == 330 ? 'contact' : 'respiratory';
            poisonExposure.hazard = rpgExpandedPoisonCatalogue('dual-route-agent',poisonDelivery.route);
            poisonDelivery.method = 'area'; poisonDelivery.inArea = true; poisonDelivery.inhaled = true;
            poisonExposure.preparedForAgent = true; poisonExposure.preparationEvidence = 'The patient was briefed on this specific hazard';
            return nil;
        }
        if (code == 332) { rpgSpendTime(7200); return nil; }
        if (code == 333)
        {
            local cycle = new RpgExpandedPoisonCycle(); cycle.exposure = poisonExposure;
            cycle.id = poisonCatalogueInput.nextId; poisonCatalogueInput.nextId += '-next';
            rpgSpendTime(poisonExposure.hazard.interval); cycle.apply(); return nil;
        }
        if (code == 334) { poisonExposure.preparedForAgent = nil; return nil; }
        if (code == 335) { poisonDelivery.method = 'direct'; return nil; }
        if (code == 336) { poisonDefinition.dice = 0; poisonDefinition.adds = 0; return nil; }
        if (code == 340)
        {
            poisonExposure.hazard = rpgExpandedPoisonCatalogue('injected-venom','follow-up');
            poisonDelivery.route = 'follow-up'; poisonDelivery.method = 'weapon';
            poisonDelivery.wound = bleedWound; poisonDelivery.penetrationKind = 'impaling'; return nil;
        }
        if (code == 341)
        {
            local context = new RpgLiteContext(); context.attribute = rpgDX;
            event('test.poison-symptom'); eventValue(poisonExposure.symptomInjury); eventValue(bleedProfile.poisonDexterityPenalty());
            eventValue(bleedProfile.healthAttributeModifier(context)); context.kind = 'defense';
            eventValue(bleedProfile.healthAttributeModifier(context)); eventValue(bleedProfile.basicSpeedQuarters());
            eventValue(bleedProfile.injury); return nil;
        }
        if (code == 342) { poisonAntidote.targetHazard = poisonExposure.hazard; return nil; }
        if (code == 343) { rpgLiteHeal(bleedProfile,8); return nil; }
        if (code == 344) { rpgLiteHeal(bleedProfile,7); return nil; }
        if (code == 345) { rpgLiteHeal(bleedProfile,6); return nil; }
        if (code == 346)
        {
            local wound = new RpgExpandedWound(); wound.profile = bleedProfile; wound.id = 'unrelated-later-wound';
            wound.amount = 6; wound.apply(); return nil;
        }
        if (code == 347)
        {
            event('test.poison-thresholds');
            foreach (local injury in [3,4,5,6,7]) eventValue(rpgExpandedVenomDexterityPenalty(10,injury)); return nil;
        }
        if (code == 350)
        {
            poisonDefinition.fatigueDamage = true; poisonDefinition.dice = 0; poisonDefinition.adds = 4;
            poisonDefinition.delay = 0; poisonDefinition.cycles = 2; poisonDefinition.interval = 1200; return nil;
        }
        if (code == 351) { rpgLiteRest(bleedProfile,600,nil,nil,nil,nil); return nil; }
        if (code == 352)
        {
            event('test.poison-fatigue'); eventValue(bleedProfile.fatigue); eventValue(bleedProfile.injury);
            eventValue(poisonExposure.lockedFatigue); eventValue(poisonExposure.lockedInjury);
            eventValue(bleedProfile.poisonFatigueLosses.length()); eventValue(rpgLedger.seconds);
            eventValue(rpgRandom.draws); return nil;
        }
        if (code == 353) { bleedProfile.fatigue = 9; return nil; }
        if (code == 354) { rpgSpendTime(600); return nil; }
        if (code == 360)
        { surgicalHealer.skills = [surgicalAidTraining,poisonKnowledgeTraining,poisonDiagnosisTraining,poisonNaturalistTraining]; return nil; }
        if (code == 361) { poisonIdentification.assess(); return nil; }
        if (code == 362 || code == 363)
        { poisonIdentification.apply(); if (code == 363) throw new RpgError(); return nil; }
        if (code == 364)
        {
            event('test.poison-identification'); eventValue(bleedProfile.poisonIdentifications.length());
            eventValue(poisonIdentification.result != nil && poisonIdentification.result.identified ? 1 : 0);
            eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws);
            eventValue(poisonIdentification.result == nil ? nil : poisonIdentification.result.check.score); return nil;
        }
        if (code == 365)
        { poisonIdentification.clue = 'symptoms'; poisonIdentification.skill = poisonDiagnosis; poisonIdentification.observedSymptoms = true; return nil; }
        if (code == 366) { poisonIdentification.clue = 'animal'; poisonIdentification.skill = poisonNaturalist; return nil; }
        if (code == 367) { poisonTreatment.identification = poisonIdentification; poisonTreatment.identificationEvidence = nil; return nil; }
        if (code == 368) { rpgSpendTime(45); return nil; }
        return inherited(context);
    }
;
