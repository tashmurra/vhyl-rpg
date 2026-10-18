/* Include after expanded foundation, skills and health. Partial hazard assessments, full-2008 B444. */

class RpgExpandedInfectionAssessment: RpgExpandedResult
    checkRequired = nil
    prevented = nil
    intervalSeconds = 0
    failureInjury = 0
    successEndsInfection = nil
;

/** Explicit wound contamination and treatment facts; no exposure is committed. */
class RpgExpandedInfectionContext: object
    infectedMatter = nil
    specialLocale = nil
    antibiotics = nil
    medicalTL = 6
    criticalTreatmentFailure = nil
    untreatedDirtyWound = nil
    contaminationModifier()
    {
        return (self.infectedMatter ? -2 : 0) + (self.specialLocale ? -3 : 0);
    }
    assessAcquisition()
    {
        rpgInteger(self.medicalTL,0,1000);
        local value = new RpgExpandedInfectionAssessment();
        if (self.antibiotics && self.medicalTL < 6)
        { value.reason = 'infection-antibiotics-technology'; return value; }
        if (self.antibiotics && self.criticalTreatmentFailure)
        { value.reason = 'infection-critical-treatment-adjudication'; return value; }
        if (self.antibiotics)
        { value.prevented = true; value.status = 'ready'; return value; }
        if (!self.untreatedDirtyWound)
        { value.reason = 'infection-exposure-not-established'; return value; }
        value.checkRequired = true; value.modifier = 3 + self.contaminationModifier();
        value.status = 'ready'; return value;
    }
    assessTypicalProgression()
    {
        rpgInteger(self.medicalTL,0,1000);
        local value = new RpgExpandedInfectionAssessment();
        if (self.antibiotics && self.medicalTL < 6)
        { value.reason = 'infection-antibiotics-technology'; return value; }
        value.checkRequired = true; value.modifier = self.contaminationModifier() + (self.antibiotics ? 3 : 0);
        value.intervalSeconds = 86400; value.failureInjury = 1; value.successEndsInfection = true;
        value.status = 'ready'; return value;
    }
;

modify RpgExpandedWound
    infectionExposure = nil
;

class RpgExpandedInfectionResult: RpgExpandedResult
    immune = nil
    infected = nil
    prevented = nil
    context = nil
;

/** Private acquisition receipt. Hosts must not display it before discovery. */
class RpgExpandedInfectionExposure: object
    patient() { return self.wound.profile; }
    sourceId() { return self.wound.id; }
    ownsSource() { return holds(self.patient().expandedWounds,self.wound); }
    rememberExposure() { self.wound.infectionExposure = self; }
    diseaseId = nil
    boundDiseaseId = nil
    wound = nil
    conditions = nil
    evidence = nil
    result = nil
    acquiredAt = nil
    boundWound = nil
    boundConditions = nil
    boundEvidence = nil
    infectedMatter = nil
    specialLocale = nil
    antibiotics = nil
    medicalTL = nil
    criticalTreatmentFailure = nil
    untreatedDirtyWound = nil
    assess()
    {
        local value = new RpgExpandedInfectionResult();
        if (self.wound == nil || !self.wound.ofKind(RpgExpandedWound)
            || self.conditions == nil || !self.conditions.ofKind(RpgExpandedInfectionContext))
            rpgExpandedReject('infection-exposure-definition');
        if (self.result != nil)
        {
            if (self.diseaseId != self.boundDiseaseId || self.wound != self.boundWound || self.conditions != self.boundConditions
                || self.evidence != self.boundEvidence || self.wound.infectionExposure != self
                || self.conditions.infectedMatter != self.infectedMatter
                || self.conditions.specialLocale != self.specialLocale || self.conditions.antibiotics != self.antibiotics
                || self.conditions.medicalTL != self.medicalTL
                || self.conditions.criticalTreatmentFailure != self.criticalTreatmentFailure
                || self.conditions.untreatedDirtyWound != self.untreatedDirtyWound)
                rpgExpandedReject('infection-exposure-binding');
            value.status = 'reused'; value.check = self.result.check;
            value.immune = self.result.immune; value.infected = self.result.infected; value.prevented = self.result.prevented; return value;
        }
        if (self.wound.health == nil || self.wound.profile != self.wound.boundProfile
            || !holds(self.wound.profile.expandedWounds,self.wound))
            rpgExpandedReject('infection-uncommitted-wound');
        if (self.wound.infectionExposure != nil)
        { value.reason = 'infection-exposure-already-resolved'; return value; }
        if (self.wound.health.injury <= 0 || self.wound.profile.dead)
        { value.reason = 'infection-patient-condition'; return value; }
        if (self.evidence == nil || self.evidence == '')
        { value.reason = 'infection-exposure-evidence'; return value; }
        if (self.diseaseId == nil || self.diseaseId == '') rpgExpandedReject('infection-disease-id');
        local resistance = self.wound.profile.diseaseResistance(self.diseaseId);
        if (resistance != nil && resistance.immune)
        { value.immune = true; value.status = 'ready'; return value; }
        local assessment = self.conditions.assessAcquisition();
        if (assessment.status != 'ready') { value.reason = assessment.reason; return value; }
        value.prevented = assessment.prevented;
        if (assessment.checkRequired)
        {
            value.context = new RpgLiteContext(); value.context.attribute = rpgHT;
            value.context.kind = 'disease'; value.context.modifier = assessment.modifier;
            local score = rpgLiteScore(self.wound.profile,value.context);
            if (score == nil || score < 3)
            { value.reason = 'infection-resistance-score-unavailable'; return value; }
        }
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        if (value.context != nil)
        {
            value.check = rpgLiteCheck(self.patient(),value.context); value.infected = !value.check.achieved;
            if (self.patient().diseaseResistance(self.diseaseId) == nil)
            {
                local record = new RpgExpandedDiseaseResistance(); record.diseaseId = self.diseaseId;
                record.profile = self.patient(); record.firstExposure = self; record.firstRoll = value.check.roll;
                record.immune = rpgExpandedNaturalDiseaseImmunity(value.check.roll);
                value.immune = record.immune;
                self.patient().diseaseResistances = self.patient().diseaseResistances + [record];
            }
        }
        self.boundDiseaseId = self.diseaseId;
        self.boundWound = self.wound; self.boundConditions = self.conditions; self.boundEvidence = self.evidence;
        self.infectedMatter = self.conditions.infectedMatter; self.specialLocale = self.conditions.specialLocale;
        self.antibiotics = self.conditions.antibiotics; self.medicalTL = self.conditions.medicalTL;
        self.criticalTreatmentFailure = self.conditions.criticalTreatmentFailure;
        self.untreatedDirtyWound = self.conditions.untreatedDirtyWound;
        self.acquiredAt = rpgLedger.seconds; self.rememberExposure();
        value.status = 'resolved'; self.result = value; return value;
    }
;

modify RpgExpandedProfile
    validateFeatures()
    {
        inherited();
        foreach (local wound in self.expandedWounds)
            if (wound.infectionExposure != nil)
            {
                local exposure = wound.infectionExposure;
                if (!exposure.ofKind(RpgExpandedInfectionExposure) || exposure.wound != wound
                    || exposure.result == nil || exposure.acquiredAt == nil
                    || exposure.acquiredAt > rpgLedger.seconds || exposure.assess().status != 'reused')
                    rpgExpandedReject('infection-exposure-history');
                local ordinal = 0; local locked = 0; local ended = nil; local ids = [];
                foreach (local day in exposure.days)
                {
                    ordinal += 1;
                    if (!day.ofKind(RpgExpandedInfectionDay) || day.exposure != exposure
                        || day.result == nil || day.ordinal != ordinal || holds(ids,day.id)
                        || day.completedAt != exposure.acquiredAt + ordinal * 86400
                        || day.completedAt > rpgLedger.seconds || ended || day.assess().status != 'reused')
                        rpgExpandedReject('infection-day-history');
                    ids = ids + [day.id]; locked += day.result.injury; ended = day.result.ended;
                }
                if (exposure.ended != ended || exposure.lockedInjury != (ended ? 0 : locked)
                    || exposure.lockedInjury > self.diseaseInjury)
                    rpgExpandedReject('infection-injury-history');
            }
        return nil;
    }
;

modify RpgExpandedInfectionExposure
    days = []
    lockedInjury = 0
    ended = nil
;

class RpgExpandedInfectionDayResult: RpgExpandedResult
    physicianBonus = 0
    injury = 0
    ended = nil
    context = nil
    failureWound = nil
;

/** One typical infection interval at its exact shared-time boundary. */
class RpgExpandedInfectionDay: object
    id = nil
    boundId = nil
    practice = nil
    continuousCare = nil
    boundPractice = nil
    boundContinuousCare = nil
    exposure = nil
    antibiotics = nil
    medicalTL = 6
    careEvidence = nil
    dropDestination = nil
    boundExposure = nil
    boundAntibiotics = nil
    boundMedicalTL = nil
    boundEvidence = nil
    boundDestination = nil
    ordinal = 0
    completedAt = nil
    result = nil
    assess()
    {
        local value = new RpgExpandedInfectionDayResult();
        if (self.exposure == nil || !self.exposure.ofKind(RpgExpandedInfectionExposure)
            || self.exposure.result == nil || self.exposure.assess().status != 'reused')
            rpgExpandedReject('infection-day-exposure');
        if (self.result != nil)
        {
            if (self.practice != self.boundPractice || self.continuousCare != self.boundContinuousCare
                || self.id != self.boundId || self.exposure != self.boundExposure || self.antibiotics != self.boundAntibiotics
                || self.medicalTL != self.boundMedicalTL || self.careEvidence != self.boundEvidence
                || self.dropDestination != self.boundDestination || !holds(self.exposure.days,self))
                rpgExpandedReject('infection-day-binding');
            value.status = 'reused'; value.check = self.result.check; value.injury = self.result.injury;
            value.physicianBonus = self.result.physicianBonus;
            value.ended = self.result.ended; value.failureWound = self.result.failureWound; return value;
        }
        if (self.id == nil || self.id == '') rpgExpandedReject('infection-day-id');
        foreach (local prior in self.exposure.days)
            if (prior.id == self.id) rpgExpandedReject('infection-day-duplicate');
        local patient = self.exposure.patient();
        if (!self.exposure.result.infected || self.exposure.ended || patient.dead)
        { value.reason = 'infection-not-active'; return value; }
        local due = self.exposure.acquiredAt + (self.exposure.days.length() + 1) * 86400;
        if (rpgLedger.seconds != due)
        { value.reason = rpgLedger.seconds < due ? 'infection-day-not-due' : 'infection-missed-boundary'; return value; }
        if (self.careEvidence == nil || self.careEvidence == '')
        { value.reason = 'infection-day-care-evidence'; return value; }
        if (patient.medicalSupervision != self.practice)
        { value.reason = 'infection-physician-assignment'; return value; }
        if (self.practice != nil)
        {
            if (!self.practice.ofKind(RpgExpandedMedicalPractice) || !holds(self.practice.patients,patient))
                rpgExpandedReject('infection-physician-roster');
            if (!self.continuousCare || patient.medicalAdmittedAt == nil || patient.medicalAdmittedAt > due - 86400)
            { value.reason = 'infection-physician-care-interval'; return value; }
            local supervision = self.practice.assess();
            if (supervision.status != 'ready') { value.reason = supervision.reason; return value; }
            value.physicianBonus = 1;
        }
        if (self.exposure.lockedInjury < 0 || self.exposure.lockedInjury > patient.diseaseInjury
            || patient.diseaseInjury > patient.injury) rpgExpandedReject('infection-injury-balance');
        local conditions = new RpgExpandedInfectionContext(); conditions.infectedMatter = self.exposure.infectedMatter;
        conditions.specialLocale = self.exposure.specialLocale; conditions.antibiotics = self.antibiotics;
        conditions.medicalTL = self.medicalTL;
        local assessment = conditions.assessTypicalProgression();
        if (assessment.status != 'ready') { value.reason = assessment.reason; return value; }
        value.context = new RpgLiteContext(); value.context.attribute = rpgHT;
        value.context.kind = 'disease'; value.context.modifier = assessment.modifier + value.physicianBonus;
        local score = rpgLiteScore(patient,value.context);
        if (score == nil || score < 3) { value.reason = 'infection-resistance-score-unavailable'; return value; }
        value.failureWound = new RpgExpandedWound(); value.failureWound.profile = patient;
        value.failureWound.id = 'infection-' + self.exposure.sourceId() + '-' + self.id;
        value.failureWound.amount = 1; value.failureWound.dropDestination = self.dropDestination;
        local failure = value.failureWound.assess();
        if (failure.status != 'ready') { value.reason = failure.reason; return value; }
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        local patient = self.exposure.patient();
        value.check = rpgLiteCheck(patient,value.context);
        if (value.check.achieved)
        {
            self.exposure.ended = true; value.ended = true; value.failureWound = nil;
            patient.diseaseInjury -= self.exposure.lockedInjury; self.exposure.lockedInjury = 0;
        }
        else
        {
            local harm = value.failureWound.apply();
            if (harm.status != 'resolved') rpgExpandedReject('infection-injury-commit-changed');
            value.injury = harm.health.injury; patient.diseaseInjury += value.injury;
            self.exposure.lockedInjury += value.injury;
        }
        self.boundPractice = self.practice; self.boundContinuousCare = self.continuousCare;
        self.boundId = self.id; self.boundExposure = self.exposure; self.boundAntibiotics = self.antibiotics;
        self.boundMedicalTL = self.medicalTL; self.boundEvidence = self.careEvidence; self.boundDestination = self.dropDestination;
        self.ordinal = self.exposure.days.length() + 1; self.completedAt = rpgLedger.seconds;
        self.exposure.days = self.exposure.days + [self]; value.status = 'resolved'; self.result = value;
        return value;
    }
;


/** B443 grants specific hidden immunity only on the first resistance attempt. */
rpgExpandedNaturalDiseaseImmunity(roll)
{
    rpgInteger(roll,3,18); return roll == 3 || roll == 4;
}

class RpgExpandedDiseaseResistance: object
    diseaseId = nil
    profile = nil
    firstExposure = nil
    firstRoll = 0
    immune = nil
;

modify RpgExpandedProfile
    diseaseResistances = []
    diseaseResistance(id)
    {
        foreach (local record in self.diseaseResistances)
            if (record.diseaseId == id) return record;
        return nil;
    }
    validateFeatures()
    {
        inherited(); local ids = [];
        foreach (local record in self.diseaseResistances)
        {
            if (record == nil || !record.ofKind(RpgExpandedDiseaseResistance) || record.profile != self
                || record.diseaseId == nil || record.diseaseId == '' || holds(ids,record.diseaseId)
                || record.firstExposure == nil || record.firstExposure.result == nil
                || record.firstExposure.patient() != self || record.firstExposure.diseaseId != record.diseaseId
                || !record.firstExposure.ownsSource()
                || record.firstExposure.result.check == nil || record.firstExposure.result.check.roll != record.firstRoll
                || record.immune != rpgExpandedNaturalDiseaseImmunity(record.firstRoll))
                rpgExpandedReject('disease-resistance-history');
            ids = ids + [record.diseaseId];
        }
        return nil;
    }
;

class RpgExpandedAgingSchedule: RpgExpandedResult
    maturityYears = 0
    bands = []
;

/** Exact shortened-lifespan rows (B154), or extended normal ages (B53/B444).
 * Each band is [starting age in years, interval unit, interval count]. */
rpgExpandedAgingSchedule(shortLevels, extendedLevels)
{
    rpgInteger(shortLevels,0,4); rpgInteger(extendedLevels,0,10);
    local value = new RpgExpandedAgingSchedule();
    if (shortLevels > 0 && extendedLevels > 0)
    { value.reason = 'aging-conflicting-lifespan'; return value; }
    local rows = [
        [18,[[50,'year',1],[70,'month',6],[90,'month',3]]],
        [9,[[25,'month',6],[35,'month',3],[45,'day',45]]],
        [4,[[12,'month',3],[17,'day',45],[22,'day',22]]],
        [2,[[6,'day',45],[8,'day',22],[11,'day',11]]],
        [1,[[3,'day',22],[4,'day',11],[5,'day',5]]]
    ];
    local row = rows[shortLevels + 1]; local multiple = 1;
    for (local index = 0; index < extendedLevels; index += 1) multiple *= 2;
    value.maturityYears = row[1] * multiple;
    foreach (local band in row[2]) value.bands = value.bands + [[band[1] * multiple,band[2],band[3] * multiple]];
    value.status = 'ready'; return value;
}

/** World medical technology and one selected fitness modifier, B444. */
rpgExpandedAgingModifier(medicalTL, fitness)
{
    rpgInteger(medicalTL,0,1000); rpgInteger(fitness,-2,2);
    return medicalTL - 3 + fitness;
}

class RpgExpandedAgingLoss: RpgExpandedResult
    score = 0
    roll = 0
    loss = 0
;

/** Pure loss for one attribute. Does not spend points or change characteristics. */
rpgExpandedAgingLoss(score, roll, longevity)
{
    rpgInteger(score,-1000,1000); rpgInteger(roll,3,18);
    local value = new RpgExpandedAgingLoss(); value.score = score; value.roll = roll;
    if (longevity) value.loss = roll == 18 || roll == 17 && score < 17 ? 1 : 0;
    else
    {
        if (score < 3) { value.reason = 'aging-low-score-unavailable'; return value; }
        local check = rpgCheck(score,roll);
        value.loss = roll >= 17 || check.critical == 'failure' ? 2 : check.achieved ? 0 : 1;
    }
    value.status = 'ready'; return value;
}

class RpgExpandedAgingSequence: RpgExpandedResult
    scoresBefore = []
    scoresAfter = []
    losses = []
    rolls = []
    pointLoss = 0
    naturalDeath = nil
    healthCapacity = 0
    fatigueCapacity = 0
    will = 0
    perception = 0
    speedQuarters = 0
    move = 0
;

/** Four supplied aging rolls in ST, DX, IQ, HT order. B444. No mutation or luck. */
rpgExpandedAgingSequence(profile, medicalTL, fitness, longevity, rolls)
{
    if (profile == nil || !profile.ofKind(RpgExpandedProfile) || rolls == nil || rolls.length() != 4)
        rpgExpandedReject('aging-sequence-definition');
    local value = new RpgExpandedAgingSequence();
    value.scoresBefore = [profile.st,profile.dx,profile.iq,profile.ht];
    foreach (local score in value.scoresBefore) rpgInteger(score,1,1000);
    foreach (local roll in rolls) rpgInteger(roll,3,18);
    if (profile.dead) { value.reason = 'aging-patient-dead'; return value; }
    local target = profile.ht + rpgExpandedAgingModifier(medicalTL,fitness);
    rpgInteger(target,-1000,1000); local prices = [10,20,20,10];
    for (local index = 1; index <= 4; index += 1)
    {
        local outcome = rpgExpandedAgingLoss(target,rolls[index],longevity);
        if (outcome.status != 'ready') { value.reason = outcome.reason; return value; }
        local loss = outcome.loss;
        if (loss > value.scoresBefore[index]) loss = value.scoresBefore[index];
        local after = value.scoresBefore[index] - loss;
        value.scoresAfter = value.scoresAfter + [after]; value.losses = value.losses + [loss];
        value.pointLoss += loss * prices[index]; if (after == 0) value.naturalDeath = true;
    }
    value.rolls = rolls;
    value.healthCapacity = value.scoresAfter[1] + profile.hpAdjustment;
    value.fatigueCapacity = value.scoresAfter[4] + profile.fpAdjustment;
    value.will = value.scoresAfter[3] + profile.willAdjustment;
    value.perception = value.scoresAfter[3] + profile.perceptionAdjustment;
    value.speedQuarters = value.scoresAfter[2] + value.scoresAfter[4] + profile.speedQuarterAdjustment;
    value.move = value.speedQuarters / 4 + profile.moveAdjustment;
    value.status = 'ready'; return value;
}

modify RpgExpandedProfile
    agingHistory = []
    rejuvenations = []
;

/** An authored calendar boundary, with four owned rolls and retained losses. */
class RpgExpandedAgingEvent: object
    era = 0
    boundEra = 0
    restoredBy = nil
    profile = nil
    calendarId = nil
    boundaryId = nil
    ageYears = 0
    ordinal = 0
    reached = nil
    evidence = nil
    medicalTL = 3
    boundProfile = nil
    boundCalendar = nil
    boundBoundary = nil
    boundAge = 0
    boundOrdinal = 0
    boundEvidence = nil
    boundMedicalTL = 0
    result = nil
    completedAt = nil
    fitnessModifier()
    {
        local count = 0; local amount = 0;
        foreach (local entry in [['very-fit',2],['fit',1],['unfit',-1],['very-unfit',-2]])
            if (self.profile.level(entry[1]) > 0) { count += 1; amount = entry[2]; }
        if (count > 1) rpgExpandedReject('aging-fitness-conflict');
        return amount;
    }
    assess()
    {
        local value = new RpgExpandedResult();
        if (self.profile == nil || !self.profile.ofKind(RpgExpandedProfile)) rpgExpandedReject('aging-profile');
        if (self.result != nil)
        {
            if (self.era != self.boundEra || self.profile != self.boundProfile || self.calendarId != self.boundCalendar
                || self.boundaryId != self.boundBoundary || self.ageYears != self.boundAge
                || self.ordinal != self.boundOrdinal || self.evidence != self.boundEvidence
                || self.medicalTL != self.boundMedicalTL || !self.reached || !holds(self.profile.agingHistory,self))
                rpgExpandedReject('aging-event-binding');
            value.status = 'reused'; return value;
        }
        if (self.calendarId == nil || self.calendarId == '' || self.boundaryId == nil || self.boundaryId == '')
            rpgExpandedReject('aging-calendar-definition');
        rpgInteger(self.ageYears,0,1000000); rpgInteger(self.ordinal,1,1000000);
        if (!self.reached || self.evidence == nil || self.evidence == '')
        { value.reason = 'aging-calendar-evidence'; return value; }
        if (self.ordinal != self.profile.agingHistory.length() + 1) rpgExpandedReject('aging-calendar-order');
        foreach (local prior in self.profile.agingHistory)
        {
            if (prior.calendarId != self.calendarId || prior.boundaryId == self.boundaryId
                || prior.era == self.profile.rejuvenations.length() && prior.ageYears > self.ageYears) rpgExpandedReject('aging-calendar-history');
        }
        if (self.profile.level('unaging') > 0) { value.reason = 'aging-exempt'; return value; }
        local schedule = rpgExpandedAgingSchedule(self.profile.level('short-lifespan'),self.profile.level('extended-lifespan'));
        if (schedule.status != 'ready') { value.reason = schedule.reason; return value; }
        if (self.ageYears < schedule.bands[1][1]) { value.reason = 'aging-before-onset'; return value; }
        local worst = rpgExpandedAgingSequence(self.profile,self.medicalTL,self.fitnessModifier(),
            self.profile.level('longevity') > 0,[18,18,18,18]);
        if (worst.status != 'ready') { value.reason = worst.reason; return value; }
        if (self.profile.hpAdjustment < 0 && worst.healthCapacity <= 0
            || self.profile.fpAdjustment < 0 && worst.fatigueCapacity <= 0
            || self.profile.willAdjustment < 0 && worst.will <= 0
            || self.profile.perceptionAdjustment < 0 && worst.perception <= 0
            || worst.speedQuarters < 0 || worst.move < 0)
        { value.reason = 'aging-derived-state-unavailable'; return value; }
        value.status = 'ready'; return value;
    }
    apply()
    {
        local prepared = self.assess(); if (prepared.status != 'ready') return prepared;
        local rolls = [];
        for (local index = 0; index < 4; index += 1) rolls = rolls + [rpgRandom.roll()];
        local value = rpgExpandedAgingSequence(self.profile,self.medicalTL,self.fitnessModifier(),
            self.profile.level('longevity') > 0,rolls);
        if (value.status != 'ready') rpgExpandedReject('aging-assessment-changed');
        self.profile.st = value.scoresAfter[1]; self.profile.dx = value.scoresAfter[2];
        self.profile.iq = value.scoresAfter[3]; self.profile.ht = value.scoresAfter[4];
        if (value.naturalDeath) self.profile.dead = true;
        self.era = self.profile.rejuvenations.length(); self.boundEra = self.era;
        self.boundProfile = self.profile; self.boundCalendar = self.calendarId; self.boundBoundary = self.boundaryId;
        self.boundAge = self.ageYears; self.boundOrdinal = self.ordinal; self.boundEvidence = self.evidence;
        self.boundMedicalTL = self.medicalTL; self.completedAt = rpgLedger.seconds;
        self.profile.agingHistory = self.profile.agingHistory + [self]; value.status = 'resolved'; self.result = value;
        return value;
    }
;

modify RpgExpandedProfile
    validateFeatures()
    {
        inherited(); local ordinal = 0; local boundaries = []; local calendar = nil; local age = 0; local era = 0;
        foreach (local entry in self.agingHistory)
        {
            ordinal += 1;
            if (entry == nil || !entry.ofKind(RpgExpandedAgingEvent) || entry.profile != self
                || entry.result == nil || entry.ordinal != ordinal || entry.completedAt == nil
                || entry.completedAt > rpgLedger.seconds || entry.era < era || entry.era > self.rejuvenations.length()
                || entry.era == era && entry.ageYears < age
                || holds(boundaries,entry.boundaryId) || calendar != nil && calendar != entry.calendarId
                || entry.assess().status != 'reused') rpgExpandedReject('aging-event-history');
            boundaries = boundaries + [entry.boundaryId]; calendar = entry.calendarId; age = entry.ageYears; era = entry.era;
        }
        return nil;
    }
;


class RpgExpandedRejuvenationResult: RpgExpandedResult
    restoredEvents = []
    gains = [0,0,0,0]
    pointGain = 0
;

/** Restore recorded aging losses after an authored youth-restoring effect. B444. */
class RpgExpandedRejuvenation: object
    id = nil
    profile = nil
    calendarId = nil
    oldAgeYears = 0
    newAgeYears = 0
    effectEvidence = nil
    boundId = nil
    boundProfile = nil
    boundCalendar = nil
    boundOldAge = 0
    boundNewAge = 0
    boundEvidence = nil
    completedAt = nil
    result = nil
    assess()
    {
        local value = new RpgExpandedRejuvenationResult();
        if (self.profile == nil || !self.profile.ofKind(RpgExpandedProfile)) rpgExpandedReject('rejuvenation-profile');
        if (self.result != nil)
        {
            if (self.id != self.boundId || self.profile != self.boundProfile || self.calendarId != self.boundCalendar
                || self.oldAgeYears != self.boundOldAge || self.newAgeYears != self.boundNewAge
                || self.effectEvidence != self.boundEvidence || !holds(self.profile.rejuvenations,self))
                rpgExpandedReject('rejuvenation-binding');
            foreach (local entry in self.result.restoredEvents)
                if (entry.restoredBy != self) rpgExpandedReject('rejuvenation-receipt-owner');
            value.status = 'reused'; value.gains = self.result.gains; value.pointGain = self.result.pointGain;
            value.restoredEvents = self.result.restoredEvents; return value;
        }
        if (self.id == nil || self.id == '' || self.calendarId == nil || self.calendarId == '')
            rpgExpandedReject('rejuvenation-definition');
        foreach (local prior in self.profile.rejuvenations)
            if (prior.id == self.id) rpgExpandedReject('rejuvenation-duplicate');
        rpgInteger(self.oldAgeYears,0,1000000); rpgInteger(self.newAgeYears,0,1000000);
        if (self.newAgeYears >= self.oldAgeYears) rpgExpandedReject('rejuvenation-age-range');
        if (self.profile.dead) { value.reason = 'rejuvenation-resurrection-unavailable'; return value; }
        if (self.effectEvidence == nil || self.effectEvidence == '')
        { value.reason = 'rejuvenation-effect-evidence'; return value; }
        local gains = [0,0,0,0];
        foreach (local entry in self.profile.agingHistory)
        {
            if (entry.calendarId != self.calendarId || entry.result == nil) rpgExpandedReject('rejuvenation-calendar');
            if (entry.restoredBy == nil)
            {
                if (entry.ageYears > self.oldAgeYears) rpgExpandedReject('rejuvenation-unaccounted-age');
                if (entry.ageYears == self.newAgeYears)
                { value.reason = 'rejuvenation-partial-year-unavailable'; return value; }
                if (entry.ageYears > self.newAgeYears)
                {
                    value.restoredEvents = value.restoredEvents + [entry];
                    gains = [gains[1] + entry.result.losses[1],gains[2] + entry.result.losses[2],
                        gains[3] + entry.result.losses[3],gains[4] + entry.result.losses[4]];
                    value.pointGain += entry.result.pointLoss;
                }
            }
        }
        foreach (local score in [self.profile.st + gains[1],self.profile.dx + gains[2],
            self.profile.iq + gains[3],self.profile.ht + gains[4]]) rpgInteger(score,1,1000);
        value.gains = gains; value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        self.profile.st += value.gains[1]; self.profile.dx += value.gains[2];
        self.profile.iq += value.gains[3]; self.profile.ht += value.gains[4];
        foreach (local entry in value.restoredEvents) entry.restoredBy = self;
        self.boundId = self.id; self.boundProfile = self.profile; self.boundCalendar = self.calendarId;
        self.boundOldAge = self.oldAgeYears; self.boundNewAge = self.newAgeYears; self.boundEvidence = self.effectEvidence;
        self.completedAt = rpgLedger.seconds; self.profile.rejuvenations = self.profile.rejuvenations + [self];
        value.status = 'resolved'; self.result = value; return value;
    }
;

modify RpgExpandedProfile
    validateFeatures()
    {
        inherited(); local ids = [];
        foreach (local request in self.rejuvenations)
        {
            if (request == nil || !request.ofKind(RpgExpandedRejuvenation) || request.profile != self
                || request.result == nil || holds(ids,request.id) || request.completedAt == nil
                || request.completedAt > rpgLedger.seconds || request.assess().status != 'reused')
                rpgExpandedReject('rejuvenation-history');
            ids = ids + [request.id];
        }
        foreach (local entry in self.agingHistory)
            if (entry.restoredBy != nil && (!holds(self.rejuvenations,entry.restoredBy)
                || !holds(entry.restoredBy.result.restoredEvents,entry)))
                rpgExpandedReject('rejuvenation-loss-owner');
        return nil;
    }
;

class RpgExpandedColdAssessment: RpgExpandedResult
    checkRequired = nil
    intervalSeconds = 0
    failureFatigue = 0
    context = nil
    score = nil
;

/** Ambient cold table, full-2008 B430. Temperature is authored effective F. */
rpgExpandedColdWeather(effectiveF, windMph, clothing, wet, lowerComfortF)
{
    rpgInteger(effectiveF,-1000,1000); rpgInteger(windMph,0,1000); rpgInteger(lowerComfortF,-1000,1000);
    if (!holds(['light','winter','arctic','heated'],clothing)) rpgExpandedReject('cold-clothing');
    local value = new RpgExpandedColdAssessment(); value.status = 'ready';
    if (effectiveF >= lowerComfortF) return value;
    value.checkRequired = true; value.intervalSeconds = windMph >= 30 ? 600 : windMph >= 10 ? 900 : 1800;
    value.modifier = clothing == 'light' ? -5 : clothing == 'arctic' ? 5 : clothing == 'heated' ? 10 : 0;
    if (wet) value.modifier -= 5;
    if (effectiveF < 0) value.modifier -= -effectiveF / 10;
    value.failureFatigue = 1; return value;
}

/** Compare HT and HT-based trained arctic survival without drawing dice. */
class RpgExpandedColdContext: object
    profile = nil
    effectiveF = 34
    windMph = 0
    clothing = 'winter'
    wet = nil
    lowerComfortF = 35
    temperatureEvidence = nil
    survival = nil
    assess()
    {
        if (self.profile == nil || !self.profile.ofKind(RpgExpandedProfile)) rpgExpandedReject('cold-profile');
        local value = rpgExpandedColdWeather(self.effectiveF,self.windMph,self.clothing,self.wet,self.lowerComfortF);
        if (self.temperatureEvidence == nil || self.temperatureEvidence == '')
        { value.status = 'blocked'; value.reason = 'cold-temperature-evidence'; return value; }
        if (self.profile.dead) { value.status = 'blocked'; value.reason = 'cold-patient-dead'; return value; }
        if (!value.checkRequired) return value;
        value.context = new RpgLiteContext(); value.context.attribute = rpgHT;
        value.context.kind = 'temperature'; value.context.modifier = value.modifier;
        value.score = rpgLiteScore(self.profile,value.context);
        if (self.survival != nil)
        {
            if (!self.survival.ofKind(RpgExpandedSkill) || self.survival.id != 'survival'
                || self.survival.specialty != 'arctic' || self.survival.attribute != rpgPerception
                || self.survival.difficulty != 1) rpgExpandedReject('cold-survival-definition');
            local alternate = new RpgExpandedSkillContext(); alternate.skill = self.survival;
            alternate.rollAttribute = rpgHT; alternate.kind = 'temperature'; alternate.modifier = value.modifier;
            local score = rpgLiteScore(self.profile,alternate);
            if (score != nil && (value.score == nil || score > value.score))
            { value.score = score; value.context = alternate; }
        }
        if (value.score == nil || value.score < 3)
        { value.status = 'blocked'; value.reason = 'cold-resistance-score-unavailable'; }
        return value;
    }
;

modify RpgExpandedProfile
    coldExposure = nil
    coldHistory = []
;

/** One period of unchanged authored cold conditions. */
class RpgExpandedColdExposure: RpgExpandedColdContext
    id = nil
    startedAt = nil
    lastCheckAt = nil
    intervals = []
    lockedFatigue = 0
    lockedInjury = 0
    ended = nil
    endedAt = nil
    shelterEvidence = nil
    boundId = nil
    boundProfile = nil
    boundTemperature = 0
    boundWind = 0
    boundClothing = nil
    boundWet = nil
    boundComfort = 0
    boundEvidence = nil
    boundSurvival = nil
    validateBinding()
    {
        if (self.id != self.boundId || self.profile != self.boundProfile || self.effectiveF != self.boundTemperature
            || self.windMph != self.boundWind || self.clothing != self.boundClothing || self.wet != self.boundWet
            || self.lowerComfortF != self.boundComfort || self.temperatureEvidence != self.boundEvidence
            || self.survival != self.boundSurvival || !holds(self.profile.coldHistory,self))
            rpgExpandedReject('cold-exposure-binding');
        return nil;
    }
    start()
    {
        if (self.startedAt != nil)
        {
            self.validateBinding(); local reused = new RpgExpandedResult(); reused.status = 'reused'; return reused;
        }
        local value = self.assess(); if (value.status != 'ready') return value;
        if (!value.checkRequired) { value.status = 'blocked'; value.reason = 'cold-exposure-not-required'; return value; }
        if (self.id == nil || self.id == '') rpgExpandedReject('cold-exposure-id');
        if (self.profile.coldExposure != nil || self.profile.immersion != nil) { value.status = 'blocked'; value.reason = 'cold-exposure-active'; return value; }
        foreach (local prior in self.profile.coldHistory)
            if (prior.id == self.id) rpgExpandedReject('cold-exposure-duplicate');
        self.boundId = self.id; self.boundProfile = self.profile; self.boundTemperature = self.effectiveF;
        self.boundWind = self.windMph; self.boundClothing = self.clothing; self.boundWet = self.wet;
        self.boundComfort = self.lowerComfortF; self.boundEvidence = self.temperatureEvidence; self.boundSurvival = self.survival;
        self.startedAt = rpgLedger.seconds; self.lastCheckAt = self.startedAt;
        self.profile.coldHistory = self.profile.coldHistory + [self]; self.profile.coldExposure = self;
        value.status = 'resolved'; return value;
    }
    finish(shelter, heatSource, evidence)
    {
        local value = new RpgExpandedResult();
        if (self.startedAt == nil) { value.reason = 'cold-exposure-not-started'; return value; }
        self.validateBinding();
        if (self.ended) { value.status = 'reused'; return value; }
        if (!shelter || !heatSource || evidence == nil || evidence == '')
        { value.reason = 'cold-recovery-shelter-and-heat'; return value; }
        local conditions = rpgExpandedColdWeather(self.effectiveF,self.windMph,self.clothing,self.wet,self.lowerComfortF);
        if (rpgLedger.seconds >= self.lastCheckAt + conditions.intervalSeconds)
        { value.reason = 'cold-unresolved-interval'; return value; }
        if (self.profile.coldExposure != self || self.lockedFatigue > self.profile.temperatureFatigue
            || self.lockedInjury > self.profile.temperatureInjury) rpgExpandedReject('cold-exposure-balance');
        self.profile.temperatureFatigue -= self.lockedFatigue; self.profile.temperatureInjury -= self.lockedInjury;
        self.lockedFatigue = 0; self.lockedInjury = 0; self.ended = true; self.endedAt = rpgLedger.seconds; self.shelterEvidence = evidence;
        self.profile.coldExposure = nil; value.status = 'resolved'; return value;
    }
;

class RpgExpandedColdIntervalResult: RpgExpandedResult
    fatigue = 0
    injury = 0
    failureWound = nil
;

class RpgExpandedColdInterval: object
    id = nil
    exposure = nil
    dropDestination = nil
    boundDestination = nil
    boundId = nil
    boundExposure = nil
    completedAt = nil
    result = nil
    assess()
    {
        local value = new RpgExpandedColdIntervalResult();
        if (self.exposure == nil || !self.exposure.ofKind(RpgExpandedColdExposure)) rpgExpandedReject('cold-interval-exposure');
        if (self.exposure.startedAt == nil) { value.reason = 'cold-exposure-not-started'; return value; }
        self.exposure.validateBinding();
        if (self.result != nil)
        {
            if (self.dropDestination != self.boundDestination || self.id != self.boundId || self.exposure != self.boundExposure || !holds(self.exposure.intervals,self))
                rpgExpandedReject('cold-interval-binding');
            value.status = 'reused'; value.check = self.result.check; value.fatigue = self.result.fatigue;
            value.injury = self.result.injury; value.failureWound = self.result.failureWound; return value;
        }
        if (self.id == nil || self.id == '') rpgExpandedReject('cold-interval-id');
        foreach (local prior in self.exposure.intervals)
            if (prior.id == self.id) rpgExpandedReject('cold-interval-duplicate');
        if (self.exposure.ended || self.exposure.profile.coldExposure != self.exposure)
        { value.reason = 'cold-exposure-not-active'; return value; }
        local assessment = self.exposure.assess();
        if (assessment.status != 'ready') { value.reason = assessment.reason; return value; }
        local due = self.exposure.lastCheckAt + assessment.intervalSeconds;
        if (rpgLedger.seconds != due)
        { value.reason = rpgLedger.seconds < due ? 'cold-interval-not-due' : 'cold-missed-boundary'; return value; }
        if (self.exposure.profile.fp() <= 0)
        {
            value.failureWound = new RpgExpandedWound(); value.failureWound.profile = self.exposure.profile;
            value.failureWound.id = 'cold-' + self.exposure.id + '-' + self.id; value.failureWound.amount = 1;
            value.failureWound.dropDestination = self.dropDestination;
            local failure = value.failureWound.assess();
            if (failure.status != 'ready') { value.reason = failure.reason; return value; }
        }
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        local assessment = self.exposure.assess();
        value.check = rpgLiteCheck(self.exposure.profile,assessment.context);
        if (!value.check.achieved)
        {
            local patient = self.exposure.profile;
            if (value.failureWound != nil)
            {
                local harm = value.failureWound.apply();
                if (harm.status != 'resolved') rpgExpandedReject('cold-injury-commit-changed');
                value.injury = harm.health.injury;
            }
            value.fatigue = rpgLiteFatigueIncrement(patient,'temperature');
            if (patient.fp() <= -patient.maxEnergy) { patient.becomeUnconscious(); patient.fatigueCollapse = true; }
            patient.temperatureFatigue += value.fatigue; self.exposure.lockedFatigue += value.fatigue;
            patient.temperatureInjury += value.injury; self.exposure.lockedInjury += value.injury;
        }
        else value.failureWound = nil;
        self.boundDestination = self.dropDestination;
        self.boundId = self.id; self.boundExposure = self.exposure; self.completedAt = rpgLedger.seconds;
        self.exposure.lastCheckAt = self.completedAt; self.exposure.intervals = self.exposure.intervals + [self];
        value.status = 'resolved'; self.result = value; return value;
    }
;

modify RpgExpandedProfile
    validateFeatures()
    {
        inherited(); local ids = []; local active = nil; local locked = 0; local lockedInjury = 0;
        foreach (local exposure in self.coldHistory)
        {
            if (exposure == nil || !exposure.ofKind(RpgExpandedColdExposure) || exposure.profile != self
                || holds(ids,exposure.id) || exposure.startedAt == nil || exposure.startedAt > rpgLedger.seconds)
                rpgExpandedReject('cold-exposure-history');
            exposure.validateBinding(); ids = ids + [exposure.id];
            local lastTime = exposure.startedAt; local fatigue = 0; local injury = 0; local intervals = [];
            local table = rpgExpandedColdWeather(exposure.effectiveF,exposure.windMph,exposure.clothing,exposure.wet,exposure.lowerComfortF);
            foreach (local interval in exposure.intervals)
            {
                if (interval == nil || !interval.ofKind(RpgExpandedColdInterval) || interval.exposure != exposure
                    || interval.result == nil || holds(intervals,interval.id)
                    || interval.completedAt != lastTime + table.intervalSeconds || interval.completedAt > rpgLedger.seconds
                    || interval.assess().status != 'reused') rpgExpandedReject('cold-interval-history');
                intervals = intervals + [interval.id]; lastTime = interval.completedAt; fatigue += interval.result.fatigue; injury += interval.result.injury;
            }
            if (exposure.lastCheckAt != lastTime || exposure.lockedFatigue != (exposure.ended ? 0 : fatigue)
                || exposure.lockedInjury != (exposure.ended ? 0 : injury))
                rpgExpandedReject('cold-fatigue-history');
            if (!exposure.ended)
            {
                if (active != nil) rpgExpandedReject('cold-multiple-exposures');
                active = exposure; locked += exposure.lockedFatigue; lockedInjury += exposure.lockedInjury;
            }
            else if (exposure.endedAt == nil || exposure.endedAt < lastTime || exposure.endedAt > rpgLedger.seconds
                || exposure.shelterEvidence == nil) rpgExpandedReject('cold-shelter-history');
        }
        if (self.coldExposure != active || locked > self.temperatureFatigue || lockedInjury > self.temperatureInjury) rpgExpandedReject('cold-active-history');
        return nil;
    }
;

class RpgExpandedHeatExertion: RpgExpandedResult
    extraFatigue = 0
;

/** Printed exertion/dehydration heat bands, full-2008 B434. */
rpgExpandedHeatExertion(effectiveF, upperComfortF)
{
    rpgInteger(effectiveF,-1000,1000); rpgInteger(upperComfortF,-1000,1000);
    local value = new RpgExpandedHeatExertion(); local excess = effectiveF - upperComfortF;
    if (excess > 60) { value.reason = 'heat-exertion-band-unavailable'; return value; }
    value.extraFatigue = excess <= 0 ? 0 : excess <= 30 ? 1 : 2;
    value.status = 'ready'; return value;
}

class RpgExpandedHeatOutcome: RpgExpandedResult
    fatigue = 0
    heatStroke = nil
;

/** Supplied check and optional heat-stroke die. No random draw or spending. */
rpgExpandedHeatOutcome(score, roll, strokeDie)
{
    rpgInteger(score,3,1000); local value = new RpgExpandedHeatOutcome(); value.check = rpgCheck(score,roll);
    if (!value.check.achieved)
    {
        value.heatStroke = value.check.critical == 'failure';
        if (value.heatStroke) { rpgInteger(strokeDie,1,6); value.fatigue = strokeDie; }
        else value.fatigue = 1;
    }
    value.status = 'ready'; return value;
}

class RpgExpandedThermalShockAssessment: RpgExpandedResult
    ordinaryCold = nil
    intervalSeconds = 0
    fatigue = 0
;

/** Icy immersion must be established by the author; full-2008 B430. */
rpgExpandedThermalShock(drySuit, score, roll)
{
    local value = new RpgExpandedThermalShockAssessment();
    if (drySuit)
    {
        value.ordinaryCold = true; value.status = 'ready'; return value;
    }
    rpgInteger(score,3,1000); value.intervalSeconds = 60;
    value.check = rpgCheck(score,roll);
    if (value.check.achieved) value.fatigue = 1;
    else
    {
        if (value.check.margin >= 0)
        { value.reason = 'thermal-shock-forced-failure-margin'; return value; }
        value.fatigue = -value.check.margin;
    }
    value.status = 'ready'; return value;
}

modify RpgExpandedProfile
    immersion = nil
    immersionHistory = []
;

/** Author establishes icy immersion and handles breathing independently. */
class RpgExpandedImmersion: object
    id = nil
    profile = nil
    evidence = nil
    startedAt = nil
    lastCheckAt = nil
    exitedAt = nil
    exitEvidence = nil
    warmedAt = nil
    warmthEvidence = nil
    lockedFatigue = 0
    lockedInjury = 0
    intervals = []
    boundId = nil
    boundProfile = nil
    boundEvidence = nil
    validateBinding()
    {
        if (self.id != self.boundId || self.profile != self.boundProfile || self.evidence != self.boundEvidence
            || !holds(self.profile.immersionHistory,self)) rpgExpandedReject('immersion-binding');
        return nil;
    }
    start()
    {
        local value = new RpgExpandedResult();
        if (self.startedAt != nil)
        { self.validateBinding(); value.status = 'reused'; return value; }
        if (self.profile == nil || !self.profile.ofKind(RpgExpandedProfile)) rpgExpandedReject('immersion-profile');
        if (self.id == nil || self.id == '') rpgExpandedReject('immersion-id');
        if (self.evidence == nil || self.evidence == '')
        { value.reason = 'immersion-evidence'; return value; }
        if (self.profile.dead) { value.reason = 'immersion-patient-dead'; return value; }
        if (self.profile.immersion != nil || self.profile.coldExposure != nil)
        { value.reason = 'immersion-exposure-active'; return value; }
        foreach (local prior in self.profile.immersionHistory)
            if (prior.id == self.id) rpgExpandedReject('immersion-duplicate');
        self.boundId = self.id; self.boundProfile = self.profile; self.boundEvidence = self.evidence;
        self.startedAt = rpgLedger.seconds; self.lastCheckAt = self.startedAt;
        self.profile.immersionHistory = self.profile.immersionHistory + [self]; self.profile.immersion = self;
        value.status = 'resolved'; return value;
    }
    leave(evidence)
    {
        local value = new RpgExpandedResult();
        if (self.startedAt == nil) { value.reason = 'immersion-not-started'; return value; }
        self.validateBinding();
        if (self.exitedAt != nil) { value.status = 'reused'; return value; }
        if (evidence == nil || evidence == '') { value.reason = 'immersion-exit-evidence'; return value; }
        if (rpgLedger.seconds >= self.lastCheckAt + 60)
        { value.reason = 'immersion-unresolved-interval'; return value; }
        if (self.profile.immersion != self) rpgExpandedReject('immersion-owner');
        self.exitedAt = rpgLedger.seconds; self.exitEvidence = evidence; self.profile.immersion = nil;
        value.status = 'resolved'; return value;
    }
    warm(shelter, heatSource, evidence)
    {
        local value = new RpgExpandedResult();
        if (self.startedAt == nil) { value.reason = 'immersion-not-started'; return value; }
        self.validateBinding();
        if (self.warmedAt != nil) { value.status = 'reused'; return value; }
        if (self.exitedAt == nil) { value.reason = 'immersion-not-exited'; return value; }
        if (!shelter || !heatSource || evidence == nil || evidence == '')
        { value.reason = 'immersion-recovery-shelter-and-heat'; return value; }
        if (self.lockedFatigue > self.profile.temperatureFatigue || self.lockedInjury > self.profile.temperatureInjury)
            rpgExpandedReject('immersion-balance');
        self.profile.temperatureFatigue -= self.lockedFatigue; self.lockedFatigue = 0;
        self.profile.temperatureInjury -= self.lockedInjury; self.lockedInjury = 0;
        self.warmedAt = rpgLedger.seconds; self.warmthEvidence = evidence;
        value.status = 'resolved'; return value;
    }
;

class RpgExpandedImmersionResult: RpgExpandedResult
    context = nil
    score = nil
    fatigue = 0
    requestedFatigue = 0
    injury = 0
    wounds = []
;

class RpgExpandedImmersionInterval: object
    id = nil
    exposure = nil
    completedAt = nil
    result = nil
    boundId = nil
    boundExposure = nil
    dropDestination = nil
    boundDestination = nil
    assess()
    {
        local value = new RpgExpandedImmersionResult();
        if (self.exposure == nil || !self.exposure.ofKind(RpgExpandedImmersion)) rpgExpandedReject('immersion-interval-exposure');
        if (self.exposure.startedAt == nil) { value.reason = 'immersion-not-started'; return value; }
        self.exposure.validateBinding();
        if (self.result != nil)
        {
            if (self.id != self.boundId || self.exposure != self.boundExposure || self.dropDestination != self.boundDestination
                || !holds(self.exposure.intervals,self))
                rpgExpandedReject('immersion-interval-binding');
            value.status = 'reused'; value.check = self.result.check; value.fatigue = self.result.fatigue;
            value.requestedFatigue = self.result.requestedFatigue; value.injury = self.result.injury;
            value.wounds = self.result.wounds; return value;
        }
        if (self.id == nil || self.id == '') rpgExpandedReject('immersion-interval-id');
        foreach (local prior in self.exposure.intervals)
            if (prior.id == self.id) rpgExpandedReject('immersion-interval-duplicate');
        if (self.exposure.exitedAt != nil || self.exposure.profile.immersion != self.exposure)
        { value.reason = 'immersion-not-active'; return value; }
        local patient = self.exposure.profile;
        if (patient.dead) { value.reason = 'immersion-patient-dead'; return value; }
        local due = self.exposure.lastCheckAt + 60;
        if (rpgLedger.seconds != due)
        { value.reason = rpgLedger.seconds < due ? 'immersion-interval-not-due' : 'immersion-missed-boundary'; return value; }
        value.context = new RpgLiteContext(); value.context.attribute = rpgHT; value.context.kind = 'temperature';
        value.score = rpgLiteScore(patient,value.context);
        if (value.score == nil || value.score < 3)
        { value.reason = 'immersion-resistance-unavailable'; return value; }
        if (value.score >= 17)
        { value.reason = 'thermal-shock-forced-failure-margin'; return value; }
        /* Every possible result must be supported before consuming randomness. */
        local maximum = 18 - value.score;
        local overflow = maximum - (patient.fp() > 0 ? patient.fp() : 0);
        if (overflow > 0)
        {
            if (patient.ht < 3 && patient.hp() - overflow <= -patient.maxHP)
            { value.reason = 'expanded-survival-score-unavailable'; return value; }
            local suffixes = ['01','02','03','04','05','06','07','08','09','10','11','12','13','14','15'];
            for (local index = 1; index <= overflow; index += 1)
            {
                local wound = new RpgExpandedWound(); wound.profile = patient; wound.amount = 1;
                wound.id = 'immersion-' + self.exposure.id + '-' + self.id + '-' + suffixes[index];
                wound.dropDestination = self.dropDestination;
                local assessment = wound.assess();
                if (assessment.status != 'ready') { value.reason = assessment.reason; return value; }
                value.wounds = value.wounds + [wound];
            }
        }
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        value.check = rpgLiteCheck(self.exposure.profile,value.context);
        local outcome = rpgExpandedThermalShock(nil,value.score,value.check.roll);
        if (outcome.status != 'ready') rpgExpandedReject('immersion-outcome-changed');
        local remaining = outcome.fatigue; value.requestedFatigue = remaining;
        local patient = self.exposure.profile; local prepared = value.wounds; value.wounds = []; local index = 1;
        while (remaining > 0)
        {
            if (patient.fp() <= 0 && !patient.dead)
            {
                local wound = prepared[index]; index += 1; local harm = wound.apply();
                if (harm.status != 'resolved') rpgExpandedReject('immersion-injury-commit-changed');
                value.injury += harm.health.injury; value.wounds = value.wounds + [wound];
            }
            value.fatigue += rpgLiteFatigueIncrement(patient,'temperature'); remaining -= 1;
        }
        if (patient.fp() <= -patient.maxEnergy) { patient.becomeUnconscious(); patient.fatigueCollapse = true; }
        patient.temperatureFatigue += value.fatigue; self.exposure.lockedFatigue += value.fatigue;
        patient.temperatureInjury += value.injury; self.exposure.lockedInjury += value.injury;
        self.boundDestination = self.dropDestination;
        self.boundId = self.id; self.boundExposure = self.exposure; self.completedAt = rpgLedger.seconds;
        self.exposure.lastCheckAt = self.completedAt; self.exposure.intervals = self.exposure.intervals + [self];
        value.status = 'resolved'; self.result = value; return value;
    }
;

modify RpgExpandedProfile
    validateFeatures()
    {
        inherited(); local ids = []; local active = nil; local locked = 0; local lockedInjury = 0;
        foreach (local exposure in self.immersionHistory)
        {
            if (exposure == nil || !exposure.ofKind(RpgExpandedImmersion) || exposure.profile != self
                || holds(ids,exposure.id) || exposure.startedAt == nil || exposure.startedAt > rpgLedger.seconds)
                rpgExpandedReject('immersion-history');
            exposure.validateBinding(); ids = ids + [exposure.id];
            local lastTime = exposure.startedAt; local fatigue = 0; local injury = 0; local intervals = [];
            foreach (local interval in exposure.intervals)
            {
                if (interval == nil || !interval.ofKind(RpgExpandedImmersionInterval) || interval.exposure != exposure
                    || interval.result == nil || holds(intervals,interval.id)
                    || interval.completedAt != lastTime + 60 || interval.completedAt > rpgLedger.seconds
                    || interval.assess().status != 'reused') rpgExpandedReject('immersion-interval-history');
                local woundInjury = 0;
                foreach (local wound in interval.result.wounds)
                {
                    if (wound.profile != self || wound.assess().status != 'reused') rpgExpandedReject('immersion-wound-history');
                    woundInjury += wound.health.injury;
                }
                if (woundInjury != interval.result.injury) rpgExpandedReject('immersion-injury-history');
                intervals = intervals + [interval.id]; lastTime = interval.completedAt;
                fatigue += interval.result.fatigue; injury += interval.result.injury;
            }
            if (exposure.lastCheckAt != lastTime || exposure.lockedFatigue != (exposure.warmedAt == nil ? fatigue : 0)
                || exposure.lockedInjury != (exposure.warmedAt == nil ? injury : 0))
                rpgExpandedReject('immersion-fatigue-history');
            locked += exposure.lockedFatigue; lockedInjury += exposure.lockedInjury;
            if (exposure.exitedAt == nil)
            {
                if (active != nil || exposure.warmedAt != nil) rpgExpandedReject('immersion-active-history');
                active = exposure;
            }
            else if (exposure.exitedAt < lastTime || exposure.exitedAt >= lastTime + 60
                || exposure.exitedAt > rpgLedger.seconds || exposure.exitEvidence == nil)
                rpgExpandedReject('immersion-exit-history');
            if (exposure.warmedAt != nil && (exposure.warmedAt < exposure.exitedAt
                || exposure.warmedAt > rpgLedger.seconds || exposure.warmthEvidence == nil))
                rpgExpandedReject('immersion-warmth-history');
        }
        foreach (local cold in self.coldHistory) { locked += cold.lockedFatigue; lockedInjury += cold.lockedInjury; }
        if (self.immersion != active || locked > self.temperatureFatigue || lockedInjury > self.temperatureInjury || active != nil && self.coldExposure != nil)
            rpgExpandedReject('immersion-restriction-history');
        return nil;
    }
;

/** Lite climate has a global recovery reset; do not mix ownership models. */
modify RpgExpandedProfile
    validateClimateAdvance()
    {
        inherited();
        if (self.coldExposure != nil || self.immersion != nil)
            rpgExpandedReject('climate-expanded-exposure-active');
        foreach (local exposure in self.immersionHistory)
            if (exposure.lockedFatigue > 0 || exposure.lockedInjury > 0) rpgExpandedReject('climate-expanded-recovery-owned');
        return nil;
    }
;

modify RpgExpandedProfile
    airlessExposure = nil
    airlessHistory = []
;

class RpgExpandedAirlessResult: RpgExpandedResult
    fatigue = 0
    injury = 0
    wound = nil
    consciousness = nil
    brainCheck = nil
    intelligenceLoss = 0
;

/** Complete air deprivation with no remaining breath reserve, B436-B437. */
class RpgExpandedAirlessExposure: object
    id = nil
    profile = nil
    evidence = nil
    startedAt = nil
    lastSecondAt = nil
    seconds = []
    endedAt = nil
    airEvidence = nil
    result = nil
    boundId = nil
    boundProfile = nil
    boundEvidence = nil
    validateBinding()
    {
        if (self.id != self.boundId || self.profile != self.boundProfile || self.evidence != self.boundEvidence
            || !holds(self.profile.airlessHistory,self)) rpgExpandedReject('airless-binding');
        return nil;
    }
    start()
    {
        local value = new RpgExpandedResult();
        if (self.startedAt != nil) { self.validateBinding(); value.status = 'reused'; return value; }
        if (self.profile == nil || !self.profile.ofKind(RpgExpandedProfile)) rpgExpandedReject('airless-profile');
        if (self.id == nil || self.id == '') rpgExpandedReject('airless-id');
        if (self.evidence == nil || self.evidence == '') { value.reason = 'airless-exposure-evidence'; return value; }
        if (self.profile.dead) { value.reason = 'airless-patient-dead'; return value; }
        if (self.profile.airlessExposure != nil || self.profile.airClock != 0)
        { value.reason = 'airless-existing-exposure'; return value; }
        self.profile.validateSuffocation();
        foreach (local prior in self.profile.airlessHistory)
            if (prior.id == self.id) rpgExpandedReject('airless-duplicate');
        self.boundId = self.id; self.boundProfile = self.profile; self.boundEvidence = self.evidence;
        self.startedAt = rpgLedger.seconds; self.lastSecondAt = self.startedAt;
        self.profile.airlessExposure = self; self.profile.airlessHistory = self.profile.airlessHistory + [self];
        value.status = 'resolved'; return value;
    }
    assessAir(evidence)
    {
        local value = new RpgExpandedAirlessResult();
        if (self.startedAt == nil) { value.reason = 'airless-not-started'; return value; }
        self.validateBinding();
        if (self.result != nil)
        { value.status = 'reused'; value.brainCheck = self.result.brainCheck; value.intelligenceLoss = self.result.intelligenceLoss; return value; }
        if (evidence == nil || evidence == '') { value.reason = 'airless-clean-air-evidence'; return value; }
        if (self.profile.dead) { value.reason = 'airless-rescue-too-late'; return value; }
        if (rpgLedger.seconds != self.lastSecondAt) { value.reason = 'airless-unresolved-seconds'; return value; }
        if (self.profile.airlessExposure != self || self.profile.airClock != self.seconds.length())
            rpgExpandedReject('airless-clock-owner');
        if (self.profile.airClock > 120)
        {
            if (self.profile.iq <= 1 || self.profile.will <= 1 || self.profile.perception <= 1)
            { value.reason = 'airless-brain-loss-range'; return value; }
            local context = new RpgLiteContext(); context.attribute = rpgHT; context.kind = 'brain-injury';
            local score = rpgLiteScore(self.profile,context);
            if (score == nil || score < 3) { value.reason = 'airless-brain-check-unavailable'; return value; }
        }
        value.status = 'ready'; return value;
    }
    resumeAir(evidence)
    {
        local value = self.assessAir(evidence); if (value.status != 'ready') return value;
        if (self.profile.airClock > 120)
        {
            value.brainCheck = rpgLiteAttributeCheck(self.profile,rpgHT,'brain-injury',0);
            if (!value.brainCheck.achieved) { self.profile.iq -= 1; value.intelligenceLoss = 1; }
        }
        self.profile.airClock = 0; self.profile.airlessExposure = nil;
        self.endedAt = rpgLedger.seconds; self.airEvidence = evidence;
        value.status = 'resolved'; self.result = value; return value;
    }
;

class RpgExpandedAirlessSecond: object
    id = nil
    exposure = nil
    dropDestination = nil
    boundId = nil
    boundExposure = nil
    boundDestination = nil
    completedAt = nil
    result = nil
    assess()
    {
        local value = new RpgExpandedAirlessResult();
        if (self.exposure == nil || !self.exposure.ofKind(RpgExpandedAirlessExposure)) rpgExpandedReject('airless-second-exposure');
        if (self.exposure.startedAt == nil) { value.reason = 'airless-not-started'; return value; }
        self.exposure.validateBinding();
        if (self.result != nil)
        {
            if (self.id != self.boundId || self.exposure != self.boundExposure || self.dropDestination != self.boundDestination
                || !holds(self.exposure.seconds,self)) rpgExpandedReject('airless-second-binding');
            value.status = 'reused'; value.fatigue = self.result.fatigue; value.injury = self.result.injury;
            value.wound = self.result.wound; value.consciousness = self.result.consciousness; return value;
        }
        if (self.id == nil || self.id == '') rpgExpandedReject('airless-second-id');
        foreach (local prior in self.exposure.seconds)
            if (prior.id == self.id) rpgExpandedReject('airless-second-duplicate');
        local patient = self.exposure.profile;
        if (patient.airlessExposure != self.exposure || self.exposure.endedAt != nil)
        { value.reason = 'airless-not-active'; return value; }
        if (patient.dead) { value.reason = 'airless-patient-dead'; return value; }
        if (patient.airClock != self.exposure.seconds.length()) rpgExpandedReject('airless-clock-owner');
        local due = self.exposure.lastSecondAt + 1;
        if (rpgLedger.seconds != due)
        { value.reason = rpgLedger.seconds < due ? 'airless-second-not-due' : 'airless-missed-boundary'; return value; }
        if (patient.fp() <= 1 && !patient.unconscious)
        {
            local context = new RpgLiteContext(); context.attribute = rpgWill; context.kind = 'air';
            local score = rpgLiteScore(patient,context);
            if (score == nil || score < 3) { value.reason = 'airless-consciousness-unavailable'; return value; }
        }
        if (patient.fp() <= 0)
        {
            value.wound = new RpgExpandedWound(); value.wound.id = 'airless-' + self.exposure.id + '-' + self.id;
            value.wound.profile = patient; value.wound.amount = 1; value.wound.dropDestination = self.dropDestination;
            local harm = value.wound.assess();
            if (harm.status != 'ready') { value.reason = harm.reason; return value; }
        }
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        local patient = self.exposure.profile;
        if (value.wound != nil)
        {
            local harm = value.wound.apply();
            if (harm.status != 'resolved') rpgExpandedReject('airless-wound-commit-changed');
            value.injury = harm.health.injury;
        }
        value.fatigue = rpgLiteFatigueIncrement(patient,'air');
        if (patient.fp() <= -patient.maxEnergy) { patient.becomeUnconscious(); patient.fatigueCollapse = true; }
        if (patient.fp() <= 0 && !patient.unconscious && !patient.dead)
        {
            value.consciousness = rpgLiteAttributeCheck(patient,rpgWill,'air',0);
            if (!value.consciousness.achieved) { patient.becomeUnconscious(); patient.fatigueCollapse = true; }
        }
        patient.airClock += 1;
        if (patient.airClock >= 240) { patient.dead = true; patient.becomeUnconscious(); }
        self.boundId = self.id; self.boundExposure = self.exposure; self.boundDestination = self.dropDestination;
        self.completedAt = rpgLedger.seconds; self.exposure.lastSecondAt = self.completedAt;
        self.exposure.seconds = self.exposure.seconds + [self]; value.status = 'resolved'; self.result = value; return value;
    }
;

modify RpgExpandedProfile
    validateSuffocation()
    {
        inherited();
        if (self.airlessExposure != nil) rpgExpandedReject('suffocation-airless-exposure-owned');
        return nil;
    }
    validateNaturalRecovery(seconds, food, allowed)
    {
        inherited(seconds,food,allowed);
        if (self.airlessExposure != nil) rpgExpandedReject('airless-recovery-needs-air');
        return nil;
    }
    validateFeatures()
    {
        inherited(); local active = nil; local ids = [];
        foreach (local exposure in self.airlessHistory)
        {
            if (exposure == nil || !exposure.ofKind(RpgExpandedAirlessExposure) || exposure.profile != self
                || holds(ids,exposure.id) || exposure.startedAt == nil || exposure.startedAt > rpgLedger.seconds)
                rpgExpandedReject('airless-history');
            exposure.validateBinding(); ids = ids + [exposure.id]; local lastTime = exposure.startedAt; local seconds = [];
            foreach (local second in exposure.seconds)
            {
                if (second == nil || !second.ofKind(RpgExpandedAirlessSecond) || second.exposure != exposure
                    || holds(seconds,second.id) || second.result == nil || second.completedAt != lastTime + 1
                    || second.completedAt > rpgLedger.seconds || second.assess().status != 'reused')
                    rpgExpandedReject('airless-second-history');
                if (second.result.wound != nil && (second.result.wound.profile != self
                    || second.result.wound.assess().status != 'reused')) rpgExpandedReject('airless-wound-history');
                seconds = seconds + [second.id]; lastTime = second.completedAt;
            }
            if (exposure.lastSecondAt != lastTime || exposure.seconds.length() > 240) rpgExpandedReject('airless-time-history');
            if (exposure.endedAt == nil)
            {
                if (active != nil || exposure.result != nil) rpgExpandedReject('airless-active-history');
                active = exposure;
            }
            else if (exposure.endedAt != lastTime || exposure.result == nil || exposure.airEvidence == nil)
                rpgExpandedReject('airless-rescue-history');
        }
        if (self.airlessExposure != active || active != nil && self.airClock != active.seconds.length())
            rpgExpandedReject('airless-clock-history');
        return nil;
    }
;

modify RpgExpandedProfile
    validateBreathStart()
    {
        inherited();
        if (self.airlessExposure != nil) rpgExpandedReject('breath-airless-exposure-owned');
        return nil;
    }
;

/** Pure full-2008 B436 table lookup for whole-rad accumulated doses. The
 * supplied printing overlaps at 800: that value requires source resolution. */
rpgExpandedRadiationBand(rads)
{
    rpgInteger(rads,1,1000000);
    local value = new RpgExpandedRadiationResult();
    if (rads == 800) { value.reason = 'radiation-eight-hundred-overlap'; return value; }
    if (rads <= 10) { value.modifier = 0; value.effects = ['none','none','burns','blood']; }
    else if (rads <= 20) { value.modifier = 0; value.effects = ['none','burns','blood','digestive']; }
    else if (rads <= 799)
    {
        value.modifier = rads <= 40 ? 0 : rads <= 80 ? -1 : rads <= 160 ? -3 : -4;
        value.effects = ['burns','blood','digestive','terminal'];
    }
    else if (rads <= 4000) { value.modifier = -5; value.effects = ['digestive','terminal','acute-brain','acute-brain']; }
    else { value.modifier = -5; value.effects = ['terminal','acute-brain','acute-brain','acute-brain']; }
    value.status = 'ready'; return value;
}

/** Select a syndrome descriptor from a supplied HT roll; no symptoms committed. */
rpgExpandedRadiationOutcome(health, rads, modifier, roll)
{
    rpgInteger(health,1,1000); rpgInteger(modifier,-1000,1000); rpgInteger(roll,3,18);
    local value = rpgExpandedRadiationBand(rads); if (value.status != 'ready') return value;
    local score = health + modifier + value.modifier;
    if (score < 3) { value.status = 'blocked'; value.reason = 'radiation-score-unavailable'; return value; }
    value.check = rpgCheck(score,roll);
    local column = value.check.critical == 'success' ? 1 : value.check.critical == 'failure' ? 4
        : value.check.achieved ? 2 : 3;
    value.effect = value.effects[column]; return value;
}

/** Source-table descriptors, not an executed medical condition. */
class RpgExpandedRadiationResult: RpgExpandedResult
    effects = []
    effect = nil
;

/** B435 dose recovery. Whole elapsed days after day thirty reduce this dose
 * by ten rads/day; tenths retain the permanent tenth without rounding it away. */
rpgExpandedRadiationRemainingTenths(originalRads, elapsedDays)
{
    rpgInteger(originalRads,1,1000000); rpgInteger(elapsedDays,0,1000000);
    if (elapsedDays <= 30) return originalRads * 10;
    local remaining = originalRads * 10 - (elapsedDays - 30) * 100;
    return remaining < originalRads ? originalRads : remaining;
}

modify RpgExpandedProfile
    radiationDoses = []
;

/** One received exact dose, with its own recovery epoch and source identity.
 * Shielding, tolerance and syndrome resolution are separate pending operations. */
class RpgExpandedRadiationDose: object
    id = nil
    profile = nil
    source = nil
    rads = 0
    radDenominator = 1
    approved = nil
    evidence = nil
    receivedAt = nil
    boundDefinition = nil
    result = nil
    definition() { return [self.id,self.profile,self.source,self.rads,self.radDenominator,self.approved,self.evidence]; }
    assess()
    {
        if (self.id == nil || self.id == '' || self.profile == nil || !self.profile.ofKind(RpgExpandedProfile)
            || self.source == nil) rpgExpandedReject('radiation-dose-definition');
        rpgInteger(self.rads,1,100000000); rpgInteger(self.radDenominator,1,20000000);
        local value = new RpgExpandedResult();
        if (self.result != nil)
        {
            local current = self.definition();
            for (local index = 1; index <= current.length(); index += 1)
                if (current[index] != self.boundDefinition[index]) rpgExpandedReject('radiation-dose-binding');
            if (!holds(self.profile.radiationDoses,self)) rpgExpandedReject('radiation-dose-history');
            value.status = 'reused'; return value;
        }
        rpgExpandedValidate(self.profile);
        if (!self.approved || self.evidence == nil || self.evidence == '')
        { value.reason = 'radiation-dose-evidence'; return value; }
        foreach (local prior in self.profile.radiationDoses)
            if (prior.id == self.id) rpgExpandedReject('radiation-dose-duplicate');
        rpgInteger(rpgLedger.seconds,0,2147483647);
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        self.boundDefinition = self.definition(); self.receivedAt = rpgLedger.seconds;
        self.profile.radiationDoses = self.profile.radiationDoses + [self];
        value.status = 'resolved'; self.result = value; return value;
    }
    remainingQuantity()
    {
        if (self.result == nil) rpgExpandedReject('radiation-dose-unreceived');
        self.assess(); rpgInteger(self.receivedAt,0,rpgLedger.seconds);
        return rpgExpandedRadiationRemainingQuantity(self.rads,self.radDenominator,
            (rpgLedger.seconds - self.receivedAt) / 86400);
    }
    remainingTenths() { return self.remainingQuantity().tenths(); }
;

/** Sum independently recovering doses; assessment never consumes exposure state. */
rpgExpandedRadiationTotalTenths(profile)
{
    return rpgExpandedRadiationTotal(profile).tenths();
}

/** B436 reference samples only; no interpolation across thicknesses/materials. */
rpgExpandedRadiationProtection(sample)
{
    if (holds(['lead-half-inch','steel-one-and-half-inches','air-750-yards'],sample)) return 2;
    if (sample == 'water-one-yard') return 8;
    if (sample == 'earth-one-yard') return 27;
    if (sample == 'concrete-one-yard') return 64;
    rpgExpandedReject('radiation-protection-sample');
}

/** Exact received-dose ratio. No fractional rad is rounded away. */
rpgExpandedShieldedRadiation(rads, protection, spectrum)
{
    rpgInteger(rads,1,1000000); rpgInteger(protection,1,1000000);
    if (!holds(['ordinary','solar-belt','cosmic'],spectrum)) rpgExpandedReject('radiation-spectrum');
    local value = new RpgExpandedShieldedRadiationResult();
    value.numerator = rads; value.denominator = protection;
    if (spectrum == 'solar-belt') value.denominator *= 20;
    if (spectrum == 'cosmic')
    {
        /* B436 divides PF by 100, but gives no sub-one protection rule. */
        if (protection < 100) { value.reason = 'radiation-subunit-protection-unresolved'; return value; }
        value.numerator *= 100;
    }
    value.wholeRads = value.numerator / value.denominator;
    value.fractional = value.numerator != value.wholeRads * value.denominator;
    value.status = 'ready'; return value;
}

/** Ratio and whole-rad eligibility, before recording an exposure. */
class RpgExpandedShieldedRadiationResult: RpgExpandedResult
    numerator = 0
    denominator = 1
    wholeRads = 0
    fractional = nil
    resistanceDivisor = 1
    preventiveDivisor = 1
    dose = nil
;

modify RpgExpandedProfile
    radiationExposures = []
;

/** Shielded exact exposure composed with the shared dose history. */
class RpgExpandedRadiationExposure: object
    id = nil
    profile = nil
    source = nil
    incidentRads = 0
    protection = 1
    spectrum = 'ordinary'
    approved = nil
    evidence = nil
    result = nil
    boundDefinition = nil
    definition()
    {
        return [self.id,self.profile,self.source,self.incidentRads,self.protection,self.spectrum,self.approved,self.evidence];
    }
    assess()
    {
        if (self.id == nil || self.id == '' || self.profile == nil || !self.profile.ofKind(RpgExpandedProfile)
            || self.source == nil) rpgExpandedReject('radiation-exposure-definition');
        if (self.result != nil)
        {
            local current = self.definition();
            for (local index = 1; index <= current.length(); index += 1)
                if (current[index] != self.boundDefinition[index]) rpgExpandedReject('radiation-exposure-binding');
            if (!holds(self.profile.radiationExposures,self) || self.result.dose == nil
                || self.result.dose.assess().status != 'reused') rpgExpandedReject('radiation-exposure-history');
            local replay = new RpgExpandedShieldedRadiationResult(); replay.status = 'reused'; return replay;
        }
        local value = rpgExpandedShieldedRadiation(self.incidentRads,self.protection,self.spectrum);
        if (value.status != 'ready') return value;
        rpgExpandedValidate(self.profile);
        foreach (local prior in self.profile.radiationExposures)
            if (prior.id == self.id) rpgExpandedReject('radiation-exposure-duplicate');
        value.dose = new RpgExpandedRadiationDose(); value.dose.id = self.id;
        value.resistanceDivisor = self.profile.radiationDivisor();
        local quantity = rpgExpandedDivideRadiation(rpgExpandedRadQuantity(value.numerator,value.denominator),
            value.resistanceDivisor);
        value.preventiveDivisor = self.profile.radiationPreventiveDivisor();
        quantity = rpgExpandedDivideRadiation(quantity,value.preventiveDivisor);
        value.dose.profile = self.profile; value.dose.source = self.source;
        value.dose.rads = quantity.numerator; value.dose.radDenominator = quantity.denominator;
        value.dose.approved = self.approved; value.dose.evidence = self.evidence;
        local prepared = value.dose.assess();
        if (prepared.status != 'ready') { value.status = 'blocked'; value.reason = prepared.reason; }
        return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        local committed = value.dose.apply();
        if (committed.status != 'resolved') rpgExpandedReject('radiation-exposure-dose-changed');
        self.boundDefinition = self.definition(); self.profile.radiationExposures = self.profile.radiationExposures + [self];
        value.status = 'resolved'; self.result = value; return value;
    }
;


/** Exact nonnegative rad quantity. Conversion refuses precision loss. */
class RpgExpandedRadQuantity: object
    numerator = 0
    denominator = 1
    tenths()
    {
        if (10 % self.denominator != 0) rpgExpandedReject('radiation-finer-than-tenth');
        local multiplier = 10 / self.denominator;
        rpgInteger(self.numerator,0,2147483647 / multiplier);
        return self.numerator * multiplier;
    }
;

/** Reduce a bounded integer ratio without floating-point or dose rounding. */
rpgExpandedRadQuantity(numerator, denominator)
{
    rpgInteger(numerator,0,2147483647); rpgInteger(denominator,1,2147483647);
    local left = numerator; local right = denominator;
    while (right != 0) { local remainder = left % right; left = right; right = remainder; }
    local value = new RpgExpandedRadQuantity();
    value.numerator = numerator / left; value.denominator = denominator / left; return value;
}

/** Per-dose daily recovery with an exact one-tenth residual, B435. */
rpgExpandedRadiationRemainingQuantity(numerator, denominator, elapsedDays)
{
    rpgInteger(numerator,1,100000000); rpgInteger(denominator,1,20000000);
    rpgInteger(elapsedDays,0,1000000);
    if (elapsedDays <= 30) return rpgExpandedRadQuantity(numerator,denominator);
    local days = elapsedDays - 30;
    local daily = denominator * 100;
    /* Compare before multiplying days: large elapsed times cannot overflow. */
    if (days > numerator * 9 / daily) return rpgExpandedRadQuantity(numerator,denominator * 10);
    return rpgExpandedRadQuantity(numerator * 10 - days * daily,denominator * 10);
}

/** Exact sum with reduced denominator and explicit arithmetic capacity checks. */
rpgExpandedAddRadiation(left, right)
{
    local a = rpgExpandedRadQuantity(left.numerator,left.denominator);
    local b = rpgExpandedRadQuantity(right.numerator,right.denominator);
    local x = a.denominator; local y = b.denominator;
    while (y != 0) { local remainder = x % y; x = y; y = remainder; }
    local leftFactor = b.denominator / x; local rightFactor = a.denominator / x;
    if (a.denominator > 2147483647 / leftFactor || a.numerator > 2147483647 / leftFactor
        || b.numerator > 2147483647 / rightFactor) rpgExpandedReject('radiation-quantity-capacity');
    local first = a.numerator * leftFactor; local second = b.numerator * rightFactor;
    if (first > 2147483647 - second) rpgExpandedReject('radiation-quantity-capacity');
    return rpgExpandedRadQuantity(first + second,a.denominator * leftFactor);
}

/** Independently age and sum every owned dose, retaining fractional residues. */
rpgExpandedRadiationTotal(profile)
{
    rpgExpandedValidate(profile); local total = rpgExpandedRadQuantity(0,1); local ids = [];
    foreach (local dose in profile.radiationDoses)
    {
        if (dose == nil || !dose.ofKind(RpgExpandedRadiationDose) || dose.profile != profile || holds(ids,dose.id))
            rpgExpandedReject('radiation-dose-history');
        ids = ids + [dose.id]; total = rpgExpandedAddRadiation(total,dose.remainingQuantity());
    }
    return total;
}


/** Divide after shielding, cancelling factors before bounded multiplication. */
rpgExpandedDivideRadiation(quantity, divisor)
{
    rpgInteger(divisor,1,1000);
    local normalized = rpgExpandedRadQuantity(quantity.numerator,quantity.denominator);
    local left = normalized.numerator; local right = divisor;
    while (right != 0) { local remainder = left % right; left = right; right = remainder; }
    local multiplier = divisor / left;
    if (normalized.denominator > 20000000 / multiplier) rpgExpandedReject('radiation-quantity-capacity');
    return rpgExpandedRadQuantity(normalized.numerator / left,normalized.denominator * multiplier);
}

/** B436 preventive medication. Price is per dose; authors supply package weight. */
class RpgExpandedRadiationPreventive: RpgLiteItem
    cost = 500
    techLevel = 7
;

modify RpgExpandedProfile
    radiationPreventions = []
    radiationPreventiveDivisor()
    {
        local active = 0;
        foreach (local treatment in self.radiationPreventions)
        {
            treatment.validateReceipt();
            local elapsed = rpgLedger.seconds - treatment.administeredAt;
            if (elapsed >= 3600 && elapsed <= 10800) active += 1;
        }
        if (active > 1) rpgExpandedReject('radiation-prevention-overlap');
        return active == 1 ? 2 : 1;
    }
;

/** An authored administration consumes one owned dose; purchase remains separate. */
class RpgExpandedRadiationPrevention: object
    id = nil
    profile = nil
    medicine = nil
    approved = nil
    administrationEvidence = nil
    administeredAt = nil
    boundDefinition = nil
    result = nil
    medicineValid() { return self.medicine.ofKind(RpgExpandedRadiationPreventive); }
    minimumTechnology() { return 7; }
    history() { return self.profile.radiationPreventions; }
    remember() { self.profile.radiationPreventions = self.profile.radiationPreventions + [self]; }
    overlaps(prior) { return rpgLedger.seconds - prior.administeredAt <= 10800; }
    definition() { return [self.id,self.profile,self.medicine,self.approved,self.administrationEvidence]; }
    validateReceipt()
    {
        if (self.result == nil || self.boundDefinition == nil || self.administeredAt == nil)
            rpgExpandedReject('radiation-prevention-uncommitted');
        local current = self.definition();
        for (local index = 1; index <= current.length(); index += 1)
            if (current[index] != self.boundDefinition[index]) rpgExpandedReject('radiation-prevention-binding');
        if (!holds(self.history(),self)) rpgExpandedReject('radiation-prevention-history');
        rpgInteger(self.administeredAt,0,rpgLedger.seconds); return nil;
    }
    assess()
    {
        if (self.id == nil || self.id == '' || self.profile == nil || !self.profile.ofKind(RpgExpandedProfile)
            || self.medicine == nil || !self.medicineValid())
            rpgExpandedReject('radiation-prevention-definition');
        local value = new RpgExpandedResult();
        if (self.result != nil) { self.validateReceipt(); value.status = 'reused'; return value; }
        rpgExpandedValidate(self.profile);
        if (!self.approved || self.administrationEvidence == nil || self.administrationEvidence == '')
        { value.reason = 'radiation-prevention-administration-required'; return value; }
        if (self.profile.dead) { value.reason = 'radiation-prevention-patient-dead'; return value; }
        rpgInteger(self.medicine.techLevel,self.minimumTechnology(),12); rpgInteger(self.medicine.quantity,0,1000000);
        if (!holds(self.profile.equipment,self.medicine) || self.medicine.quantity == 0
            || !self.medicine.usableBy(self.profile))
        { value.reason = 'radiation-prevention-supply'; return value; }
        local count = 0;
        for (local owner = firstObj(RpgLiteProfile); owner != nil; owner = nextObj(owner,RpgLiteProfile))
            foreach (local item in owner.equipment) if (item == self.medicine) count += 1;
        if (count != 1) rpgExpandedReject('radiation-prevention-supply-ownership');
        foreach (local prior in self.history())
        {
            prior.validateReceipt();
            if (prior.id == self.id) rpgExpandedReject('radiation-prevention-duplicate');
            /* Repeated-dose pharmacology is unspecified; reject overlapping windows. */
            if (self.overlaps(prior))
            { value.reason = 'radiation-prevention-overlap'; return value; }
        }
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        self.medicine.quantity -= 1;
        if (self.medicine.quantity == 0)
        {
            local remaining = [];
            foreach (local item in self.profile.equipment) if (item != self.medicine) remaining = remaining + [item];
            self.profile.equipment = remaining;
        }
        self.administeredAt = rpgLedger.seconds; self.boundDefinition = self.definition();
        self.remember();
        value.status = 'resolved'; self.result = value; return value;
    }
;


/** B436 advanced medication: the existing acquisition ledger charges per dose. */
class RpgExpandedRadiationRepairMedicine: RpgLiteItem
    cost = 1000
    techLevel = 9
;

/** One two-week course; overlapping courses are unsupported, never additive. */
class RpgExpandedRadiationResistanceTreatment: RpgExpandedRadiationPrevention
    medicineValid() { return self.medicine.ofKind(RpgExpandedRadiationRepairMedicine); }
    minimumTechnology() { return 9; }
    history() { return self.profile.radiationResistanceTreatments; }
    remember() { self.profile.radiationResistanceTreatments = self.profile.radiationResistanceTreatments + [self]; }
    overlaps(prior) { return rpgLedger.seconds - prior.administeredAt < 1209600; }
;

modify RpgExpandedProfile
    radiationResistanceTreatments = []
    radiationTreatmentModifier()
    {
        local active = 0;
        foreach (local treatment in self.radiationResistanceTreatments)
        {
            if (treatment == nil || !treatment.ofKind(RpgExpandedRadiationResistanceTreatment)
                || treatment.profile != self) rpgExpandedReject('radiation-treatment-history');
            treatment.validateReceipt();
            if (rpgLedger.seconds - treatment.administeredAt < 1209600) active += 1;
        }
        if (active > 1) rpgExpandedReject('radiation-treatment-overlap');
        return active == 1 ? 3 : 0;
    }
;

/** Every HT roll against radiation can use this context, including later recovery.
 * It supplies the medication bonus once; the caller supplies other rule modifiers. */
class RpgExpandedRadiationContext: RpgLiteContext
    kind = 'radiation'
    attribute = rpgHT
    skillUseModifier(profile)
    {
        if (!profile.ofKind(RpgExpandedProfile) || self.attribute != rpgHT
            || self.skill != nil || self.kind != 'radiation') rpgExpandedReject('radiation-check-context');
        local base = inherited(profile);
        return base == nil ? nil : base + profile.radiationTreatmentModifier();
    }
;

/** B436 remaining internal-source exposure fraction after a single treatment. */
rpgExpandedFalloutFraction(advanced, elapsedSeconds)
{
    rpgInteger(elapsedSeconds,0,2147483647);
    if (advanced) return rpgExpandedRadQuantity(elapsedSeconds >= 43200 ? 0 : 1,1);
    if (elapsedSeconds >= 604800) return rpgExpandedRadQuantity(0,1);
    return rpgExpandedRadQuantity(1,elapsedSeconds >= 259200 ? 2 : 1);
}

modify RpgExpandedProfile
    internalFallout = []
    falloutTreatments = []
;

/** One authored internal fallout burden; new ingestion needs a new record. */
class RpgExpandedInternalFallout: object
    id = nil
    profile = nil
    approved = nil
    evidence = nil
    recordedAt = nil
    boundDefinition = nil
    result = nil
    definition() { return [self.id,self.profile,self.approved,self.evidence]; }
    validateReceipt()
    {
        if (self.result == nil || self.boundDefinition == nil || self.recordedAt == nil)
            rpgExpandedReject('fallout-uncommitted');
        local current = self.definition();
        for (local index = 1; index <= current.length(); index += 1)
            if (current[index] != self.boundDefinition[index]) rpgExpandedReject('fallout-binding');
        if (!holds(self.profile.internalFallout,self)) rpgExpandedReject('fallout-history');
        rpgInteger(self.recordedAt,0,rpgLedger.seconds); return nil;
    }
    fraction()
    {
        self.validateReceipt(); local found = nil;
        foreach (local treatment in self.profile.falloutTreatments)
        {
            if (treatment == nil || !treatment.ofKind(RpgExpandedFalloutTreatment)
                || treatment.profile != self.profile) rpgExpandedReject('fallout-treatment-history');
            treatment.validateReceipt();
            if (treatment.contamination == self)
            {
                if (found != nil) rpgExpandedReject('fallout-treatment-overlap');
                found = treatment;
            }
        }
        return found == nil ? rpgExpandedRadQuantity(1,1)
            : rpgExpandedFalloutFraction(found.advanced,rpgLedger.seconds - found.administeredAt);
    }
    assess()
    {
        if (self.id == nil || self.id == '' || self.profile == nil || !self.profile.ofKind(RpgExpandedProfile))
            rpgExpandedReject('fallout-definition');
        local value = new RpgExpandedResult();
        if (self.result != nil) { self.validateReceipt(); value.status = 'reused'; return value; }
        rpgExpandedValidate(self.profile);
        if (!self.approved || self.evidence == nil || self.evidence == '')
        { value.reason = 'fallout-evidence-required'; return value; }
        foreach (local prior in self.profile.internalFallout)
        {
            if (prior.profile != self.profile) rpgExpandedReject('fallout-history');
            prior.validateReceipt();
            if (prior.id == self.id) rpgExpandedReject('fallout-duplicate');
            if (prior.fraction().numerator != 0)
            { value.reason = 'fallout-repeated-ingestion-unimplemented'; return value; }
        }
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        self.recordedAt = rpgLedger.seconds; self.boundDefinition = self.definition();
        self.profile.internalFallout = self.profile.internalFallout + [self];
        value.status = 'resolved'; self.result = value; return value;
    }
;

/** Separate basic and advanced supplies prevent accidental use of a slower dose. */
class RpgExpandedFalloutMedicine: RpgLiteItem
    cost = 500
    techLevel = 7
;
class RpgExpandedAdvancedFalloutMedicine: RpgExpandedFalloutMedicine
    techLevel = 8
;

/** B436 removal of one internal burden, without changing absorbed dose history. */
class RpgExpandedFalloutTreatment: RpgExpandedRadiationPrevention
    contamination = nil
    advanced = nil
    medicineValid()
    {
        return self.advanced ? self.medicine.ofKind(RpgExpandedAdvancedFalloutMedicine)
            : self.medicine.ofKind(RpgExpandedFalloutMedicine)
                && !self.medicine.ofKind(RpgExpandedAdvancedFalloutMedicine);
    }
    minimumTechnology() { return self.advanced ? 8 : 7; }
    history() { return self.profile.falloutTreatments; }
    remember() { self.profile.falloutTreatments = self.profile.falloutTreatments + [self]; }
    overlaps(prior) { return prior.contamination == self.contamination; }
    definition() { return inherited() + [self.contamination,self.advanced]; }
    assess()
    {
        if (self.contamination == nil || !self.contamination.ofKind(RpgExpandedInternalFallout)
            || self.contamination.profile != self.profile) rpgExpandedReject('fallout-treatment-target');
        self.contamination.validateReceipt();
        return inherited();
    }
;

modify RpgExpandedProfile
    falloutReleases = []
;
class RpgExpandedFalloutReleaseResult: RpgExpandedResult
    sourceFraction = nil
    quantity = nil
    dose = nil
;

/** An authored instantaneous release from internal fallout, assessed at this clock.
 * The baseline is before chelation and personal protection, with no outer shield. */
class RpgExpandedFalloutRelease: object
    id = nil
    contamination = nil
    numerator = 0
    denominator = 1
    approved = nil
    evidence = nil
    result = nil
    boundDefinition = nil
    definition() { return [self.id,self.contamination,self.numerator,self.denominator,self.approved,self.evidence]; }
    assess()
    {
        if (self.id == nil || self.id == '' || self.contamination == nil
            || !self.contamination.ofKind(RpgExpandedInternalFallout)) rpgExpandedReject('fallout-release-definition');
        self.contamination.validateReceipt(); local profile = self.contamination.profile;
        local value = new RpgExpandedFalloutReleaseResult();
        if (self.result != nil)
        {
            local current = self.definition();
            for (local index = 1; index <= current.length(); index += 1)
                if (current[index] != self.boundDefinition[index]) rpgExpandedReject('fallout-release-binding');
            if (!holds(profile.falloutReleases,self) || self.result.dose != nil
                && self.result.dose.assess().status != 'reused') rpgExpandedReject('fallout-release-history');
            value.status = 'reused'; return value;
        }
        rpgExpandedValidate(profile);
        rpgInteger(self.numerator,1,100000000); rpgInteger(self.denominator,1,20000000);
        if (!self.approved || self.evidence == nil || self.evidence == '')
        { value.reason = 'fallout-release-evidence-required'; return value; }
        foreach (local prior in profile.falloutReleases)
            if (prior.id == self.id) rpgExpandedReject('fallout-release-duplicate');
        value.sourceFraction = self.contamination.fraction();
        value.quantity = rpgExpandedRadQuantity(0,1);
        if (value.sourceFraction.numerator != 0)
        {
            value.quantity = rpgExpandedDivideRadiation(rpgExpandedRadQuantity(self.numerator,self.denominator),
                value.sourceFraction.denominator);
            value.quantity = rpgExpandedDivideRadiation(value.quantity,profile.radiationDivisor());
            value.quantity = rpgExpandedDivideRadiation(value.quantity,profile.radiationPreventiveDivisor());
            value.dose = new RpgExpandedRadiationDose(); value.dose.id = self.id;
            value.dose.profile = profile; value.dose.source = self.contamination;
            value.dose.rads = value.quantity.numerator; value.dose.radDenominator = value.quantity.denominator;
            value.dose.approved = self.approved; value.dose.evidence = self.evidence;
            local prepared = value.dose.assess();
            if (prepared.status != 'ready') { value.reason = prepared.reason; return value; }
        }
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        if (value.dose != nil && value.dose.apply().status != 'resolved') rpgExpandedReject('fallout-release-dose-changed');
        self.boundDefinition = self.definition();
        self.contamination.profile.falloutReleases = self.contamination.profile.falloutReleases + [self];
        value.status = 'resolved'; self.result = value; return value;
    }
;

modify RpgExpandedProfile
    radiationChecks = []
;

class RpgExpandedRadiationCheckResult: RpgExpandedRadiationResult
    context = nil
    score = nil
    accumulated = nil
    consequencesPending = nil
;

/** Owned living-subject check. Nonzero syndromes remain explicit pending work;
 * recording a check is not an assertion that its medical consequences ran. */
class RpgExpandedRadiationCheck: object
    id = nil
    triggerDose = nil
    continued = nil
    approved = nil
    exposureEvidence = nil
    checkedAt = nil
    boundDefinition = nil
    result = nil
    definition() { return [self.id,self.triggerDose,self.continued,self.approved,self.exposureEvidence]; }
    validateReceipt()
    {
        if (self.result == nil || self.boundDefinition == nil || self.checkedAt == nil)
            rpgExpandedReject('radiation-check-uncommitted');
        local current = self.definition();
        for (local index = 1; index <= current.length(); index += 1)
            if (current[index] != self.boundDefinition[index]) rpgExpandedReject('radiation-check-binding');
        if (!holds(self.triggerDose.profile.radiationChecks,self)) rpgExpandedReject('radiation-check-history');
        rpgInteger(self.checkedAt,0,rpgLedger.seconds); return nil;
    }
    assess()
    {
        if (self.id == nil || self.id == '' || self.triggerDose == nil
            || !self.triggerDose.ofKind(RpgExpandedRadiationDose)) rpgExpandedReject('radiation-check-definition');
        if (self.triggerDose.assess().status != 'reused') rpgExpandedReject('radiation-check-dose-required');
        local profile = self.triggerDose.profile; local value = new RpgExpandedRadiationCheckResult();
        if (self.result != nil)
        {
            self.validateReceipt(); value.status = 'reused'; value.check = self.result.check;
            value.effect = self.result.effect; value.consequencesPending = self.result.consequencesPending;
            return value;
        }
        rpgExpandedValidate(profile);
        if (!self.approved || self.exposureEvidence == nil || self.exposureEvidence == '')
        { value.reason = 'radiation-check-living-exposure-evidence'; return value; }
        if (profile.dead) { value.reason = 'radiation-check-patient-dead'; return value; }
        local found = nil;
        foreach (local prior in profile.radiationChecks)
        {
            if (prior == nil || !prior.ofKind(RpgExpandedRadiationCheck)
                || prior.triggerDose.profile != profile) rpgExpandedReject('radiation-check-history');
            prior.validateReceipt();
            if (prior.id == self.id) rpgExpandedReject('radiation-check-duplicate');
            if (prior.triggerDose.source == self.triggerDose.source)
            {
                if (prior.checkedAt / 86400 == rpgLedger.seconds / 86400)
                { value.reason = 'radiation-check-source-day-used'; return value; }
                found = prior;
            }
        }
        if (found != nil && !self.continued)
        { value.reason = 'radiation-check-repeated-acute-exposure-unimplemented'; return value; }
        if (!self.continued && self.triggerDose.receivedAt != rpgLedger.seconds)
        { value.reason = 'radiation-check-delayed-onset-unimplemented'; return value; }
        value.accumulated = rpgExpandedRadiationTotal(profile);
        if (value.accumulated.numerator < value.accumulated.denominator)
        { value.reason = 'radiation-check-below-threshold'; return value; }
        if (value.accumulated.denominator != 1)
        { value.reason = 'radiation-check-fractional-band-unresolved'; return value; }
        local band = rpgExpandedRadiationBand(value.accumulated.numerator);
        if (band.status != 'ready') { value.reason = band.reason; return value; }
        value.effects = band.effects; value.modifier = band.modifier;
        value.context = new RpgExpandedRadiationContext(); value.context.modifier = band.modifier;
        value.score = rpgLiteScore(profile,value.context);
        if (value.score == nil || value.score < 3)
        { value.reason = 'radiation-score-unavailable'; return value; }
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        value.check = rpgLiteCheck(self.triggerDose.profile,value.context);
        local column = value.check.critical == 'success' ? 1 : value.check.critical == 'failure' ? 4
            : value.check.achieved ? 2 : 3;
        value.effect = value.effects[column]; value.consequencesPending = value.effect != 'none';
        value.status = value.consequencesPending ? 'awaiting-consequences' : 'resolved';
        self.checkedAt = rpgLedger.seconds; self.boundDefinition = self.definition();
        self.triggerDose.profile.radiationChecks = self.triggerDose.profile.radiationChecks + [self];
        self.result = value; return value;
    }
;

modify RpgExpandedProfile
    radiationBurns = []
    level(id)
    {
        local value = inherited(id);
        if (!holds(['high-pain-threshold','low-pain-threshold'],id)) return value;
        foreach (local episode in self.radiationBurns)
            if (episode.onsetAt != nil && rpgLedger.seconds - episode.onsetAt < 604800)
            {
                if (episode.suppressedResistance && id == 'high-pain-threshold') return 0;
                if (!episode.suppressedResistance && id == 'low-pain-threshold') return value > 0 ? value : 1;
            }
        return value;
    }
;
class RpgExpandedRadiationBurnResult: RpgExpandedResult
    wound = nil
    injury = 0
    recoveryChecksPending = true
;

/** B436 category-A onset; later recovery consequences have a separate lifecycle. */
class RpgExpandedRadiationBurn: object
    id = nil
    radiationCheck = nil
    dropDestination = nil
    scheduledAt = nil
    onsetDue = nil
    onsetAt = nil
    healthAtExposure = nil
    suppressedResistance = nil
    boundDefinition = nil
    result = nil
    profile() { return self.radiationCheck.triggerDose.profile; }
    definition() { return [self.id,self.radiationCheck,self.dropDestination]; }
    validateReceipt()
    {
        if (self.scheduledAt == nil || self.boundDefinition == nil) rpgExpandedReject('radiation-burn-unscheduled');
        local current = self.definition();
        for (local index = 1; index <= current.length(); index += 1)
            if (current[index] != self.boundDefinition[index]) rpgExpandedReject('radiation-burn-binding');
        self.radiationCheck.validateReceipt();
        if (!holds(self.profile().radiationBurns,self)) rpgExpandedReject('radiation-burn-history');
        rpgInteger(self.scheduledAt,0,rpgLedger.seconds); return nil;
    }
    assessSchedule()
    {
        if (self.id == nil || self.id == '' || self.radiationCheck == nil
            || !self.radiationCheck.ofKind(RpgExpandedRadiationCheck)) rpgExpandedReject('radiation-burn-definition');
        self.radiationCheck.validateReceipt(); local value = new RpgExpandedResult();
        if (self.scheduledAt != nil) { self.validateReceipt(); value.status = 'reused'; return value; }
        if (self.radiationCheck.result.effect != 'burns')
        { value.reason = 'radiation-burn-syndrome-unimplemented'; return value; }
        if (self.radiationCheck.continued || self.radiationCheck.checkedAt != rpgLedger.seconds
            || self.radiationCheck.triggerDose.receivedAt != rpgLedger.seconds)
        { value.reason = 'radiation-burn-exposure-epoch-unimplemented'; return value; }
        if (self.profile().dead) { value.reason = 'radiation-burn-patient-dead'; return value; }
        foreach (local prior in self.profile().radiationBurns)
        {
            prior.validateReceipt();
            if (prior.id == self.id || prior.radiationCheck == self.radiationCheck)
                rpgExpandedReject('radiation-burn-duplicate');
            /* Recovery outcomes and overlapping pain effects need composition support. */
            if (prior.result == nil || prior.result.recoveryChecksPending
                || prior.onsetAt != nil && rpgLedger.seconds - prior.onsetAt < 604800)
            { value.reason = 'radiation-burn-overlap-unimplemented'; return value; }
        }
        rpgInteger(self.profile().ht,1,1000);
        if (rpgLedger.seconds > 2147483647 - self.profile().ht * 3600 - 604800)
            rpgExpandedReject('radiation-burn-time-capacity');
        value.seconds = self.profile().ht * 3600; value.status = 'ready'; return value;
    }
    schedule()
    {
        local value = self.assessSchedule(); if (value.status != 'ready') return value;
        self.scheduledAt = rpgLedger.seconds; self.healthAtExposure = self.profile().ht;
        self.onsetDue = self.scheduledAt + value.seconds; self.boundDefinition = self.definition();
        local profile = self.profile(); profile.radiationBurns = profile.radiationBurns + [self];
        value.status = 'resolved'; return value;
    }
    wound(amount)
    {
        local wound = new RpgExpandedWound(); wound.id = 'radiation-burn-' + self.id;
        wound.profile = self.profile(); wound.amount = amount; wound.dropDestination = self.dropDestination;
        return wound;
    }
    assess()
    {
        self.validateReceipt(); local value = new RpgExpandedRadiationBurnResult();
        if (self.result != nil)
        {
            if (self.result.wound.assess().status != 'reused') rpgExpandedReject('radiation-burn-wound-history');
            value.status = 'reused'; value.wound = self.result.wound; value.injury = self.result.injury;
            value.recoveryChecksPending = self.result.recoveryChecksPending; return value;
        }
        if (self.profile().dead) { value.reason = 'radiation-burn-patient-dead'; return value; }
        if (rpgLedger.seconds != self.onsetDue) { value.reason = 'radiation-burn-not-due'; return value; }
        for (local amount = 1; amount <= 6; amount += 1)
        {
            local prepared = self.wound(amount).assess();
            if (prepared.status != 'ready') { value.reason = prepared.reason; return value; }
        }
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        local resistant = self.profile().level('high-pain-threshold') > 0;
        value.injury = rpgRandom.die(); value.wound = self.wound(value.injury);
        if (value.wound.apply().status != 'resolved') rpgExpandedReject('radiation-burn-wound-changed');
        /* Apply the printed injury before gaining the simultaneous temporary trait. */
        self.suppressedResistance = resistant; self.onsetAt = rpgLedger.seconds;
        value.status = 'awaiting-recovery'; self.result = value; return value;
    }
;

modify rpgLedger
    validateAdvance(seconds)
    {
        inherited(seconds);
        for (local episode = firstObj(RpgExpandedRadiationBurn); episode != nil;
            episode = nextObj(episode,RpgExpandedRadiationBurn))
            if (episode.scheduledAt != nil && episode.result == nil && !episode.profile().dead)
            {
                episode.validateReceipt();
                if (self.seconds + seconds > episode.onsetDue) rpgExpandedReject('radiation-burn-onset-boundary');
            }
        return nil;
    }
;

modify RpgExpandedRadiationBurn
    recovery = nil
;
class RpgExpandedRadiationRecoveryResult: RpgExpandedResult
    sterilityCheck = nil
    terminalCheck = nil
    sterile = nil
    terminal = nil
;

/** B436 independent post-recovery checks. Whole-profile healing is a conservative
 * prerequisite until wound-specific healing allocation is available. */
class RpgExpandedRadiationBurnRecovery: object
    episode = nil
    terminalCondition = nil
    approved = nil
    recoveryEvidence = nil
    result = nil
    boundDefinition = nil
    completedAt = nil
    sterilityTrait = nil
    definition() { return [self.episode,self.terminalCondition,self.approved,self.recoveryEvidence]; }
    context()
    {
        local context = new RpgExpandedRadiationContext();
        context.modifier = self.episode.radiationCheck.result.modifier; return context;
    }
    assess()
    {
        if (self.episode == nil || !self.episode.ofKind(RpgExpandedRadiationBurn))
            rpgExpandedReject('radiation-recovery-episode');
        self.episode.validateReceipt(); local value = new RpgExpandedRadiationRecoveryResult();
        if (self.result != nil)
        {
            local current = self.definition();
            for (local index = 1; index <= current.length(); index += 1)
                if (current[index] != self.boundDefinition[index]) rpgExpandedReject('radiation-recovery-binding');
            if (self.episode.recovery != self) rpgExpandedReject('radiation-recovery-history');
            if (self.result.terminal) self.terminalCondition.validateReceipt();
            if (self.sterilityTrait != nil && !holds(self.episode.profile().traits,self.sterilityTrait))
                rpgExpandedReject('radiation-recovery-sterility-history');
            value.status = 'reused'; value.sterilityCheck = self.result.sterilityCheck;
            value.terminalCheck = self.result.terminalCheck; value.sterile = self.result.sterile;
            value.terminal = self.result.terminal; value.points = self.result.points; return value;
        }
        if (self.episode.recovery != nil) rpgExpandedReject('radiation-recovery-duplicate');
        if (self.episode.result == nil || self.episode.result.wound.assess().status != 'reused')
        { value.reason = 'radiation-recovery-onset-required'; return value; }
        local profile = self.episode.profile();
        if (profile.dead) { value.reason = 'radiation-recovery-patient-dead'; return value; }
        if (profile.injury != 0) { value.reason = 'radiation-recovery-healing-required'; return value; }
        if (!self.approved || self.recoveryEvidence == nil || self.recoveryEvidence == '')
        { value.reason = 'radiation-recovery-evidence-required'; return value; }
        if (self.terminalCondition == nil || !self.terminalCondition.ofKind(RpgExpandedTerminalCondition)
            || self.terminalCondition.profile != profile) rpgExpandedReject('radiation-recovery-terminal-definition');
        local terminal = self.terminalCondition.assess();
        if (terminal.status != 'ready') { value.reason = 'radiation-recovery-terminal-unavailable'; return value; }
        local score = rpgLiteScore(profile,self.context());
        if (score == nil || score < 3) { value.reason = 'radiation-recovery-score-unavailable'; return value; }
        foreach (local trait in profile.traits)
            if (trait.id == 'sterility' && (!trait.ofKind(RpgExpandedSterility) || !trait.active || trait.mitigated))
                rpgExpandedReject('radiation-recovery-sterility-definition');
        /* Reserve room for both independently acquired consequences before rolling. */
        rpgInteger(profile.developmentRevision,0,2147483645);
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        local profile = self.episode.profile();
        value.sterilityCheck = rpgLiteCheck(profile,self.context());
        value.terminalCheck = rpgLiteCheck(profile,self.context());
        value.sterile = value.sterilityCheck.critical == 'failure';
        value.terminal = value.terminalCheck.critical == 'failure';
        if (value.sterile && !profile.fertilityBlocked())
        {
            self.sterilityTrait = new RpgExpandedSterility();
            profile.traits = profile.traits + [self.sterilityTrait]; profile.developmentRevision += 1;
        }
        if (value.terminal && self.terminalCondition.acquire().status != 'resolved')
            rpgExpandedReject('radiation-recovery-terminal-changed');
        self.completedAt = rpgLedger.seconds; self.boundDefinition = self.definition();
        self.episode.recovery = self; self.episode.result.recoveryChecksPending = nil;
        self.episode.result.status = 'resolved'; value.points = value.terminal ? -75 : 0;
        self.episode.radiationCheck.result.consequencesPending = nil;
        self.episode.radiationCheck.result.status = 'resolved';
        value.status = 'resolved'; self.result = value; return value;
    }
;

/** B424 mandates the B444 acquisition check after low-technology surgery,
 * even when no HP-loss wound was created by the successful procedure. */
class RpgExpandedSurgicalInfectionContext: RpgExpandedInfectionContext
    assessAcquisition()
    {
        rpgInteger(self.medicalTL,0,12);
        local value = new RpgExpandedInfectionAssessment();
        if (self.antibiotics || self.criticalTreatmentFailure)
        { value.reason = 'surgical-infection-treatment-combination-unimplemented'; return value; }
        value.checkRequired = true; value.modifier = 3 + self.contaminationModifier();
        value.status = 'ready'; return value;
    }
;
class RpgExpandedSurgicalInfectionExposure: RpgExpandedInfectionExposure
    operation = nil
    boundOperation = nil
    patient() { return self.operation.patient; }
    sourceId() { return 'surgery-' + self.operation.id; }
    ownsSource() { return holds(self.patient().surgicalOperations,self.operation); }
    rememberExposure() { self.boundOperation = self.operation; }
    assessPreparation()
    {
        if (self.operation == nil || !self.operation.ofKind(RpgExpandedSurgicalOperation)
            || self.operation.infectionExposure != self || self.wound != nil
            || self.conditions == nil || !self.conditions.ofKind(RpgExpandedSurgicalInfectionContext)
            || self.diseaseId == nil || self.diseaseId == '') rpgExpandedReject('surgical-infection-definition');
        local value = new RpgExpandedInfectionResult();
        if (self.evidence == nil || self.evidence == '')
        { value.reason = 'surgical-infection-evidence'; return value; }
        if (self.conditions.medicalTL != self.operation.assessment.conditions.techLevel)
        { value.reason = 'surgical-infection-technology'; return value; }
        if (self.patient().dead) { value.reason = 'surgical-infection-patient-dead'; return value; }
        local resistance = self.patient().diseaseResistance(self.diseaseId);
        if (resistance != nil && resistance.immune)
        { value.immune = true; value.status = 'ready'; return value; }
        local acquisition = self.conditions.assessAcquisition();
        if (acquisition.status != 'ready') { value.reason = acquisition.reason; return value; }
        value.context = new RpgLiteContext(); value.context.attribute = rpgHT;
        value.context.kind = 'disease'; value.context.modifier = acquisition.modifier;
        local score = rpgLiteScore(self.patient(),value.context);
        if (score == nil || score < 3) { value.reason = 'infection-resistance-score-unavailable'; return value; }
        value.status = 'ready'; return value;
    }
    assess()
    {
        local value = new RpgExpandedInfectionResult();
        if (self.result != nil)
        {
            if (self.operation != self.boundOperation || !self.ownsSource()
                || self.operation.infectionExposure != self || self.wound != nil
                || self.diseaseId != self.boundDiseaseId || self.conditions != self.boundConditions
                || self.evidence != self.boundEvidence || self.conditions.infectedMatter != self.infectedMatter
                || self.conditions.specialLocale != self.specialLocale || self.conditions.antibiotics != self.antibiotics
                || self.conditions.medicalTL != self.medicalTL
                || self.conditions.criticalTreatmentFailure != self.criticalTreatmentFailure
                || self.conditions.untreatedDirtyWound != self.untreatedDirtyWound)
                rpgExpandedReject('surgical-infection-binding');
            self.operation.validateReceipt();
            value.status = 'reused'; value.check = self.result.check; value.immune = self.result.immune;
            value.infected = self.result.infected; value.prevented = self.result.prevented; return value;
        }
        value = self.assessPreparation(); if (value.status != 'ready') return value;
        if (self.operation.result == nil || self.operation.result.check == nil
            || self.operation.completedAt != rpgLedger.seconds || !self.ownsSource())
        { value.status = 'blocked'; value.reason = 'surgical-infection-operation-not-completed'; }
        return value;
    }
;
modify RpgExpandedSurgicalOperation
    infectionExposure = nil
    infectionReason()
    {
        if (self.infectionExposure == nil || !self.infectionExposure.ofKind(RpgExpandedSurgicalInfectionExposure))
            return 'surgical-infection-exposure-required';
        local prepared = self.infectionExposure.assessPreparation();
        return prepared.status == 'ready' ? nil : prepared.reason;
    }
    definition()
    {
        local fields = inherited() + [self.infectionExposure];
        if (self.infectionExposure == nil) return fields;
        local e = self.infectionExposure; local c = e.conditions;
        return fields + [e.operation,e.diseaseId,c,e.evidence,c.medicalTL,c.infectedMatter,c.specialLocale,
            c.antibiotics,c.criticalTreatmentFailure,c.untreatedDirtyWound];
    }
    complete()
    {
        local value = inherited(); if (value.status != 'resolved') return value;
        if (!self.patient.dead && self.assessment.conditions.assess().infectionCheckRequired)
        {
            local exposure = self.infectionExposure.apply();
            if (exposure.status != 'resolved') rpgExpandedReject('surgical-infection-commit-changed');
        }
        return value;
    }
;
modify RpgExpandedProfile
    validateFeatures()
    {
        inherited();
        foreach (local operation in self.surgicalOperations)
            if (operation.infectionExposure != nil && operation.infectionExposure.result != nil)
            {
                local exposure = operation.infectionExposure;
                if (!exposure.ofKind(RpgExpandedSurgicalInfectionExposure) || exposure.patient() != self
                    || exposure.operation != operation || exposure.assess().status != 'reused'
                    || exposure.acquiredAt != operation.completedAt)
                    rpgExpandedReject('surgical-infection-history');
                local ordinal = 0; local locked = 0; local ended = nil; local ids = [];
                foreach (local day in exposure.days)
                {
                    ordinal += 1;
                    if (!day.ofKind(RpgExpandedInfectionDay) || day.exposure != exposure
                        || day.result == nil || day.ordinal != ordinal || holds(ids,day.id)
                        || day.completedAt != exposure.acquiredAt + ordinal * 86400
                        || day.completedAt > rpgLedger.seconds || ended || day.assess().status != 'reused')
                        rpgExpandedReject('surgical-infection-day-history');
                    ids = ids + [day.id]; locked += day.result.injury; ended = day.result.ended;
                }
                if (exposure.ended != ended || exposure.lockedInjury != (ended ? 0 : locked)
                    || exposure.lockedInjury > self.diseaseInjury)
                    rpgExpandedReject('surgical-infection-injury-history');
            }
        return nil;
    }
;
modify rpgLedger
    validateAdvance(seconds)
    {
        inherited(seconds);
        for (local exposure = firstObj(RpgExpandedSurgicalInfectionExposure); exposure != nil;
            exposure = nextObj(exposure,RpgExpandedSurgicalInfectionExposure))
            if (exposure.result != nil && exposure.result.infected && !exposure.ended && !exposure.patient().dead)
            {
                exposure.assess();
                local due = exposure.acquiredAt + (exposure.days.length() + 1) * 86400;
                if (self.seconds + seconds > due) rpgExpandedReject('surgical-infection-day-boundary');
            }
        return nil;
    }
;
