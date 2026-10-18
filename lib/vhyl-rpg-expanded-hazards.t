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
    plagueRidden = nil
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
    plagueRidden = nil
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
                || self.conditions.plagueRidden != self.plagueRidden
                || self.conditions.infectedMatter != self.infectedMatter
                || self.conditions.specialLocale != self.specialLocale || self.conditions.antibiotics != self.antibiotics
                || self.conditions.medicalTL != self.medicalTL
                || self.conditions.criticalTreatmentFailure != self.criticalTreatmentFailure
                || self.conditions.untreatedDirtyWound != self.untreatedDirtyWound)
                rpgExpandedReject('infection-exposure-binding');
            value.status = 'reused'; value.check = self.result.check;
            value.immune = self.result.immune; value.condition = self.result.condition; value.infected = self.result.infected; value.prevented = self.result.prevented; return value;
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
            value.context.kind = 'disease'; value.context.modifier = assessment.modifier
                + self.patient().persistentWoundInfectionModifier(self.conditions.plagueRidden);
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
        self.plagueRidden = self.conditions.plagueRidden;
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
    plagueRidden = nil
    boundPlagueRidden = nil
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
            if (self.plagueRidden != self.boundPlagueRidden
                || self.practice != self.boundPractice || self.continuousCare != self.boundContinuousCare
                || self.id != self.boundId || self.exposure != self.boundExposure || self.antibiotics != self.boundAntibiotics
                || self.medicalTL != self.boundMedicalTL || self.careEvidence != self.boundEvidence
                || self.dropDestination != self.boundDestination || !holds(self.exposure.days,self))
                rpgExpandedReject('infection-day-binding');
            value.status = 'reused'; value.check = self.result.check; value.injury = self.result.injury; value.immune = self.result.immune;
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
        value.context.kind = 'disease'; value.context.modifier = assessment.modifier + value.physicianBonus
            + patient.persistentWoundInfectionModifier(self.plagueRidden);
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
        self.boundPlagueRidden = self.plagueRidden;
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
    calendarDay = nil
    boundCalendarDay = nil
    ageCalendarDay() { return self.calendarDay; }
    exemptFromAging() { return self.profile.level('unaging') > 0; }
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
                || self.ordinal != self.boundOrdinal || self.evidence != self.boundEvidence || self.calendarDay != self.boundCalendarDay
                || self.medicalTL != self.boundMedicalTL || !self.reached || !holds(self.profile.agingHistory,self))
                rpgExpandedReject('aging-event-binding');
            value.status = 'reused'; return value;
        }
        if (self.calendarId == nil || self.calendarId == '' || self.boundaryId == nil || self.boundaryId == '')
            rpgExpandedReject('aging-calendar-definition');
        if (self.calendarDay != nil) rpgInteger(self.calendarDay,0,2147483646);
        rpgInteger(self.ageYears,0,1000000); rpgInteger(self.ordinal,1,1000000);
        if (!self.reached || self.evidence == nil || self.evidence == '')
        { value.reason = 'aging-calendar-evidence'; return value; }
        if (self.ordinal != self.profile.agingHistory.length() + 1) rpgExpandedReject('aging-calendar-order');
        foreach (local prior in self.profile.agingHistory)
        {
            if (prior.calendarId != self.calendarId || prior.boundaryId == self.boundaryId
                || prior.era == self.profile.rejuvenations.length() && prior.ageYears > self.ageYears) rpgExpandedReject('aging-calendar-history');
            local priorDay = prior.ageCalendarDay(); local currentDay = self.ageCalendarDay();
            if (prior.era == self.profile.rejuvenations.length() && priorDay != nil && currentDay != nil && priorDay >= currentDay)
                rpgExpandedReject('aging-calendar-day-order');
        }
        if (self.exemptFromAging()) { value.reason = 'aging-exempt'; return value; }
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
        self.boundCalendarDay = self.calendarDay; self.boundAge = self.ageYears; self.boundOrdinal = self.ordinal; self.boundEvidence = self.evidence;
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
    boundExtraDefinition = nil
    extraDefinition() { return []; }
    validateAgeRange()
    {
        rpgInteger(self.oldAgeYears,0,1000000); rpgInteger(self.newAgeYears,0,1000000);
        if (self.newAgeYears >= self.oldAgeYears) rpgExpandedReject('rejuvenation-age-range');
    }
    entryPosition(entry)
    {
        if (entry.ageYears > self.oldAgeYears) return 'future';
        if (entry.ageYears == self.newAgeYears) return 'ambiguous';
        return entry.ageYears > self.newAgeYears ? 'restore' : 'keep';
    }
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
            local extra = self.extraDefinition();
            if (self.boundExtraDefinition == nil || extra.length() != self.boundExtraDefinition.length()) rpgExpandedReject('rejuvenation-extra-binding');
            for (local index = 1; index <= extra.length(); index += 1)
                if (extra[index] != self.boundExtraDefinition[index]) rpgExpandedReject('rejuvenation-extra-binding');
            foreach (local entry in self.result.restoredEvents)
                if (entry.restoredBy != self) rpgExpandedReject('rejuvenation-receipt-owner');
            value.status = 'reused'; value.gains = self.result.gains; value.pointGain = self.result.pointGain;
            value.restoredEvents = self.result.restoredEvents; return value;
        }
        if (self.id == nil || self.id == '' || self.calendarId == nil || self.calendarId == '')
            rpgExpandedReject('rejuvenation-definition');
        foreach (local prior in self.profile.rejuvenations)
            if (prior.id == self.id) rpgExpandedReject('rejuvenation-duplicate');
        self.validateAgeRange();
        foreach (local advance in self.profile.sustenanceAgingAdvances)
        {
            advance.validateReceipt();
            if (!self.profile.dead && advance.boundaries.length() < advance.plan.boundaryAgeMonths.length())
            { value.reason = 'rejuvenation-aging-unsettled'; return value; }
        }
        if (self.profile.dead) { value.reason = 'rejuvenation-resurrection-unavailable'; return value; }
        if (self.effectEvidence == nil || self.effectEvidence == '')
        { value.reason = 'rejuvenation-effect-evidence'; return value; }
        local gains = [0,0,0,0];
        foreach (local entry in self.profile.agingHistory)
        {
            if (entry.calendarId != self.calendarId || entry.result == nil) rpgExpandedReject('rejuvenation-calendar');
            if (entry.assess().status != 'reused') rpgExpandedReject('rejuvenation-aging-receipt');
            if (entry.restoredBy == nil)
            {
                local position = self.entryPosition(entry);
                if (position == 'future') rpgExpandedReject('rejuvenation-unaccounted-age');
                if (position == 'ambiguous')
                { value.reason = 'rejuvenation-partial-year-unavailable'; return value; }
                if (position == 'restore')
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
        self.boundExtraDefinition = self.extraDefinition();
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
    assessAir(evidence) { return self.assessAirRecovery(evidence); }
    assessAirRecovery(evidence)
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
        value.context.kind = 'disease'; value.context.modifier = acquisition.modifier
            + self.patient().persistentWoundInfectionModifier(self.conditions.plagueRidden);
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
                || self.evidence != self.boundEvidence || self.conditions.plagueRidden != self.plagueRidden
                || self.conditions.infectedMatter != self.infectedMatter
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
        return fields + [e.operation,e.diseaseId,c,e.evidence,c.medicalTL,c.plagueRidden,c.infectedMatter,c.specialLocale,
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

class RpgExpandedPoisonEntryResult: RpgExpandedResult
    exposed = nil
    viaPersistentWound = nil
    resistanceModifier = 0
;
/** B437 delivery boundary. Approved fields describe actual contact and protection;
 * this does not invent a poison's dose, delay, resistance or effects. */
class RpgExpandedPoisonEntry: object
    patient = nil
    route = nil
    method = 'direct'
    approved = nil
    evidence = nil
    inArea = nil
    mucousContact = nil
    openWoundContact = nil
    persistentWoundReached = nil
    vulnerableAreaHit = nil
    skinContact = nil
    unarmored = nil
    unclad = nil
    swallowed = nil
    forcedSwallow = nil
    headOrNeckHeldSeconds = 0
    wound = nil
    penetrationKind = nil
    inhaled = nil
    holdingBreath = nil
    improvisedMask = nil
    sealed = nil
    noBreathing = nil
    filteredLungs = nil
    eyeMembrane = nil
    protectedVision = nil
    senseKind = nil
    sensePresent = true
    senseProtected = nil
    assess()
    {
        if (self.patient == nil || !self.patient.ofKind(RpgExpandedProfile)
            || !holds(['blood','contact','digestive','follow-up','respiratory','sense'],self.route)
            || !holds(['direct','spray','area','weapon'],self.method)) rpgExpandedReject('poison-entry-definition');
        local value = new RpgExpandedPoisonEntryResult();
        if (!self.approved || self.evidence == nil || self.evidence == '')
        { value.reason = 'poison-entry-facts-required'; return value; }
        if (self.patient.dead) { value.reason = 'poison-entry-patient-dead'; return value; }
        if (self.persistentWoundReached && self.patient.level('persistent-wound') == 0)
            rpgExpandedReject('poison-entry-persistent-wound-missing');
        if (self.route == 'blood')
        {
            if (self.method == 'area')
                value.exposed = self.inArea && !self.sealed
                    && !((self.noBreathing || self.filteredLungs) && (self.eyeMembrane || self.protectedVision));
            else if (self.method == 'weapon')
            { value.reason = 'poison-entry-use-follow-up'; return value; }
            else
            {
                value.exposed = (self.mucousContact || self.openWoundContact || self.persistentWoundReached)
                    && (self.method != 'spray' || self.vulnerableAreaHit);
                value.viaPersistentWound = value.exposed && self.persistentWoundReached;
            }
        }
        else if (self.route == 'contact')
        {
            if (self.method == 'area') value.exposed = self.inArea && !self.sealed;
            else if (self.method == 'weapon') value.exposed = self.skinContact && self.unarmored && self.unclad;
            else value.exposed = self.skinContact || self.inhaled;
        }
        else if (self.route == 'digestive')
        {
            if (self.method != 'direct') { value.reason = 'poison-entry-delivery-combination'; return value; }
            rpgInteger(self.headOrNeckHeldSeconds,0,2147483647);
            value.exposed = self.swallowed && (!self.forcedSwallow || self.headOrNeckHeldSeconds >= 10);
        }
        else if (self.route == 'follow-up')
        {
            if (self.method != 'weapon' || !holds(['piercing','impaling','hypodermic'],self.penetrationKind))
            { value.reason = 'poison-entry-follow-up-combination'; return value; }
            if (self.wound == nil || !self.wound.ofKind(RpgExpandedWound) || self.wound.profile != self.patient
                || self.wound.assess().status != 'reused') rpgExpandedReject('poison-entry-follow-up-wound');
            value.exposed = self.wound.health.injury > 0;
        }
        else if (self.route == 'respiratory')
        {
            if (self.method == 'weapon') { value.reason = 'poison-entry-delivery-combination'; return value; }
            local breath = self.patient.unconscious || self.patient.stunned || self.patient.mentalStun
                ? true : self.inhaled && !self.holdingBreath;
            value.exposed = breath && !self.noBreathing && !self.filteredLungs
                && (self.method != 'area' || self.inArea);
            value.resistanceModifier = value.exposed && self.improvisedMask ? 1 : 0;
        }
        else
        {
            if (self.method == 'weapon') { value.reason = 'poison-entry-delivery-combination'; return value; }
            value.exposed = self.sensePresent && !self.senseProtected && (self.method != 'area' || self.inArea);
        }
        value.status = 'ready'; return value;
    }
;

/** B438 size modifies onset delay, not the interval between later cycles. */
rpgExpandedPoisonDelay(delay, sizeModifier)
{
    rpgInteger(delay,0,2147483647); rpgInteger(sizeModifier,-20,20);
    if (sizeModifier > 0)
        for (local step = 0; step < sizeModifier; step += 1)
        { rpgInteger(delay,0,1073741823); delay *= 2; }
    else
        for (local step = 0; step > sizeModifier; step -= 1)
        {
            if (delay % 2 != 0) rpgExpandedReject('poison-subsecond-delay-unimplemented');
            delay /= 2;
        }
    return delay;
}
/** full-2008 B439: exact whole-second dose scaling. Zero interval means
 * a noncyclic effect. A delivering system consumes the returned abstract doses. */
class RpgExpandedPoisonDoseResult: RpgExpandedResult
    doses = 1
    damageMultiplier = 1
    costMultiplier = 1
    delaySeconds = 0
    intervalSeconds = 0
    resistanceModifier = 0
    detectionModifier = 0
;
rpgExpandedPoisonDose(doublings, delay, interval)
{
    rpgInteger(doublings,0,10); rpgInteger(delay,0,2147483647); rpgInteger(interval,0,86400);
    local value = new RpgExpandedPoisonDoseResult();
    for (local step = 0; step < doublings; step += 1)
    {
        if (delay % 2 != 0 || interval % 2 != 0)
        { value.reason = 'poison-dose-subsecond-timing'; return value; }
        delay /= 2; interval /= 2; value.doses *= 2;
    }
    value.damageMultiplier = value.doses; value.costMultiplier = value.doses;
    value.delaySeconds = delay; value.intervalSeconds = interval;
    value.resistanceModifier = -2 * doublings; value.detectionModifier = 2 * doublings;
    value.status = 'ready'; return value;
}
class RpgExpandedPoisonResult: RpgExpandedResult
    condition = nil
    immune = nil
    fatigue = 0
    fatigueLoss = nil
    context = nil
    entryModifier = 0
    injury = 0
    wound = nil
    resisted = nil
;
/** Owned toxic injury cycles. Other effect forms are rejected, not
 * silently approximated by this subset of the full poison procedure. */
class RpgExpandedPoisonExposure: RpgLiteExposure
    id = nil
    entry = nil
    sizeModifier = 0
    approved = nil
    effectEvidence = nil
    dropDestination = nil
    startedAt = nil
    dueAt = nil
    completedAt = nil
    entryModifier = 0
    boundDefinition = nil
    result = nil
    cycleHistory = []
    condition = nil
    associatedCondition = nil
    associatedPolicy = nil
    associationEvidence = nil
    associatedApplied = nil
    assessAssociated()
    {
        local value = new RpgExpandedResult();
        local required = self.hazard.ofKind(RpgExpandedCataloguePoison) && self.hazard.catalogueId == 'neurological-agent';
        if (!required && self.associatedCondition == nil) { value.status = 'ready'; return value; }
        if (self.associatedCondition == nil || self.associatedPolicy != 'first-failed-cycle'
            || self.associationEvidence == nil || self.associationEvidence == '')
        { value.reason = 'poison-associated-condition-contract'; return value; }
        local effect = self.associatedCondition;
        if (self.causesCondition()) { value.reason = 'poison-combined-conditions-unimplemented'; return value; }
        if ((!effect.ofKind(RpgExpandedParalysis) && !effect.ofKind(RpgExpandedSeizure) && !effect.ofKind(RpgExpandedAgony)) || effect.profile != self.profile)
        { value.reason = 'poison-associated-condition-unsupported'; return value; }
        if (self.associatedApplied)
        { effect.validateReceipt(); value.status = 'ready'; return value; }
        if (effect.result != nil) { value.reason = 'poison-associated-condition-already-owned'; return value; }
        return effect.assess();
    }
    causesCoughing() { return self.hazard.ofKind(RpgExpandedCataloguePoison) && self.hazard.coughingEffect; }
    causesBlindness() { return self.hazard.ofKind(RpgExpandedCataloguePoison) && self.hazard.blindingEffect; }
    causesCondition() { return self.causesCoughing() || self.causesBlindness(); }
    newCoughing(tailSeconds) { return self.newPoisonCondition(tailSeconds); }
    newPoisonCondition(tailSeconds)
    {
        local episode = self.causesBlindness() ? new RpgExpandedEnvironmentalBlindness() : new RpgExpandedEnvironmentalCoughing();
        episode.id = (self.causesBlindness() ? 'poison-blind-' : 'poison-cough-') + self.id;
        episode.profile = self.profile; episode.exposure = self; episode.durationSeconds = tailSeconds;
        episode.approved = true; episode.evidence = self.effectEvidence; return episode;
    }
    symptomInjury = 0
    lockedFatigue = 0
    hasDexteritySymptoms() { return self.hazard.ofKind(RpgExpandedCataloguePoison) && self.hazard.dexteritySymptoms; }
    dexteritySymptomPenalty()
    {
        self.validateReceipt();
        return self.hasDexteritySymptoms() ? rpgExpandedVenomDexterityPenalty(self.profile.maxHP,self.symptomInjury) : 0;
    }
    doseDoublings = 0
    susceptibility = nil
    preparedForAgent = nil
    preparationEvidence = nil
    doseAssessment()
    {
        if (self.doseDoublings != 0 && self.entry.route != 'digestive'
            && !(self.entry.route == 'follow-up' && self.entry.penetrationKind == 'hypodermic'))
        {
            local value = new RpgExpandedPoisonDoseResult(); value.reason = 'poison-dose-route'; return value;
        }
        local delay = rpgExpandedPoisonDelay(self.hazard.delay,self.sizeModifier);
        return rpgExpandedPoisonDose(self.doseDoublings,delay,self.hazard.cycles > 1 ? self.hazard.interval : 0);
    }
    definition()
    {
        local e = self.entry; local h = self.hazard;
        if (h.ofKind(RpgExpandedCataloguePoison)) h.validateCatalogue();
        return [self.id,self.profile,h,self.sizeModifier,self.doseDoublings,self.preparedForAgent,self.preparationEvidence,self.approved,self.effectEvidence,self.dropDestination,
            h.kind,h.delay,h.interval,h.cycles,h.dice,h.adds,h.fatigueDamage,h.resistible,h.resistanceModifier,
            e,e.patient,e.route,e.method,e.approved,e.evidence,e.inArea,e.mucousContact,e.openWoundContact,
            e.persistentWoundReached,e.vulnerableAreaHit,e.skinContact,e.unarmored,e.unclad,e.swallowed,
            e.forcedSwallow,e.headOrNeckHeldSeconds,e.wound,e.penetrationKind,e.inhaled,e.holdingBreath,
            e.improvisedMask,e.sealed,e.noBreathing,e.filteredLungs,e.eyeMembrane,e.protectedVision,
            e.sensePresent,e.senseProtected,e.senseKind,
            h.ofKind(RpgExpandedCataloguePoison) ? h.catalogueId : nil,
            h.ofKind(RpgExpandedCataloguePoison) ? h.route : nil,self.susceptibility]
            + (self.susceptibility == nil ? [nil,nil,nil,nil,nil,nil,nil] : self.susceptibility.signature())
            + [self.associatedCondition,self.associatedPolicy,self.associationEvidence]
            + (self.associatedCondition == nil ? [] : self.associatedCondition.definition());
    }
    validateReceipt()
    {
        local current = self.definition();
        for (local index = 1; index <= current.length(); index += 1)
            if (current[index] != self.boundDefinition[index]) rpgExpandedReject('poison-exposure-binding');
        if (!holds(self.profile.poisonExposures,self)) rpgExpandedReject('poison-exposure-history');
        if (self.associatedApplied) self.associatedCondition.validateReceipt();
        return nil;
    }
    failureFatigue(amount)
    {
        local loss = new RpgExpandedPoisonFatigueLoss(); loss.profile = self.profile;
        loss.id = 'poison-preview-' + self.id; loss.amount = amount; loss.dropDestination = self.dropDestination; return loss;
    }
    failureWound(amount)
    {
        local wound = new RpgExpandedWound(); wound.profile = self.profile; wound.id = 'poison-preview-' + self.id;
        wound.amount = amount; wound.dropDestination = self.dropDestination; return wound;
    }
    assess()
    {
        if (self.id == nil || self.id == '' || self.profile == nil || !self.profile.ofKind(RpgExpandedProfile)
            || self.hazard == nil || !self.hazard.ofKind(RpgLiteHazard) || self.hazard.kind != 'poison'
            || self.entry == nil || !self.entry.ofKind(RpgExpandedPoisonEntry) || self.entry.patient != self.profile)
            rpgExpandedReject('poison-exposure-definition');
        local value = new RpgExpandedPoisonResult();
        if (self.hazard.ofKind(RpgExpandedCataloguePoison))
        {
            self.hazard.validateCatalogue();
            if (self.entry.route != self.hazard.route
                || self.hazard.deliveryMethod != nil && self.entry.method != self.hazard.deliveryMethod)
            { value.reason = 'poison-catalogue-route'; return value; }
            if (self.causesBlindness() && self.entry.senseKind != 'vision')
            { value.reason = 'poison-visual-agent-sense'; return value; }
            if (self.hazard.unpreparedFear && (!self.preparedForAgent
                || self.preparationEvidence == nil || self.preparationEvidence == ''))
            { value.reason = 'poison-unprepared-fear-admission-unimplemented'; return value; }
        }
        if (self.started)
        {
            self.validateReceipt();
            if (self.finished && self.result != nil)
            {
                value.status = 'reused'; value.check = self.result.check; value.injury = self.result.injury;
                value.wound = self.result.wound; value.resisted = self.result.resisted;
                value.fatigue = self.result.fatigue; value.fatigueLoss = self.result.fatigueLoss; return value;
            }
            value.entryModifier = self.entryModifier;
        }
        if (!self.approved || self.effectEvidence == nil || self.effectEvidence == '')
        { value.reason = 'poison-exposure-effect-evidence'; return value; }
        rpgInteger(self.hazard.cycles,1,10000); rpgInteger(self.hazard.interval,1,86400);
        rpgInteger(self.hazard.dice,0,100); rpgInteger(self.hazard.adds,self.hazard.dice == 0 && !self.causesCondition() ? 1 : 0,1000);
        rpgInteger(self.hazard.resistanceModifier,-100,100);
        if (self.profile.dead) { value.reason = 'poison-exposure-dead'; return value; }
        local susceptibility = new RpgExpandedPoisonSusceptibilityResult(); susceptibility.status = 'ready';
        if (self.susceptibility != nil)
        {
            if (!self.susceptibility.ofKind(RpgExpandedPoisonSusceptibility)) rpgExpandedReject('poison-susceptibility-type');
            susceptibility = self.susceptibility.assess(self.profile,self.hazard);
            if (susceptibility.status != 'ready') { value.reason = susceptibility.reason; return value; }
        }
        local dose = self.doseAssessment();
        if (dose.status != 'ready') { value.reason = dose.reason; return value; }
        if (!self.started)
        {
            foreach (local prior in self.profile.poisonExposures)
            {
                if (prior.id == self.id) rpgExpandedReject('poison-exposure-duplicate');
                if (self.hasDexteritySymptoms() && prior.hasDexteritySymptoms() && (!prior.finished || prior.symptomInjury > 0))
                { value.reason = 'poison-symptom-overlap-unimplemented'; return value; }
            }
            local entry = self.entry.assess();
            if (entry.status != 'ready' || !entry.exposed)
            { value.reason = entry.status == 'ready' ? 'poison-not-delivered' : entry.reason; return value; }
            value.entryModifier = entry.resistanceModifier;
            if (susceptibility.immune)
            { value.immune = true; value.seconds = 0; value.status = 'ready'; return value; }
            local delay = dose.delaySeconds;
            rpgInteger(rpgLedger.seconds,0,2147483647 - delay); value.seconds = delay;
            if (self.hazard.cycles > 1)
                rpgInteger(self.hazard.cycles - 1,0,(2147483647 - rpgLedger.seconds - delay) / dose.intervalSeconds);
        }
        if (self.hazard.resistible)
        {
            value.context = new RpgLiteContext(); value.context.attribute = rpgHT; value.context.kind = 'poison';
            value.context.modifier = self.hazard.resistanceModifier + value.entryModifier + dose.resistanceModifier + susceptibility.modifier + self.antidoteBonus() + self.treatmentBonus();
            local score = rpgLiteScore(self.profile,value.context);
            if (score == nil || score < 3) { value.reason = 'poison-resistance-score'; return value; }
        }
        local associated = self.assessAssociated();
        if (associated.status != 'ready') { value.reason = associated.reason; return value; }
        if (self.causesCondition())
        {
            if (!self.ofKind(RpgExpandedEnvironmentalPoisonExposure))
            { value.reason = 'poison-coughing-environment-required'; return value; }
            local score = rpgLiteScore(self.profile,value.context);
            if (score > 16) { value.reason = 'poison-nonpositive-failure-duration-unimplemented'; return value; }
            local tail = (18 - score) * 60;
            rpgInteger(rpgLedger.seconds,0,2147483647 - value.seconds - tail);
            local effect = self.newPoisonCondition(tail).assess();
            if (effect.status != 'ready') { value.reason = effect.reason; return value; }
        }
        else
        for (local amount = self.hazard.dice + self.hazard.adds; amount <= 6 * self.hazard.dice + self.hazard.adds; amount += 1)
        {
            local harm = self.hazard.fatigueDamage ? self.failureFatigue(amount * dose.damageMultiplier).assess()
                : self.failureWound(amount * dose.damageMultiplier).assess();
            if (harm.status != 'ready') { value.reason = harm.reason; return value; }
        }
        value.status = 'ready'; return value;
    }
    start()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        if (self.started) { value.status = 'reused'; return value; }
        self.started = true; self.startedAt = rpgLedger.seconds; self.dueAt = self.startedAt + value.seconds;
        self.remaining = self.hazard.cycles; self.entryModifier = value.entryModifier; self.boundDefinition = self.definition();
        self.profile.poisonExposures = self.profile.poisonExposures + [self];
        if (value.immune)
        {
            self.finished = true; self.remaining = 0; self.completedAt = rpgLedger.seconds;
            self.result = value;
        }
        value.status = 'resolved'; return value;
    }
    assessResolution()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        if (!self.started || rpgLedger.seconds != self.dueAt)
        { value.status = 'blocked'; value.reason = 'poison-resolution-not-due'; }
        return value;
    }
    resolve()
    {
        if (self.started && self.finished && self.result != nil && self.result.immune) return self.assess();
        if (self.cycleHistory.length() > 0) return self.cycleHistory[1].apply();
        local cycle = new RpgExpandedPoisonCycle(); cycle.id = 'onset'; cycle.exposure = self;
        return cycle.apply();
    }
    advance(seconds) { rpgExpandedReject('poison-use-shared-clock'); }
;
/** One owned, replayable cycle; create a new receipt for each later deadline. */
class RpgExpandedPoisonCycle: object
    id = nil
    exposure = nil
    completedAt = nil
    boundId = nil
    boundExposure = nil
    result = nil
    assess()
    {
        if (self.result != nil)
        {
            if (self.id != self.boundId || self.exposure != self.boundExposure
                || !holds(self.exposure.cycleHistory,self)) rpgExpandedReject('poison-cycle-binding');
            self.exposure.validateReceipt();
            local reused = new RpgExpandedPoisonResult(); reused.status = 'reused';
            reused.check = self.result.check; reused.injury = self.result.injury;
            reused.wound = self.result.wound; reused.resisted = self.result.resisted;
            reused.fatigue = self.result.fatigue; reused.fatigueLoss = self.result.fatigueLoss; reused.condition = self.result.condition; return reused;
        }
        if (self.id == nil || self.id == '' || self.exposure == nil
            || !self.exposure.ofKind(RpgExpandedPoisonExposure)) rpgExpandedReject('poison-cycle-definition');
        if (self.exposure.ofKind(RpgExpandedEnvironmentalPoisonExposure)
            && !self.ofKind(RpgExpandedEnvironmentalPoisonCycle)) rpgExpandedReject('poison-environment-cycle-required');
        foreach (local prior in self.exposure.cycleHistory)
            if (prior.id == self.id) rpgExpandedReject('poison-cycle-duplicate');
        local value = self.exposure.assessResolution();
        if (self.exposure.finished) { value.status = 'blocked'; value.reason = 'poison-already-ended'; }
        if (value.status == 'ready')
            foreach (local wound in self.exposure.profile.expandedWounds)
                if (wound.id == 'poison-' + self.exposure.id + '-' + self.id)
                    rpgExpandedReject('poison-cycle-wound-duplicate');
        if (value.status == 'ready' && self.exposure.hazard.fatigueDamage)
        {
            local e = self.exposure;
            local loss = e.failureFatigue((6 * e.hazard.dice + e.hazard.adds) * e.doseAssessment().damageMultiplier);
            loss.id = 'poison-' + e.id + '-' + self.id;
            local assessed = loss.assess();
            if (assessed.status != 'ready') { value.status = 'blocked'; value.reason = assessed.reason; }
        }
        return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        local e = self.exposure;
        if (value.context != nil) value.check = rpgLiteCheck(e.profile,value.context);
        value.resisted = value.check != nil && value.check.achieved;
        if (!value.resisted && e.associatedCondition != nil && !e.associatedApplied)
        {
            local associated = e.associatedCondition.apply();
            if (associated.status != 'resolved') rpgExpandedReject('poison-associated-condition-changed');
            e.associatedApplied = true; value.condition = e.associatedCondition;
        }
        if (!value.resisted && e.causesCondition())
        {
            value.condition = e.newPoisonCondition(-value.check.margin * 60);
            local effect = value.condition.apply();
            if (effect.status != 'resolved') rpgExpandedReject('poison-coughing-changed');
            e.condition = value.condition;
        }
        else if (!value.resisted)
        {
            local baseDamage = e.hazard.dice == 0 ? e.hazard.adds : rpgLiteRollDamage(e.hazard.dice,e.hazard.adds,'tox',nil);
            local amount = baseDamage * e.doseAssessment().damageMultiplier;
            if (e.hazard.fatigueDamage)
            {
                value.fatigueLoss = e.failureFatigue(amount); value.fatigueLoss.id = 'poison-' + e.id + '-' + self.id;
                local harm = value.fatigueLoss.apply();
                if (harm.status != 'resolved') rpgExpandedReject('poison-fatigue-changed');
                value.injury = harm.injuryAdded; value.fatigue = harm.fatigueAdded;
            }
            else
            {
                value.wound = e.failureWound(amount); value.wound.id = 'poison-' + e.id + '-' + self.id;
                local harm = value.wound.apply();
                if (harm.status != 'resolved') rpgExpandedReject('poison-injury-changed');
                value.injury = harm.healthLoss;
            }
            if (e.hasDexteritySymptoms()) e.symptomInjury += value.injury;
        }
        self.completedAt = rpgLedger.seconds; self.boundId = self.id; self.boundExposure = e;
        value.status = 'resolved'; self.result = value; e.cycleHistory = e.cycleHistory + [self];
        e.remaining -= 1;
        if (value.resisted || e.remaining == 0 || e.profile.dead)
        {
            e.completedAt = rpgLedger.seconds; e.remaining = 0; e.finished = true;
            e.lockedInjury = 0; e.lockedFatigue = 0; e.result = value;
        }
        else { e.lockedInjury += value.injury; e.lockedFatigue += value.fatigue; e.dueAt += e.doseAssessment().intervalSeconds; }
        return value;
    }
;
modify RpgExpandedProfile
    poisonExposures = []
    cyclicPoisonInjury()
    {
        local total = 0;
        foreach (local exposure in self.poisonExposures)
        {
            exposure.validateReceipt(); rpgInteger(exposure.lockedInjury,0,self.injury - total);
            total += exposure.lockedInjury;
        }
        return total;
    }
    poisonHealingAvailable()
    {
        local protected = self.cyclicPoisonInjury() + self.clottingProtectedInjury()
            + self.diseaseInjury + self.temperatureInjury;
        rpgInteger(protected,0,self.injury); return self.injury - protected;
    }
    validateHealing(amount)
    {
        inherited(amount);
        if (self.cyclicPoisonInjury() > 0 && amount > self.poisonHealingAvailable())
            rpgExpandedReject('poison-protected-healing');
        return nil;
    }
    naturalRecoveryNeeded()
    { return (self.cyclicPoisonInjury() == 0 || self.poisonHealingAvailable() > 0) && inherited(); }
    naturalRecoveryAmount()
    {
        local amount = inherited(); if (self.cyclicPoisonInjury() == 0) return amount;
        local available = self.poisonHealingAvailable(); return amount > available ? available : amount;
    }
;
modify rpgLedger
    validateAdvance(seconds)
    {
        inherited(seconds);
        for (local exposure = firstObj(RpgExpandedPoisonExposure); exposure != nil;
            exposure = nextObj(exposure,RpgExpandedPoisonExposure))
            if (exposure.started && !exposure.finished && !exposure.profile.dead)
            {
                exposure.validateReceipt();
                if (self.seconds + seconds > exposure.dueAt) rpgExpandedReject('poison-onset-boundary');
            }
        return nil;
    }
;


/** full-2008 B439: author-defined medicine for one identified agent. */
class RpgExpandedAntidote: RpgLiteItem
    targetHazard = nil
    resistanceBonus = 0
    endsExposure = nil
    effectEvidence = nil
;
class RpgExpandedAntidoteAdministration: object
    id = nil
    exposure = nil
    medicine = nil
    approved = nil
    identification = nil
    administrator = nil
    identificationEvidence = nil
    administrationEvidence = nil
    administeredAt = nil
    boundDefinition = nil
    result = nil
    definition()
    {
        return [self.id,self.exposure,self.medicine,self.approved,self.identification,self.administrator,self.identificationEvidence,
            self.administrationEvidence,self.medicine.targetHazard,self.medicine.resistanceBonus,
            self.medicine.endsExposure,self.medicine.effectEvidence];
    }
    validateReceipt()
    {
        if (self.result == nil || self.boundDefinition == nil
            || !holds(self.exposure.profile.poisonAntidotes,self)) rpgExpandedReject('antidote-history');
        local current = self.definition();
        for (local index = 1; index <= current.length(); index += 1)
            if (current[index] != self.boundDefinition[index]) rpgExpandedReject('antidote-binding');
        if (self.identification != nil) self.identification.validateReceipt();
        self.exposure.validateReceipt(); return nil;
    }
    assess()
    {
        if (self.id == nil || self.id == '' || self.exposure == nil
            || !self.exposure.ofKind(RpgExpandedPoisonExposure) || self.medicine == nil
            || !self.medicine.ofKind(RpgExpandedAntidote)) rpgExpandedReject('antidote-definition');
        local value = new RpgExpandedResult();
        if (self.result != nil) { self.validateReceipt(); value.status = 'reused'; return value; }
        local e = self.exposure; local patient = e.profile;
        if (!e.started || e.finished) { value.reason = 'antidote-active-exposure-required'; return value; }
        e.validateReceipt(); rpgExpandedValidate(patient);
        if (patient.dead) { value.reason = 'antidote-patient-dead'; return value; }
        if (!self.approved || self.identification == nil && (self.identificationEvidence == nil || self.identificationEvidence == '')
            || self.administrationEvidence == nil || self.administrationEvidence == ''
            || self.medicine.effectEvidence == nil || self.medicine.effectEvidence == '')
        { value.reason = 'antidote-authored-evidence-required'; return value; }
        if (self.identification != nil)
        {
            if (!self.identification.ofKind(RpgExpandedPoisonIdentification)
                || self.administrator == nil || !self.administrator.ofKind(RpgLiteProfile))
                rpgExpandedReject('antidote-identification-definition');
            self.identification.validateReceipt();
            if (self.identification.exposure != e || self.identification.examiner != self.administrator
                || !self.identification.result.identified)
            { value.reason = 'antidote-not-identified'; return value; }
            if (self.administrator.voluntaryMovementUnavailable() || self.administrator.dead || self.administrator.unconscious || self.administrator.mortal
                || self.administrator.stunned || self.administrator.mentalStun)
            { value.reason = 'antidote-administrator-condition'; return value; }
        }
        if (self.medicine.targetHazard != e.hazard)
        { value.reason = 'antidote-agent-mismatch'; return value; }
        rpgInteger(self.medicine.resistanceBonus,0,100);
        if (self.medicine.endsExposure ? self.medicine.resistanceBonus != 0 : self.medicine.resistanceBonus == 0)
        { value.reason = 'antidote-effect-definition'; return value; }
        if (!self.medicine.endsExposure && !e.hazard.resistible)
        { value.reason = 'antidote-resistance-unavailable'; return value; }
        foreach (local treatment in patient.poisonTreatments)
            if (treatment.exposure == e)
            { value.reason = 'antidote-combined-treatment-unimplemented'; return value; }
        foreach (local prior in patient.poisonAntidotes)
        {
            prior.validateReceipt();
            if (prior.id == self.id) rpgExpandedReject('antidote-duplicate');
            if (prior.exposure == e)
            { value.reason = 'antidote-combined-treatment-unimplemented'; return value; }
        }
        rpgInteger(self.medicine.quantity,0,1000000);
        if (!holds(patient.equipment,self.medicine) || self.medicine.quantity == 0 || !self.medicine.usableBy(patient))
        { value.reason = 'antidote-supply'; return value; }
        local count = 0;
        for (local owner = firstObj(RpgLiteProfile); owner != nil; owner = nextObj(owner,RpgLiteProfile))
            foreach (local item in owner.equipment) if (item == self.medicine) count += 1;
        if (count != 1) rpgExpandedReject('antidote-supply-ownership');
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        local e = self.exposure; local patient = e.profile;
        self.medicine.quantity -= 1;
        if (self.medicine.quantity == 0)
        {
            local remaining = [];
            foreach (local item in patient.equipment) if (item != self.medicine) remaining = remaining + [item];
            patient.equipment = remaining;
        }
        self.administeredAt = rpgLedger.seconds; self.boundDefinition = self.definition();
        value.status = 'resolved'; self.result = value;
        patient.poisonAntidotes = patient.poisonAntidotes + [self];
        if (self.medicine.endsExposure)
        {
            e.finished = true; e.remaining = 0; e.lockedInjury = 0; e.lockedFatigue = 0; e.completedAt = rpgLedger.seconds;
            e.result = new RpgExpandedPoisonResult(); e.result.status = 'resolved';
        }
        return value;
    }
;
modify RpgExpandedProfile
    poisonAntidotes = []
;
modify RpgExpandedPoisonExposure
    antidoteBonus()
    {
        local bonus = 0;
        foreach (local care in self.profile.poisonAntidotes)
        {
            care.validateReceipt();
            if (care.exposure == self && !care.medicine.endsExposure) bonus += care.medicine.resistanceBonus;
        }
        return bonus;
    }
;


class RpgExpandedPoisonTreatmentResult: RpgExpandedResult
    context = nil
    resistanceBonus = 0
;
/** full-2008 B439. Suitability is an explicit fact about the identified agent;
 * harmful exceptions require their own effect and are not treated as safe care. */
class RpgExpandedPoisonTreatment: object
    id = nil
    exposure = nil
    healer = nil
    skill = nil
    kind = 'wound'
    suitable = nil
    approved = nil
    identification = nil
    identificationEvidence = nil
    suitabilityEvidence = nil
    medicalSeconds = nil
    medicalBonus = nil
    medicalTechnology = nil
    completedAt = nil
    boundDefinition = nil
    result = nil
    duration() { return self.kind == 'wound' ? 60 : self.kind == 'digestive' ? 10 : self.medicalSeconds; }
    definition()
    {
        return [self.id,self.exposure,self.healer,self.skill,self.skill.techLevel,self.kind,self.suitable,
            self.approved,self.identification,self.identificationEvidence,self.suitabilityEvidence,self.medicalSeconds,
            self.medicalBonus,self.medicalTechnology];
    }
    validateReceipt()
    {
        if (self.result == nil || !holds(self.exposure.profile.poisonTreatments,self))
            rpgExpandedReject('poison-treatment-history');
        local current = self.definition();
        for (local index = 1; index <= current.length(); index += 1)
            if (current[index] != self.boundDefinition[index]) rpgExpandedReject('poison-treatment-binding');
        if (self.identification != nil) self.identification.validateReceipt();
        self.exposure.validateReceipt(); return nil;
    }
    prepare()
    {
        local value = new RpgExpandedPoisonTreatmentResult(); local e = self.exposure;
        if (!e.started || e.finished || e.profile.dead || !e.hazard.resistible)
        { value.reason = 'poison-treatment-active-resistible-exposure'; return value; }
        e.validateReceipt();
        if (!self.approved || !self.suitable || self.identification == nil && (self.identificationEvidence == nil || self.identificationEvidence == '')
            || self.suitabilityEvidence == nil || self.suitabilityEvidence == '')
        { value.reason = 'poison-treatment-suitability-required'; return value; }
        if (self.identification != nil)
        {
            if (!self.identification.ofKind(RpgExpandedPoisonIdentification)) rpgExpandedReject('poison-treatment-identification-type');
            self.identification.validateReceipt();
            if (self.identification.exposure != e || self.identification.examiner != self.healer || !self.identification.result.identified)
            { value.reason = 'poison-treatment-not-identified'; return value; }
        }
        if ((self.kind == 'wound' && !holds(['blood','follow-up'],e.entry.route))
            || (self.kind == 'digestive' && e.entry.route != 'digestive'))
        { value.reason = 'poison-treatment-route'; return value; }
        if (self.healer.voluntaryMovementUnavailable() || self.healer.dead || self.healer.unconscious || self.healer.mortal || self.healer.stunned || self.healer.mentalStun)
        { value.reason = 'poison-treatment-healer-condition'; return value; }
        foreach (local prior in e.profile.poisonTreatments)
        {
            prior.validateReceipt();
            if (prior.id == self.id) rpgExpandedReject('poison-treatment-duplicate');
            if (prior.exposure == e) { value.reason = 'poison-treatment-repeat-unimplemented'; return value; }
        }
        foreach (local antidote in e.profile.poisonAntidotes)
            if (antidote.exposure == e) { value.reason = 'poison-treatment-combination-unimplemented'; return value; }
        value.context = new RpgLiteContext(); value.context.skill = self.skill; value.context.kind = 'poison-treatment';
        value.context.modifier = self.kind == 'wound' ? -2 : 0;
        if (self.kind == 'medical')
        {
            local technology = rpgExpandedTechnologyModifier(self.skill.techLevel,self.medicalTechnology,true);
            if (technology == nil) { value.reason = 'poison-treatment-technology'; return value; }
            value.context.modifier += technology;
        }
        local score = rpgLiteScore(self.healer,value.context);
        if (score == nil || score < 3) { value.reason = 'poison-treatment-score'; return value; }
        value.resistanceBonus = self.kind == 'medical' ? self.medicalBonus : 2;
        value.seconds = self.duration(); value.status = 'ready'; return value;
    }
    assess()
    {
        if (self.id == nil || self.id == '' || self.exposure == nil || !self.exposure.ofKind(RpgExpandedPoisonExposure)
            || self.healer == nil || !self.healer.ofKind(RpgLiteProfile) || self.skill == nil
            || !self.skill.ofKind(RpgLiteSkill) || self.skill.techLevel == nil
            || !holds(['wound','digestive','medical'],self.kind)
            || !holds(['first-aid','physician'],self.skill.id)
            || (self.kind == 'medical' && self.skill.id != 'physician')) rpgExpandedReject('poison-treatment-definition');
        if (self.result != nil)
        {
            self.validateReceipt(); local reused = new RpgExpandedPoisonTreatmentResult(); reused.status = 'reused';
            reused.check = self.result.check; reused.resistanceBonus = self.result.resistanceBonus; return reused;
        }
        if (self.kind == 'medical')
        {
            rpgInteger(self.medicalTechnology,0,12); local maximum = (self.medicalTechnology + 1) / 2;
            rpgInteger(self.medicalBonus,1,maximum > 0 ? maximum : 1);
        }
        rpgInteger(self.duration(),1,86400); rpgInteger(rpgLedger.seconds,0,2147483647 - self.duration());
        local value = self.prepare(); if (value.status == 'ready') rpgLedger.validateAdvance(self.duration());
        return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        local definition = self.definition(); local started = rpgLedger.seconds;
        rpgSpendTime(self.duration()); local current = self.definition();
        for (local index = 1; index <= current.length(); index += 1)
            if (current[index] != definition[index]) rpgExpandedReject('poison-treatment-interrupted');
        if (rpgLedger.seconds != started + self.duration()) rpgExpandedReject('poison-treatment-clock');
        value = self.prepare(); if (value.status != 'ready') rpgExpandedReject(value.reason);
        value.check = rpgLiteCheck(self.healer,value.context);
        if (!value.check.achieved) value.resistanceBonus = 0;
        self.completedAt = rpgLedger.seconds; self.boundDefinition = self.definition();
        self.exposure.profile.poisonTreatments = self.exposure.profile.poisonTreatments + [self];
        value.status = 'resolved'; self.result = value; return value;
    }
;
modify RpgExpandedProfile
    poisonTreatments = []
;
modify RpgExpandedPoisonExposure
    treatmentBonus()
    {
        local bonus = 0;
        foreach (local treatment in self.profile.poisonTreatments)
        {
            treatment.validateReceipt();
            if (treatment.exposure == self) bonus += treatment.result.resistanceBonus;
        }
        return bonus;
    }
;


/** B439 abstract dose stock and ordinary point/edge coating. */
class RpgExpandedPoisonStock: RpgLiteItem
    techLevel = nil
    legality = nil
    hazard = nil
;
class RpgExpandedCoatingResult: RpgExpandedResult
    doses = 0
;
class RpgExpandedWeaponCoating: object
    id = nil
    profile = nil
    weapon = nil
    stock = nil
    mode = nil
    reachYards = 1
    approved = nil
    evidence = nil
    appliedAt = nil
    boundDefinition = nil
    result = nil
    contacts = []
    defendedContacts = 0
    depleted = nil
    definition() { return [self.id,self.profile,self.weapon,self.stock,self.stock.hazard,self.mode,
        self.mode.damageType,self.mode.ranged,self.reachYards,self.approved,self.evidence]; }
    validateReceipt()
    {
        if (self.result == nil || !holds(self.profile.poisonCoatings,self)) rpgExpandedReject('coating-history');
        local current = self.definition();
        for (local index = 1; index <= current.length(); index += 1)
            if (current[index] != self.boundDefinition[index]) rpgExpandedReject('coating-binding');
        return nil;
    }
    assess()
    {
        if (self.id == nil || self.id == '' || self.profile == nil || !self.profile.ofKind(RpgExpandedProfile)
            || self.weapon == nil || !self.weapon.ofKind(RpgLiteWeapon) || self.stock == nil
            || !self.stock.ofKind(RpgExpandedPoisonStock) || self.mode == nil || !self.mode.ofKind(RpgLiteAttackMode)
            || self.stock.hazard == nil || self.stock.hazard.kind != 'poison') rpgExpandedReject('coating-definition');
        local value = new RpgExpandedCoatingResult();
        if (self.result != nil) { self.validateReceipt(); value.status = 'reused'; return value; }
        if (!self.approved || self.evidence == nil || self.evidence == '')
        { value.reason = 'coating-ordinary-behavior-evidence'; return value; }
        if (self.mode.ranged || !holds(['cut','imp','pi','pi-','pi+','pi++'],self.mode.damageType))
        { value.reason = 'coating-mode-unimplemented'; return value; }
        rpgInteger(self.reachYards,1,100); rpgInteger(self.stock.quantity,0,1000000);
        local doses = self.mode.damageType == 'cut' ? 3 * self.reachYards : 1;
        if (!holds(self.weapon.modes,self.mode) || !holds(self.profile.equipment,self.weapon)
            || !holds(self.profile.equipment,self.stock) || self.stock.quantity < doses
            || !self.stock.usableBy(self.profile)) { value.reason = 'coating-supply'; return value; }
        local stockOwners = 0; local weaponOwners = 0;
        for (local owner = firstObj(RpgLiteProfile); owner != nil; owner = nextObj(owner,RpgLiteProfile))
            foreach (local item in owner.equipment)
            { if (item == self.stock) stockOwners += 1; if (item == self.weapon) weaponOwners += 1; }
        if (stockOwners != 1 || weaponOwners != 1) rpgExpandedReject('coating-supply-ownership');
        foreach (local prior in self.profile.poisonCoatings)
            if (prior.id == self.id) rpgExpandedReject('coating-duplicate');
        if (self.weapon.poisonCoating != nil && !self.weapon.poisonCoating.depleted)
        { value.reason = 'coating-already-present'; return value; }
        value.doses = doses; value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        self.stock.quantity -= value.doses;
        if (self.stock.quantity == 0)
        {
            local remaining = [];
            foreach (local item in self.profile.equipment) if (item != self.stock) remaining = remaining + [item];
            self.profile.equipment = remaining;
        }
        self.appliedAt = rpgLedger.seconds; self.boundDefinition = self.definition();
        self.profile.poisonCoatings = self.profile.poisonCoatings + [self]; self.weapon.poisonCoating = self;
        value.status = 'resolved'; self.result = value; return value;
    }
    validateAttack(attacker, attackMode)
    {
        self.validateReceipt();
        if (self.depleted) return nil;
        if (attacker.profile != self.profile || attacker.weapon != self.weapon || attackMode != self.mode)
            rpgExpandedReject('coating-attack-mode-unimplemented');
        return nil;
    }
    recordStrike(strike)
    {
        self.validateReceipt();
        if (holds(self.contacts,strike) || self.depleted) return nil;
        if (strike.status != 'resolved' || !holds(['hit','miss','defended'],strike.outcome))
            rpgExpandedReject('coating-strike-outcome');
        self.contacts = self.contacts + [strike];
        if (strike.outcome == 'hit') self.depleted = true;
        if (strike.outcome == 'defended' && holds(['block','parry','parry-other'],strike.successfulDefense))
        { self.defendedContacts += 1; if (self.defendedContacts >= 3) self.depleted = true; }
        return nil;
    }
;
modify RpgExpandedProfile
    poisonCoatings = []
;
modify RpgLiteWeapon
    poisonCoating = nil
    validateStrike(attacker, mode)
    {
        inherited(attacker,mode);
        if (self.poisonCoating != nil) self.poisonCoating.validateAttack(attacker,mode);
        return nil;
    }
    afterStrike(attacker, mode, result)
    {
        inherited(attacker,mode,result);
        if (self.poisonCoating != nil) self.poisonCoating.recordStrike(result);
        return nil;
    }
;


/** Neutral executable catalogue subset, full-2008 B439. Values are fixed to the
 * supplied printing; use an ordinary hazard for original authored agents. */
class RpgExpandedCataloguePoison: RpgLiteHazard
    catalogueId = nil
    deliveryMethod = nil
    unpreparedFear = nil
    dexteritySymptoms = nil
    coughingEffect = nil
    blindingEffect = nil
    route = nil
    techLevel = 0
    unitCost = 0
    legality = 1
    signature() { return [self.kind,self.delay,self.interval,self.cycles,self.dice,self.adds,
        self.fatigueDamage,self.resistible,self.resistanceModifier,self.techLevel,self.unitCost,self.legality,self.deliveryMethod,self.unpreparedFear,self.dexteritySymptoms,self.coughingEffect,self.blindingEffect]; }
    validateCatalogue()
    {
        local expected = rpgExpandedPoisonCatalogue(self.catalogueId,self.route).signature();
        local actual = self.signature();
        for (local index = 1; index <= actual.length(); index += 1)
            if (actual[index] != expected[index]) rpgExpandedReject('poison-catalogue-modified');
        return nil;
    }
;
rpgExpandedPoisonCatalogue(id, route)
{
    local value = new RpgExpandedCataloguePoison(); value.kind = 'poison';
    value.catalogueId = id; value.route = route;
    if (id == 'delayed-ingested-agent')
    {
        if (route != 'digestive') rpgExpandedReject('poison-catalogue-route');
        value.techLevel = 1; value.unitCost = 1; value.delay = 3600;
        value.interval = 3600; value.cycles = 8; value.dice = 1; value.resistanceModifier = -2;
    }
    else if (id == 'rapid-systemic-agent')
    {
        if (!holds(['follow-up','respiratory','contact','digestive'],route)) rpgExpandedReject('poison-catalogue-route');
        value.techLevel = 4; value.unitCost = 2; value.resistible = nil; value.dice = 4;
        value.delay = holds(['follow-up','respiratory'],route) ? 0 : 900;
    }
    else if (id == 'injected-venom')
    {
        if (route != 'follow-up') rpgExpandedReject('poison-catalogue-route');
        value.techLevel = 0; value.unitCost = 10; value.delay = 60; value.resistanceModifier = -3;
        value.dice = 2; value.interval = 3600; value.cycles = 6; value.dexteritySymptoms = true;
    }
    else if (id == 'dual-route-agent')
    {
        if (!holds(['contact','respiratory'],route)) rpgExpandedReject('poison-catalogue-route');
        value.techLevel = 6; value.unitCost = 10; value.legality = 0;
        value.deliveryMethod = 'area'; value.unpreparedFear = true;
        if (route == 'contact')
        {
            value.delay = 0; value.resistanceModifier = -4; value.dice = 0; value.adds = 1;
            value.interval = 28800; value.cycles = 24;
        }
        else
        {
            value.delay = 7200; value.resistanceModifier = -1; value.dice = 1;
            value.interval = 3600; value.cycles = 6;
        }
    }
    else if (id == 'neurological-agent')
    {
        if (route != 'contact') rpgExpandedReject('poison-catalogue-route');
        value.techLevel = 6; value.unitCost = 20; value.legality = 0;
        value.deliveryMethod = 'area'; value.unpreparedFear = true;
        value.delay = 0; value.resistanceModifier = -6; value.dice = 2;
        value.interval = 60; value.cycles = 6;
    }
    else if (id == 'combustion-smoke')
    {
        if (route != 'respiratory') rpgExpandedReject('poison-catalogue-route');
        value.techLevel = nil; value.unitCost = nil; value.legality = 4;
        value.deliveryMethod = 'area'; value.delay = 10; value.dice = 0; value.adds = 0; value.coughingEffect = true;
    }
    else if (id == 'dual-irritant')
    {
        if (!holds(['respiratory','sense'],route)) rpgExpandedReject('poison-catalogue-route');
        value.techLevel = 6; value.unitCost = 10; value.legality = 2; value.unpreparedFear = true;
        value.deliveryMethod = 'area'; value.delay = 0; value.resistanceModifier = -2; value.dice = 0; value.adds = 0;
        value.coughingEffect = route == 'respiratory'; value.blindingEffect = route == 'sense';
    }
    else rpgExpandedReject('poison-catalogue-entry-unimplemented');
    return value;
}
/** Return an unowned lot. The acquisition library charges cost for the whole lot;
 * market availability and permission remain explicit authored decisions. */
rpgExpandedPoisonCatalogueStock(stockId, catalogueId, route, doses)
{
    if (stockId == nil || stockId == '') rpgExpandedReject('poison-stock-id');
    rpgInteger(doses,1,1000000);
    local hazard = rpgExpandedPoisonCatalogue(catalogueId,route);
    if (hazard.unitCost == nil || hazard.techLevel == nil) rpgExpandedReject('poison-catalogue-not-marketed');
    local stock = new RpgExpandedPoisonStock(); stock.id = stockId; stock.hazard = hazard;
    stock.quantity = doses; stock.techLevel = hazard.techLevel; stock.legality = hazard.legality;
    stock.cost = doses * hazard.unitCost; return stock;
}


/** B439 symptom thresholds use exact fractions of full HP, never rounded-down HP. */
rpgExpandedVenomDexterityPenalty(capacity, injury)
{
    rpgInteger(capacity,1,1000000); rpgInteger(injury,0,100000000);
    if (injury * 3 >= capacity * 2) return -6;
    if (injury * 2 >= capacity) return -4;
    if (injury * 3 >= capacity) return -2;
    return 0;
}
modify RpgExpandedProfile
    poisonDexterityPenalty()
    {
        local penalty = 0;
        foreach (local exposure in self.poisonExposures)
            penalty += exposure.dexteritySymptomPenalty();
        return penalty;
    }
    healthAttributeModifier(context)
    {
        local value = inherited(context);
        if (context.controllingAttribute() == rpgDX && context.kind != 'defense' && !context.defensiveReaction)
            value += self.poisonDexterityPenalty();
        return value;
    }
    afterHealing()
    {
        inherited();
        foreach (local exposure in self.poisonExposures)
        {
            exposure.validateReceipt();
            if (exposure.symptomInjury > self.injury) exposure.symptomInjury = self.injury;
        }
        return nil;
    }
;


/** Reuse the owned fatigue/overflow procedure, retaining separate poison history. */
class RpgExpandedPoisonFatigueLoss: RpgExpandedFearFatigueLoss
    maximumAmount() { return 10000; }
    fatigueCause() { return 'poison'; }
    history() { return self.profile.poisonFatigueLosses; }
    remember() { self.profile.poisonFatigueLosses = self.profile.poisonFatigueLosses + [self]; }
    woundId(index)
    {
        local digits = ['0','1','2','3','4','5','6','7','8','9']; local suffix = '';
        while (index > 0) { suffix = digits[index % 10 + 1] + suffix; index /= 10; }
        return 'poison-fatigue-' + self.id + '-' + suffix;
    }
;
modify RpgExpandedProfile
    poisonFatigueLosses = []
    additionalRecoveryLockedFatigue()
    {
        local total = inherited();
        foreach (local exposure in self.poisonExposures)
        {
            exposure.validateReceipt(); rpgInteger(exposure.lockedFatigue,0,self.fatigue - total);
            total += exposure.lockedFatigue;
        }
        rpgInteger(total,0,self.fatigue - self.hunger - self.thirst - self.sleepDebt - self.temperatureFatigue);
        return total;
    }
;


class RpgExpandedPoisonIdentificationResult: RpgExpandedResult
    context = nil
    identified = nil
;
/** B439 concrete clue/symptom identification. Interrogation uses social play and
 * is not substituted by a generic skill check here. */
class RpgExpandedPoisonIdentification: object
    id = nil
    exposure = nil
    examiner = nil
    skill = nil
    clue = 'residue'
    observedSymptoms = nil
    approved = nil
    evidence = nil
    durationSeconds = nil
    conditionsModifier = 0
    completedAt = nil
    boundDefinition = nil
    result = nil
    definition() { return [self.id,self.exposure,self.examiner,self.skill,self.skill.techLevel,self.clue,
        self.observedSymptoms,self.approved,self.evidence,self.durationSeconds,self.conditionsModifier]; }
    validateReceipt()
    {
        if (self.result == nil || !holds(self.exposure.profile.poisonIdentifications,self))
            rpgExpandedReject('poison-identification-history');
        local current = self.definition();
        for (local index = 1; index <= current.length(); index += 1)
            if (current[index] != self.boundDefinition[index]) rpgExpandedReject('poison-identification-binding');
        self.exposure.validateReceipt(); return nil;
    }
    prepare()
    {
        local value = new RpgExpandedPoisonIdentificationResult(); local e = self.exposure;
        if (!e.started) { value.reason = 'poison-identification-exposure'; return value; }
        e.validateReceipt();
        if (!self.approved || self.evidence == nil || self.evidence == '')
        { value.reason = 'poison-identification-clue-required'; return value; }
        if (self.examiner.dead || self.examiner.unconscious || self.examiner.mortal || self.examiner.stunned || self.examiner.mentalStun)
        { value.reason = 'poison-identification-examiner'; return value; }
        if (self.clue == 'symptoms')
        {
            local effects = nil;
            foreach (local cycle in e.cycleHistory)
                if (cycle.result.injury > 0 || cycle.result.fatigue > 0 || cycle.result.condition != nil) effects = true;
            if (!self.observedSymptoms || !effects)
            { value.reason = 'poison-identification-no-symptoms'; return value; }
        }
        foreach (local prior in e.profile.poisonIdentifications)
        {
            prior.validateReceipt();
            if (prior.id == self.id) rpgExpandedReject('poison-identification-duplicate');
            if (prior.exposure == e && prior.examiner == self.examiner)
            { value.reason = 'poison-identification-retry-unimplemented'; return value; }
        }
        value.context = new RpgLiteContext(); value.context.skill = self.skill; value.context.kind = 'poison-identification';
        value.context.modifier = self.conditionsModifier + e.doseAssessment().detectionModifier;
        local score = rpgLiteScore(self.examiner,value.context);
        if (score == nil || score < 3) { value.reason = 'poison-identification-score'; return value; }
        value.seconds = self.durationSeconds; value.status = 'ready'; return value;
    }
    assess()
    {
        if (self.id == nil || self.id == '' || self.exposure == nil || !self.exposure.ofKind(RpgExpandedPoisonExposure)
            || self.examiner == nil || !self.examiner.ofKind(RpgLiteProfile) || self.skill == nil
            || !self.skill.ofKind(RpgLiteSkill) || !holds(['residue','animal','symptoms'],self.clue))
            rpgExpandedReject('poison-identification-definition');
        if (self.clue == 'residue' && self.skill.id != 'poisons'
            || self.clue == 'animal' && self.skill.id != 'naturalist'
            || self.clue == 'symptoms' && !holds(['poisons','diagnosis'],self.skill.id))
            rpgExpandedReject('poison-identification-skill');
        if (self.result != nil)
        {
            self.validateReceipt(); local reused = new RpgExpandedPoisonIdentificationResult(); reused.status = 'reused';
            reused.check = self.result.check; reused.identified = self.result.identified; return reused;
        }
        rpgInteger(self.durationSeconds,1,86400); rpgInteger(self.conditionsModifier,-100,100);
        rpgInteger(rpgLedger.seconds,0,2147483647 - self.durationSeconds);
        local value = self.prepare(); if (value.status == 'ready') rpgLedger.validateAdvance(self.durationSeconds);
        return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        local definition = self.definition(); local started = rpgLedger.seconds;
        rpgSpendTime(self.durationSeconds); local current = self.definition();
        for (local index = 1; index <= current.length(); index += 1)
            if (current[index] != definition[index]) rpgExpandedReject('poison-identification-interrupted');
        if (rpgLedger.seconds != started + self.durationSeconds) rpgExpandedReject('poison-identification-clock');
        value = self.prepare(); if (value.status != 'ready') rpgExpandedReject(value.reason);
        value.check = rpgLiteCheck(self.examiner,value.context); value.identified = value.check.achieved;
        self.completedAt = rpgLedger.seconds; self.boundDefinition = self.definition();
        self.exposure.profile.poisonIdentifications = self.exposure.profile.poisonIdentifications + [self];
        value.status = 'resolved'; self.result = value; return value;
    }
;
modify RpgExpandedProfile
    poisonIdentifications = []
;


/** B438 continuing area exposure. The same owned exposure retries until its
 * first failed resistance; after that, ordinary poison cycles continue. */
class RpgExpandedEnvironmentalPoisonExposure: RpgExpandedPoisonExposure
    environmentEvidence = nil
    environmentAffected = nil
    leftAt = nil
    leaveEvidence = nil
    definition() { return inherited() + [self.environmentEvidence]; }
    assess()
    {
        if (self.entry == nil || self.entry.method != 'area'
            || !holds(['blood','contact','respiratory','sense'],self.entry.route))
            rpgExpandedReject('poison-environment-route');
        if (self.environmentEvidence == nil || self.environmentEvidence == '')
        {
            local value = new RpgExpandedPoisonResult(); value.reason = 'poison-environment-evidence'; return value;
        }
        return inherited();
    }
    retrySeconds()
    {
        local delay = self.doseAssessment().delaySeconds; return delay > 0 ? delay : 1;
    }
    resolve()
    {
        if (self.started && self.finished && self.result != nil && self.result.immune) return self.assess();
        if (self.cycleHistory.length() > 0) return self.cycleHistory[1].apply();
        local cycle = new RpgExpandedEnvironmentalPoisonCycle(); cycle.id = 'onset'; cycle.exposure = self;
        return cycle.apply();
    }
    leave(evidence)
    {
        if (!self.started) rpgExpandedReject('poison-environment-not-started');
        self.validateReceipt();
        if (evidence == nil || evidence == '') rpgExpandedReject('poison-environment-leave-evidence');
        local value = new RpgExpandedPoisonResult();
        if (self.leftAt != nil)
        {
            if (evidence != self.leaveEvidence) rpgExpandedReject('poison-environment-leave-binding');
            value.status = 'reused'; return value;
        }
        if (self.condition != nil)
        {
            self.condition.validateReceipt();
            rpgInteger(rpgLedger.seconds,0,2147483647 - self.condition.durationSeconds);
        }
        self.leftAt = rpgLedger.seconds; self.leaveEvidence = evidence;
        if (self.condition != nil) self.condition.expiresAt = self.leftAt + self.condition.durationSeconds;
        if (!self.environmentAffected && !self.finished)
        {
            self.finished = true; self.remaining = 0; self.completedAt = rpgLedger.seconds;
            self.result = new RpgExpandedPoisonResult(); self.result.status = 'resolved';
            self.result.reason = 'left-poison-environment';
        }
        value.status = 'resolved'; return value;
    }
;
class RpgExpandedEnvironmentalPoisonCycle: RpgExpandedPoisonCycle
    assess()
    {
        if (self.exposure == nil || !self.exposure.ofKind(RpgExpandedEnvironmentalPoisonExposure))
            rpgExpandedReject('poison-environment-cycle-owner');
        local value = inherited();
        if (value.status == 'ready' && self.exposure.hazard.resistible
            && !self.exposure.environmentAffected && self.exposure.leftAt == nil)
        {
            local e = self.exposure; local interval = e.doseAssessment().intervalSeconds;
            rpgInteger(rpgLedger.seconds,0,2147483647 - e.retrySeconds() - (e.hazard.cycles - 1) * interval);
        }
        return value;
    }
    apply()
    {
        local value = inherited(); if (value.status != 'resolved') return value;
        local e = self.exposure;
        if (!value.resisted) e.environmentAffected = true;
        else if (!e.environmentAffected && e.leftAt == nil)
        {
            e.finished = nil; e.completedAt = nil; e.result = nil;
            e.remaining = e.hazard.cycles; e.dueAt = rpgLedger.seconds + e.retrySeconds();
        }
        return value;
    }
;


class RpgExpandedPoisonSusceptibilityResult: RpgExpandedResult
    immune = nil
;
/** B438 author decision for a specific physiology and agent, not a label lookup. */
class RpgExpandedPoisonSusceptibility: object
    profile = nil
    hazard = nil
    physiology = nil
    approved = nil
    evidence = nil
    immune = nil
    resistanceModifier = 0
    signature() { return [self.profile,self.hazard,self.physiology,self.approved,self.evidence,self.immune,self.resistanceModifier]; }
    assess(patient, agent)
    {
        local value = new RpgExpandedPoisonSusceptibilityResult();
        if (self.profile != patient || self.hazard != agent)
        { value.reason = 'poison-susceptibility-target'; return value; }
        if (!self.approved || self.physiology == nil || self.physiology == '' || self.evidence == nil || self.evidence == '')
        { value.reason = 'poison-susceptibility-evidence'; return value; }
        rpgInteger(self.resistanceModifier,-100,100);
        if (self.immune && self.resistanceModifier != 0 || !agent.resistible && self.resistanceModifier != 0)
        { value.reason = 'poison-susceptibility-combination'; return value; }
        value.immune = self.immune; value.modifier = self.resistanceModifier;
        value.status = 'ready'; return value;
    }
;


/** B439 coughing persists in the environment, then for failure-margin minutes. */
class RpgExpandedEnvironmentalCoughing: RpgExpandedCoughing
    exposure = nil
    definition() { return inherited() + [self.exposure]; }
    validateReceipt()
    {
        if (self.result == nil || self.exposure == nil || self.exposure.condition != self
            || self.profile != self.exposure.profile || !holds(self.history(),self))
            rpgExpandedReject('environmental-coughing-history');
        local current = self.definition();
        for (local index = 1; index <= current.length(); index += 1)
            if (current[index] != self.boundDefinition[index]) rpgExpandedReject('environmental-coughing-binding');
        self.exposure.validateReceipt();
        if (self.exposure.leftAt == nil ? self.expiresAt != nil : self.expiresAt != self.exposure.leftAt + self.durationSeconds)
            rpgExpandedReject('environmental-coughing-expiry');
        return nil;
    }
    active()
    {
        self.validateReceipt();
        return !self.profile.dead && (self.expiresAt == nil || rpgLedger.seconds < self.expiresAt);
    }
    apply()
    {
        local value = inherited();
        if (value.status == 'resolved') self.expiresAt = nil;
        return value;
    }
;


class RpgExpandedEnvironmentalBlindness: RpgExpandedEnvironmentalCoughing
    history() { return self.profile.temporaryBlindnessHistory; }
    remember() { self.profile.temporaryBlindnessHistory = self.profile.temporaryBlindnessHistory + [self]; }
    receiptKind() { return 'environmental-blindness'; }
;
/** B439 authored opacity density, applied to actual whole yards of cloud crossed. */
rpgExpandedIrritantCloudVision(yards, penaltyPerYard)
{
    rpgInteger(yards,0,1000000); rpgInteger(penaltyPerYard,1,3);
    return -yards * penaltyPerYard;
}
modify RpgLiteContext
    irritantCloudYards = 0
    irritantCloudPenaltyPerYard = 1
;
modify RpgExpandedProfile
    healthAttributeModifier(context)
    {
        local value = inherited(context);
        if (context.kind == 'vision') value += rpgExpandedIrritantCloudVision(context.irritantCloudYards,context.irritantCloudPenaltyPerYard);
        return value;
    }
;

class RpgExpandedCollisionAssessment: RpgExpandedResult
    damageDice = 0
    damageAdds = 0
    capacity = 0
    velocity = 0
    damageType = 'cr'
    velocityScale = 1
;
/** B430-B431: capacity is full HP, not remaining HP. Hard means immovable hard surface. */
rpgExpandedAssessCollision(capacity,velocity,hard)
{ return rpgExpandedAssessScaledCollision(capacity,velocity,1,hard); }

/** Fixed-point velocity preserves fractional yards/second without early rounding. */
rpgExpandedAssessScaledCollision(capacity,velocity,scale,hard)
{
    if (!holds([1,10,100,1000],scale)) rpgExpandedReject('collision-velocity-scale');
    rpgInteger(capacity,1,1000000); rpgInteger(velocity,0,10000*scale);
    local value = new RpgExpandedCollisionAssessment();
    value.capacity = capacity * (hard ? 2 : 1); value.velocity = velocity; value.velocityScale = scale;
    if (velocity != 0)
    {
        rpgInteger(value.capacity,1,2147483647 / velocity);
        local numerator = value.capacity * velocity; local denominator = 100*scale;
        if (numerator < denominator)
        {
            value.damageDice = 1;
            value.damageAdds = numerator <= denominator/4 ? -3 : numerator <= denominator/2 ? -2 : -1;
        }
        else value.damageDice = numerator/denominator + (numerator%denominator >= denominator/2 ? 1 : 0);
    }
    value.status = 'ready'; return value;
}

class RpgExpandedFallProtectionAssessment: RpgExpandedResult
    penetratingDamage = 0
    bluntInjury = 0
    stoppedDamage = 0
;
/** B431/B379: one homogeneous protection layer, prior to location injury modifiers.
 * Mixed innate/armor layers require explicit ordering and are not represented here. */
rpgExpandedAssessFallProtection(damage,resistance,kind)
{
    rpgInteger(damage,0,100000000); rpgInteger(resistance,0,100000000);
    if (!holds(['armor','innate'],kind)) rpgExpandedReject('fall-protection-kind');
    local value = new RpgExpandedFallProtectionAssessment();
    value.stoppedDamage = damage < resistance ? damage : resistance;
    value.penetratingDamage = damage - value.stoppedDamage;
    if (kind == 'armor' && value.penetratingDamage == 0) value.bluntInjury = damage / 5;
    value.status = 'ready'; return value;
}

modify RpgExpandedProfile
    fallInjuries = []
;
class RpgExpandedFallInjuryResult: RpgExpandedResult
    protection = nil
    wound = nil
    impactDamage = 0
    cushionedDamage = 0
;
/** Owned bridge from an already resolved fall damage roll to torso injury.
 * Location rules, mixed protection and special anatomy must not use this adapter. */
class RpgExpandedFallInjury: object
    id = nil
    profile = nil
    damage = 0
    fall = nil
    landing = nil
    damageVelocity = nil
    obstacleHP = nil
    obstacleDR = nil
    cushionDR = 0
    cushionEvidence = nil
    resistance = 0
    protectionKind = 'armor'
    location = 'torso'
    bodyPart = nil
    locationEvidence = nil
    approved = nil
    evidence = nil
    dropDestination = nil
    result = nil
    boundDefinition = nil
    committedAt = nil
    definition()
    { return [self.id,self.profile,self.damage,self.resistance,self.protectionKind,self.location,
        self.approved,self.evidence,self.dropDestination,self.obstacleHP,self.obstacleDR,
        self.cushionDR,self.cushionEvidence,self.fall,self.landing,self.damageVelocity,
        self.bodyPart,self.locationEvidence]; }
    assess()
    {
        if (self.id == nil || self.id == '' || self.profile == nil || !self.profile.ofKind(RpgExpandedProfile))
            rpgExpandedReject('fall-injury-definition');
        local landingResult = nil;
        if (self.landing != nil)
        {
            if (!self.landing.ofKind(RpgExpandedLandingReceipt) || self.fall == nil)
                rpgExpandedReject('fall-injury-landing');
            landingResult = self.landing.impactFor(self.profile,self.fall);
        }
        local value = new RpgExpandedFallInjuryResult();
        if (self.result != nil)
        {
            local current = self.definition();
            for (local index = 1; index <= current.length(); index += 1)
                if (current[index] != self.boundDefinition[index]) rpgExpandedReject('fall-injury-binding');
            if (!holds(self.profile.fallInjuries,self) || self.result.wound.assess().status != 'reused')
                rpgExpandedReject('fall-injury-history');
            value.status = 'reused'; return value;
        }
        if (!self.approved || self.evidence == nil || self.evidence == '')
        { value.reason = 'fall-injury-author-facts'; return value; }
        if (!holds(['torso','hand','arm','leg','foot'],self.location)) { value.reason = 'fall-injury-location-unavailable'; return value; }
        if (self.location != 'torso' && (self.bodyPart == nil || self.locationEvidence == nil || self.locationEvidence == ''))
        { value.reason = 'fall-injury-location-facts'; return value; }
        if (self.location == 'torso' && self.bodyPart != nil) rpgExpandedReject('fall-injury-body-part');
        foreach (local prior in self.profile.fallInjuries)
            if (prior.id == self.id || self.fall != nil && prior.fall == self.fall)
                rpgExpandedReject('fall-injury-duplicate');
        if (landingResult != nil && !landingResult.negatesDamage && self.damageVelocity != landingResult.velocity)
        { value.reason = 'fall-injury-velocity'; return value; }
        value.impactDamage = rpgExpandedCollisionCap(self.damage,self.obstacleHP,self.obstacleDR);
        if (landingResult != nil && (landingResult.negatesDamage || landingResult.velocity == 0)) value.impactDamage = 0;
        rpgInteger(self.cushionDR,0,10);
        if (self.cushionDR != 0 && (self.cushionDR < 2 || self.cushionEvidence == nil || self.cushionEvidence == ''))
        { value.reason = 'fall-cushion-facts'; return value; }
        value.cushionedDamage = value.impactDamage > self.cushionDR ? value.impactDamage-self.cushionDR : 0;
        value.protection = rpgExpandedAssessFallProtection(value.cushionedDamage,self.resistance,self.protectionKind);
        value.wound = holds(['hand','foot'],self.location) ? new RpgExpandedFallExtremityWound()
            : holds(['arm','leg'],self.location) ? new RpgExpandedFallLimbWound() : new RpgExpandedWound();
        value.wound.id = self.id; value.wound.profile = self.profile;
        value.wound.location = self.location; value.wound.bodyPart = self.bodyPart;
        value.wound.amount = value.protection.penetratingDamage + value.protection.bluntInjury;
        value.wound.dropDestination = self.dropDestination;
        local prepared = value.wound.assess();
        if (prepared.status != 'ready') { value.reason = prepared.reason; return value; }
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status == 'reused') return self.result;
        if (value.status != 'ready') return value;
        if (value.wound.apply().status != 'resolved') rpgExpandedReject('fall-injury-wound-changed');
        self.boundDefinition = self.definition(); self.committedAt = rpgLedger.seconds;
        self.profile.fallInjuries = self.profile.fallInjuries + [self];
        value.status = 'resolved'; self.result = value; return value;
    }
;

/** B431: cap both sides' basic impact damage for a breakable immovable obstacle.
 * nil/nil means no breakable-obstacle cap; this does not commit obstacle damage. */
rpgExpandedCollisionCap(damage,obstacleHP,obstacleDR)
{
    rpgInteger(damage,0,100000000);
    if (obstacleHP == nil && obstacleDR == nil) return damage;
    if (obstacleHP == nil || obstacleDR == nil) rpgExpandedReject('collision-obstacle-facts');
    rpgInteger(obstacleHP,1,100000000); rpgInteger(obstacleDR,0,100000000);
    local limit = obstacleHP + obstacleDR;
    return damage < limit ? damage : limit;
}

modify RpgExpandedFallInjury
    copyForDamage(amount)
    {
        local value = new RpgExpandedFallInjury();
        value.id = self.id; value.profile = self.profile; value.damage = amount;
        value.fall = self.fall; value.landing = self.landing; value.damageVelocity = self.damageVelocity;
        value.obstacleHP = self.obstacleHP; value.obstacleDR = self.obstacleDR;
        value.cushionDR = self.cushionDR; value.cushionEvidence = self.cushionEvidence;
        value.resistance = self.resistance; value.protectionKind = self.protectionKind;
        value.location = self.location; value.approved = self.approved; value.evidence = self.evidence;
        value.bodyPart = self.bodyPart; value.locationEvidence = self.locationEvidence;
        value.dropDestination = self.dropDestination; return value;
    }
;
modify RpgExpandedProfile
    fallImpacts = []
;
class RpgExpandedFallImpactResult: RpgExpandedResult
    expression = nil
    injury = nil
    damage = 0
    dice = []
;
/** Own collision dice and the injury as one transaction. injury is an uncommitted template. */
class RpgExpandedFallImpact: object
    injury = nil
    hard = nil
    velocityScale = 1
    result = nil
    boundDefinition = nil
    definition() { return [self.injury,self.hard,self.velocityScale] + self.injury.definition(); }
    assess()
    {
        if (self.injury == nil || !self.injury.ofKind(RpgExpandedFallInjury)
            || self.injury.profile == nil || !self.injury.profile.ofKind(RpgExpandedProfile)
            || self.injury.fall == nil) rpgExpandedReject('fall-impact-definition');
        local value = new RpgExpandedFallImpactResult();
        if (self.result != nil)
        {
            local current = self.definition();
            for (local index = 1; index <= current.length(); index += 1)
                if (current[index] != self.boundDefinition[index]) rpgExpandedReject('fall-impact-binding');
            if (!holds(self.injury.profile.fallImpacts,self) || self.result.injury.assess().status != 'reused')
                rpgExpandedReject('fall-impact-history');
            value.status = 'reused'; return value;
        }
        if (self.injury.result != nil || self.injury.damage != 0) rpgExpandedReject('fall-impact-template');
        if (!holds([1,10,100,1000],self.velocityScale)) rpgExpandedReject('collision-velocity-scale');
        rpgInteger(self.injury.damageVelocity,0,10000*self.velocityScale);
        local velocity = self.injury.damageVelocity;
        if (self.injury.landing != nil)
        {
            if (self.velocityScale != 1) rpgExpandedReject('fall-landing-velocity-scale');
            if (!self.injury.landing.ofKind(RpgExpandedLandingReceipt)) rpgExpandedReject('fall-injury-landing');
            local landing = self.injury.landing.impactFor(self.injury.profile,self.injury.fall);
            if (landing.negatesDamage) velocity = 0;
        }
        value.expression = rpgExpandedAssessScaledCollision(self.injury.profile.maxHP,velocity,self.velocityScale,self.hard);
        local minimum = value.expression.damageDice + value.expression.damageAdds;
        local maximum = value.expression.damageDice * 6 + value.expression.damageAdds;
        if (minimum < 0) minimum = 0; if (maximum < 0) maximum = 0;
        /* Injury is monotonic on either side of the armor stopping threshold.
         * Check its peak blunt injury as well as the highest penetration. */
        local candidates = [minimum,maximum];
        rpgInteger(self.injury.resistance,0,100000000); rpgInteger(self.injury.cushionDR,0,10);
        local threshold = self.injury.resistance + self.injury.cushionDR;
        if (threshold > minimum && threshold < maximum) candidates = candidates + [threshold];
        foreach (local amount in candidates)
        {
            local prepared = self.injury.copyForDamage(amount).assess();
            if (prepared.status != 'ready') { value.reason = prepared.reason; return value; }
        }
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status == 'reused') return self.result;
        if (value.status != 'ready') return value;
        local damage = value.expression.damageAdds;
        for (local index = 0; index < value.expression.damageDice; index += 1)
        { local die = rpgRandom.die(); value.dice = value.dice + [die]; damage += die; }
        value.damage = damage < 0 ? 0 : damage;
        value.injury = self.injury.copyForDamage(value.damage);
        if (value.injury.apply().status != 'resolved') rpgExpandedReject('fall-impact-interrupted');
        self.boundDefinition = self.definition(); value.status = 'resolved'; self.result = value;
        self.injury.profile.fallImpacts = self.injury.profile.fallImpacts + [self]; return value;
    }
;

/** Critical jump failure consumes the existing owned collision and wound pipeline. */
class RpgExpandedJumpFallImpact: RpgExpandedJumpFallPlan
    impact = nil
    validateOwner(profile,fall,velocity)
    {
        if (self.impact == nil || !self.impact.ofKind(RpgExpandedFallImpact) || self.impact.injury == nil
            || !self.impact.injury.ofKind(RpgExpandedFallInjury) || self.impact.injury.profile != profile
            || self.impact.injury.fall != fall || self.impact.injury.damageVelocity != velocity)
            rpgExpandedReject('jump-fall-plan-owner');
        return nil;
    }
    assessFor(profile,fall,velocity)
    {
        self.validateOwner(profile,fall,velocity);
        if (self.impact.result != nil)
        { local value = new RpgExpandedResult(); value.reason = 'jump-fall-plan-used'; return value; }
        return self.impact.assess();
    }
    applyFor(profile,fall,velocity)
    {
        local value = self.assessFor(profile,fall,velocity);
        if (value.status != 'ready') rpgExpandedReject('jump-fall-plan-changed');
        return self.impact.apply();
    }
    validateResult(profile,fall,velocity)
    {
        self.validateOwner(profile,fall,velocity);
        if (self.impact.result == nil || self.impact.assess().status != 'reused')
            rpgExpandedReject('jump-fall-plan-history');
        return nil;
    }
;

/** B435 crushing pressure; inputs use hundredths of an atmosphere. */
class RpgExpandedPressureAssessment: RpgExpandedResult
    checkRequired = nil
    injuryMultiplier = 1
    bendsRisk = nil
;
rpgExpandedAssessPressure(pressure,nativePressure,support,sizeModifier)
{
    rpgInteger(pressure,1,1000000); rpgInteger(nativePressure,1,100000);
    rpgInteger(support,0,3); rpgInteger(sizeModifier,-20,20);
    local value = new RpgExpandedPressureAssessment();
    local increment = nativePressure * (support == 2 ? 100 : 10);
    value.checkRequired = support < 3 && pressure > increment;
    if (value.checkRequired) value.modifier = 3 - pressure / increment;
    value.injuryMultiplier = sizeModifier >= 2 ? sizeModifier : 1;
    value.bendsRisk = support < 2 && pressure > nativePressure * (support == 1 ? 10 : 2);
    value.status = 'ready'; return value;
}

class RpgExpandedPressureResult: RpgExpandedResult
    injury = 0
    health = nil
;
modify RpgExpandedProfile
    pressureExposures = []
;
/** Owned constant-pressure interval. Resolve entry and each due minute explicitly. */
class RpgExpandedPressureExposure: object
    id = nil
    profile = nil
    pressure = 100
    nativePressure = nil
    support = 0
    sizeModifier = 0
    approved = nil
    evidence = nil
    startedAt = nil
    dueAt = nil
    endedAt = nil
    boundEndedAt = nil
    checks = []
    boundDefinition = nil
    entryNativePressure = nil
    entrySupport = nil
    currentNativePressure() { return self.nativePressure == nil ? self.profile.nativePressureHundredths : self.nativePressure; }
    currentSupport()
    {
        rpgInteger(self.support,0,3);
        local innate = self.profile.pressureSupportLevel();
        return innate > self.support ? innate : self.support;
    }
    resolvedNativePressure() { return self.startedAt == nil ? self.currentNativePressure() : self.entryNativePressure; }
    resolvedSupport() { return self.startedAt == nil ? self.currentSupport() : self.entrySupport; }
    definition() { return [self.id,self.profile,self.pressure,self.nativePressure,self.support,self.sizeModifier,
        self.approved,self.evidence,self.resolvedNativePressure(),self.resolvedSupport(),self.startedAt]; }
    validateBinding()
    {
        if (self.startedAt == nil || !holds(self.profile.pressureExposures,self)) rpgExpandedReject('pressure-owner');
        local current = self.definition();
        for (local i = 1; i <= current.length(); i += 1)
            if (current[i] != self.boundDefinition[i]) rpgExpandedReject('pressure-binding');
        if (self.endedAt == nil && (self.currentNativePressure() != self.entryNativePressure
            || self.currentSupport() != self.entrySupport)) rpgExpandedReject('pressure-binding');
        if (self.endedAt != self.boundEndedAt || self.dueAt != self.startedAt + self.checks.length() * 60)
            rpgExpandedReject('pressure-schedule-binding');
        for (local i = 1; i <= self.checks.length(); i += 1)
        {
            local check = self.checks[i];
            if (check.exposure != self || check.boundExposure != self || check.result == nil
                || check.checkedAt != self.startedAt + (i - 1) * 60) rpgExpandedReject('pressure-check-history');
        }
        return nil;
    }
    assess()
    {
        if (self.id == nil || self.id == '' || self.profile == nil || !self.profile.ofKind(RpgExpandedProfile))
            rpgExpandedReject('pressure-definition');
        rpgExpandedValidate(self.profile);
        local value = rpgExpandedAssessPressure(self.pressure,self.resolvedNativePressure(),self.resolvedSupport(),self.sizeModifier);
        if (!self.approved || self.evidence == nil || self.evidence == '')
        { value.status = 'blocked'; value.reason = 'pressure-evidence'; return value; }
        if (self.startedAt != nil)
        { self.validateBinding(); value.status = 'reused'; return value; }
        foreach (local prior in self.profile.pressureExposures)
        {
            prior.validateBinding();
            if (prior.id == self.id) rpgExpandedReject('pressure-duplicate');
            if (prior.endedAt == nil) { value.status = 'blocked'; value.reason = 'pressure-overlap'; return value; }
        }
        if (self.profile.dead) { value.status = 'blocked'; value.reason = 'pressure-patient-dead'; }
        return value;
    }
    begin()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        self.entryNativePressure = self.currentNativePressure(); self.entrySupport = self.currentSupport();
        self.startedAt = rpgLedger.seconds; self.dueAt = self.startedAt;
        self.boundDefinition = self.definition(); self.profile.pressureExposures = self.profile.pressureExposures + [self];
        value.status = 'resolved'; return value;
    }
    end()
    {
        self.validateBinding(); local value = new RpgExpandedResult();
        if (self.endedAt != nil) { value.status = 'reused'; return value; }
        local assessment = rpgExpandedAssessPressure(self.pressure,self.resolvedNativePressure(),self.resolvedSupport(),self.sizeModifier);
        if (assessment.checkRequired && !self.profile.dead && rpgLedger.seconds >= self.dueAt)
        { value.reason = 'pressure-check-due'; return value; }
        self.endedAt = rpgLedger.seconds; self.boundEndedAt = self.endedAt; value.status = 'resolved'; return value;
    }
;
class RpgExpandedPressureCheck: object
    exposure = nil
    result = nil
    boundExposure = nil
    checkedAt = nil
    assess()
    {
        local value = new RpgExpandedPressureResult();
        if (self.exposure == nil || !self.exposure.ofKind(RpgExpandedPressureExposure)) rpgExpandedReject('pressure-check-exposure');
        self.exposure.validateBinding();
        if (self.result != nil)
        {
            if (self.exposure != self.boundExposure || !holds(self.exposure.checks,self)) rpgExpandedReject('pressure-check-owner');
            value.status = 'reused'; return value;
        }
        if (self.exposure.endedAt != nil || self.exposure.profile.dead) { value.reason = 'pressure-exposure-ended'; return value; }
        local assessment = rpgExpandedAssessPressure(self.exposure.pressure,self.exposure.resolvedNativePressure(),
            self.exposure.resolvedSupport(),self.exposure.sizeModifier);
        if (!assessment.checkRequired) { value.reason = 'pressure-check-unnecessary'; return value; }
        if (rpgLedger.seconds < self.exposure.dueAt) { value.reason = 'pressure-check-not-due'; return value; }
        if (rpgLedger.seconds > self.exposure.dueAt) { value.reason = 'pressure-check-missed'; return value; }
        rpgInteger(rpgLedger.seconds,0,2147483587);
        value.modifier = assessment.modifier; value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status == 'reused') return self.result;
        if (value.status != 'ready') return value;
        self.boundExposure = self.exposure; self.checkedAt = rpgLedger.seconds;
        value.check = rpgLiteAttributeCheck(self.exposure.profile,rpgHT,'resistance',value.modifier);
        self.exposure.dueAt += 60; self.exposure.checks = self.exposure.checks + [self];
        value.status = 'resolved'; self.result = value;
        if (!value.check.achieved)
        {
            value.injury = -value.check.margin * (self.exposure.sizeModifier >= 2 ? self.exposure.sizeModifier : 1);
            if (value.injury > 0) value.health = rpgLiteWound(self.exposure.profile,value.injury);
        }
        if (self.exposure != self.boundExposure || rpgLedger.seconds != self.checkedAt
            || self.exposure.dueAt != self.checkedAt + 60) rpgExpandedReject('pressure-check-state-changed');
        self.exposure.validateBinding(); return value;
    }
;

/** No action may skip an unresolved entry/minute pressure check. */
modify rpgLedger
    validateAdvance(seconds)
    {
        inherited(seconds);
        for (local exposure = firstObj(RpgExpandedPressureExposure); exposure != nil;
            exposure = nextObj(exposure,RpgExpandedPressureExposure))
            if (exposure.startedAt != nil)
            {
                exposure.validateBinding();
                if (exposure.endedAt == nil && !exposure.profile.dead)
                {
                    local assessment = rpgExpandedAssessPressure(exposure.pressure,exposure.resolvedNativePressure(),
                        exposure.resolvedSupport(),exposure.sizeModifier);
                    if (assessment.checkRequired && self.seconds + seconds > exposure.dueAt)
                        rpgExpandedReject('pressure-check-deadline');
                }
            }
        return nil;
    }
;

/** B435 printed return-to-native-pressure examples, without interpolated schedules. */
class RpgExpandedDecompressionAssessment: RpgExpandedResult
    safeReturn = nil
    slowRequired = nil
    referenceSafeSeconds = nil
    approximate = nil
;
rpgExpandedAssessDecompression(pressure,nativePressure,support,seconds,humanExamples)
{
    local exposure = rpgExpandedAssessPressure(pressure,nativePressure,support,0);
    rpgInteger(seconds,0,2147483647);
    local value = new RpgExpandedDecompressionAssessment();
    if (!exposure.bendsRisk)
    { value.safeReturn = true; value.status = 'ready'; return value; }
    if (!humanExamples || nativePressure != 100)
    { value.reason = 'decompression-schedule-required'; return value; }
    if (pressure <= 250)
    {
        value.referenceSafeSeconds = 4800; value.safeReturn = seconds <= 4800;
        value.slowRequired = !value.safeReturn; value.status = 'ready'; return value;
    }
    if (pressure == 400)
    {
        value.referenceSafeSeconds = 1320; value.approximate = true;
        value.reason = 'decompression-approximate-limit'; return value;
    }
    if (pressure >= 550)
    { value.referenceSafeSeconds = 0; value.slowRequired = true; value.status = 'ready'; return value; }
    value.reason = 'decompression-schedule-required'; return value;
}
modify RpgExpandedPressureExposure
    assessReturnToNative(humanExamples)
    {
        self.validateBinding();
        local end = self.endedAt == nil ? rpgLedger.seconds : self.endedAt;
        if (end < self.startedAt) rpgExpandedReject('pressure-interval');
        return rpgExpandedAssessDecompression(self.pressure,self.resolvedNativePressure(),
            self.resolvedSupport(),end - self.startedAt,humanExamples);
    }
;

/** B435 author-approved descending pressure schedule; no duration is inferred. */
modify RpgExpandedProfile
    decompressionPlans = []
;
class RpgExpandedDecompressionPlan: object
    id = nil
    source = nil
    stages = []
    approved = nil
    evidence = nil
    startedAt = nil
    completedAt = nil
    stageIndex = 0
    stageSeconds = 0
    exposures = []
    progress = []
    advancing = nil
    boundDefinition = nil
    profile() { return self.source.profile; }
    definition() { return [self.id,self.source,self.stages,self.approved,self.evidence,self.startedAt]; }
    validate()
    {
        if (self.id == nil || self.id == '' || self.source == nil || !self.source.ofKind(RpgExpandedPressureExposure))
            rpgExpandedReject('decompression-plan-definition');
        self.source.validateBinding();
        if (!self.approved || self.evidence == nil || self.evidence == '') rpgExpandedReject('decompression-plan-approval');
        if (self.stages.length() == 0) rpgExpandedReject('decompression-plan-empty');
        local priorPressure = self.source.pressure;
        foreach (local row in self.stages)
        {
            if (row.length() != 2) rpgExpandedReject('decompression-plan-stage');
            rpgInteger(row[1],self.source.resolvedNativePressure(),priorPressure);
            if (row[1] == priorPressure) rpgExpandedReject('decompression-plan-repeated-pressure');
            rpgInteger(row[2],1,2147483647); priorPressure = row[1];
        }
        if (priorPressure != self.source.resolvedNativePressure()) rpgExpandedReject('decompression-plan-destination');
        if (self.startedAt != nil)
        {
            if (!holds(self.profile().decompressionPlans,self)) rpgExpandedReject('decompression-plan-owner');
            local current = self.definition();
            for (local i = 1; i <= current.length(); i += 1)
                if (current[i] != self.boundDefinition[i]) rpgExpandedReject('decompression-plan-binding');
            rpgInteger(self.stageIndex,1,self.stages.length());
            rpgInteger(self.stageSeconds,0,self.stages[self.stageIndex][2]);
            if (self.exposures.length() != self.stageIndex) rpgExpandedReject('decompression-plan-history');
            foreach (local exposure in self.exposures) exposure.validateBinding();
            for (local stage = 1; stage <= self.stageIndex; stage += 1)
            {
                local credited = 0;
                foreach (local receipt in self.progress)
                {
                    if (receipt.plan != self || receipt.result == nil || receipt.boundDefinition[1] != self
                        || receipt.boundDefinition[2] != receipt.stage || receipt.boundDefinition[3] != receipt.seconds)
                        rpgExpandedReject('decompression-progress-history');
                    if (receipt.stage == stage) credited += receipt.seconds;
                }
                if (credited != (stage == self.stageIndex ? self.stageSeconds : self.stages[stage][2]))
                    rpgExpandedReject('decompression-progress-history');
                local exposure = self.exposures[stage];
                if (exposure.profile != self.profile() || exposure.pressure != self.stages[stage][1]
                    || exposure.startedAt != (stage == 1 ? self.startedAt : self.exposures[stage-1].endedAt))
                    rpgExpandedReject('decompression-plan-history');
                if (stage < self.stageIndex && exposure.endedAt != exposure.startedAt + self.stages[stage][2])
                    rpgExpandedReject('decompression-plan-history');
            }
            if (self.completedAt != nil && (self.stageIndex != self.stages.length()
                || self.stageSeconds != self.stages[self.stageIndex][2]
                || self.completedAt != self.exposures[self.stageIndex].endedAt)) rpgExpandedReject('decompression-plan-history');
        }
        if (self.completedAt == nil && (self.source.currentNativePressure() != self.source.resolvedNativePressure()
            || self.source.currentSupport() != self.source.resolvedSupport())) rpgExpandedReject('decompression-plan-conditions');
        return nil;
    }
    openStage()
    {
        local exposure = new RpgExpandedPressureExposure(); exposure.profile = self.profile();
        exposure.id = 'decompression:' + self.id + ':' + self.stageIndex;
        exposure.pressure = self.stages[self.stageIndex][1]; exposure.nativePressure = self.source.resolvedNativePressure();
        exposure.support = self.source.support; exposure.sizeModifier = self.source.sizeModifier;
        exposure.approved = true; exposure.evidence = self.evidence;
        if (exposure.begin().status != 'resolved') rpgExpandedReject('decompression-stage-unavailable');
        self.exposures = self.exposures + [exposure]; return nil;
    }
    begin()
    {
        self.validate(); local value = new RpgExpandedResult();
        if (self.startedAt != nil) { value.status = 'reused'; return value; }
        if (self.source.endedAt == nil || self.source.endedAt != rpgLedger.seconds)
        { value.reason = 'decompression-source-not-current'; return value; }
        if (self.profile().dead) { value.reason = 'decompression-patient-dead'; return value; }
        foreach (local prior in self.profile().decompressionPlans)
            if (prior.id == self.id || prior.completedAt == nil) rpgExpandedReject('decompression-plan-overlap');
        for (local prior = firstObj(RpgExpandedDecompressionPlan); prior != nil; prior = nextObj(prior,RpgExpandedDecompressionPlan))
            if (prior != self && prior.startedAt != nil && prior.completedAt == nil && !prior.profile().dead)
                rpgExpandedReject('decompression-concurrent-plan-unimplemented');
        self.startedAt = rpgLedger.seconds; self.stageIndex = 1; self.boundDefinition = self.definition();
        self.profile().decompressionPlans = self.profile().decompressionPlans + [self]; self.openStage();
        value.status = 'resolved'; return value;
    }
    finishStage()
    {
        self.validate(); local value = new RpgExpandedResult();
        if (self.startedAt == nil) { value.reason = 'decompression-plan-not-started'; return value; }
        if (self.completedAt != nil) { value.status = 'reused'; return value; }
        if (self.profile().dead) { value.reason = 'decompression-patient-dead'; return value; }
        if (self.stageSeconds != self.stages[self.stageIndex][2]) { value.reason = 'decompression-stage-incomplete'; return value; }
        local ended = self.exposures[self.stageIndex].end();
        if (ended.status != 'resolved' && ended.status != 'reused') return ended;
        if (self.stageIndex == self.stages.length()) self.completedAt = rpgLedger.seconds;
        else { self.stageIndex += 1; self.stageSeconds = 0; self.openStage(); }
        value.status = 'resolved'; return value;
    }
;
class RpgExpandedDecompressionProgress: object
    plan = nil
    stage = 0
    seconds = 0
    result = nil
    boundDefinition = nil
    advancingAt = nil
    definition() { return [self.plan,self.stage,self.seconds]; }
    assess()
    {
        if (self.plan == nil || !self.plan.ofKind(RpgExpandedDecompressionPlan)) rpgExpandedReject('decompression-progress-plan');
        self.plan.validate(); local value = new RpgExpandedResult();
        if (self.result != nil)
        {
            local current = self.definition();
            for (local i = 1; i <= current.length(); i += 1)
                if (current[i] != self.boundDefinition[i]) rpgExpandedReject('decompression-progress-binding');
            if (!holds(self.plan.progress,self)) rpgExpandedReject('decompression-progress-owner');
            value.status = 'reused'; return value;
        }
        if (self.plan.startedAt == nil || self.plan.completedAt != nil || self.plan.profile().dead)
        { value.reason = 'decompression-plan-inactive'; return value; }
        if (self.stage != self.plan.stageIndex) { value.reason = 'decompression-progress-stage'; return value; }
        rpgInteger(self.seconds,1,self.plan.stages[self.stage][2]);
        if (self.seconds > self.plan.stages[self.stage][2] - self.plan.stageSeconds)
        { value.reason = 'decompression-progress-excess'; return value; }
        if (self.plan.advancing != nil) { value.reason = 'decompression-progress-in-flight'; return value; }
        value.seconds = self.seconds; value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status == 'reused') return self.result;
        if (value.status != 'ready') return value;
        local definition = self.definition(); local start = rpgLedger.seconds; local elapsed = self.plan.stageSeconds;
        self.advancingAt = start; self.plan.advancing = self;
        rpgSpendTime(self.seconds);
        if (self.plan.advancing != self) rpgExpandedReject('decompression-progress-changed');
        self.plan.advancing = nil;
        local current = self.definition();
        for (local i = 1; i <= current.length(); i += 1)
            if (current[i] != definition[i]) rpgExpandedReject('decompression-progress-changed');
        self.plan.validate();
        if (rpgLedger.seconds != start + self.seconds || self.plan.stageIndex != self.stage
            || self.plan.stageSeconds != elapsed) rpgExpandedReject('decompression-progress-changed');
        self.plan.stageSeconds += self.seconds; self.boundDefinition = definition;
        self.plan.progress = self.plan.progress + [self]; value.status = 'resolved'; self.result = value; return value;
    }
;

modify rpgLedger
    validateAdvance(seconds)
    {
        inherited(seconds);
        for (local plan = firstObj(RpgExpandedDecompressionPlan); plan != nil; plan = nextObj(plan,RpgExpandedDecompressionPlan))
            if (plan.startedAt != nil && plan.completedAt == nil && !plan.profile().dead)
            {
                plan.validate();
                if (plan.advancing == nil || plan.advancing.plan != plan
                    || plan.advancing.advancingAt != self.seconds || plan.advancing.seconds != seconds)
                    rpgExpandedReject('decompression-progress-required');
            }
        return nil;
    }
;

/** B435 unsafe return: authored failure branch and hourly recovery. */
class RpgExpandedDecompressionIllnessResult: RpgExpandedResult
    phase = nil
    injury = 0
;
modify RpgExpandedProfile
    decompressionIllnesses = []
    unconsciousRecoveryApartFrom(owner)
    {
        foreach (local episode in self.decompressionIllnesses)
        { episode.validateReceipt(); if (episode != owner && episode.phase == 'unconscious') return true; }
        return inherited(owner);
    }
;
class RpgExpandedDecompressionIllness: object
    id = nil
    source = nil
    humanExamples = nil
    unsafeReturn = nil
    failureMode = 'unconscious'
    positionAssessed = nil
    balanced = nil
    paralysis = nil
    approved = nil
    evidence = nil
    dropDestination = nil
    startedAt = nil
    dueAt = nil
    phase = nil
    agony = nil
    recompressions = []
    symptomRelief = nil
    recoveries = []
    result = nil
    boundDefinition = nil
    profile() { return self.source.profile; }
    definition() { return [self.id,self.source,self.humanExamples,self.unsafeReturn,self.failureMode,self.approved,self.evidence,self.dropDestination,self.startedAt,self.positionAssessed,self.balanced]; }
    validateReceipt()
    {
        self.source.validateBinding();
        if (self.result == nil || !holds(self.profile().decompressionIllnesses,self)) rpgExpandedReject('decompression-illness-owner');
        local current = self.definition();
        for (local i = 1; i <= current.length(); i += 1)
            if (current[i] != self.boundDefinition[i]) rpgExpandedReject('decompression-illness-binding');
        local expected = self.result.phase;
        foreach (local recovery in self.recoveries)
        {
            if (recovery.episode != self || recovery.boundEpisode != self || recovery.result == nil) rpgExpandedReject('decompression-recovery-history');
            expected = recovery.result.phase;
        }
        if (self.symptomRelief != nil)
        {
            local relief = self.symptomRelief;
            if (relief.treatment.episode != self || relief.boundTreatment != relief.treatment
                || !holds(self.recompressions,relief.treatment) || !holds(relief.treatment.checks,relief)
                || relief.result == nil || !relief.result.check.achieved)
                rpgExpandedReject('decompression-relief-owner');
            expected = 'recovered';
        }
        if (self.phase != expected || self.dueAt != self.startedAt + (self.recoveries.length()+1) * 3600)
            rpgExpandedReject('decompression-illness-state');
        return nil;
    }
    painEpisode(ordinal)
    {
        local pain = new RpgExpandedDecompressionAgony(); pain.episode = self; pain.id = self.id + ':pain:' + ordinal;
        pain.profile = self.profile(); pain.durationSeconds = 3600; pain.approved = true;
        pain.evidence = self.evidence; pain.dropDestination = self.dropDestination; return pain;
    }
    paralysisEpisode()
    {
        local condition = new RpgExpandedDecompressionParalysis();
        condition.id = self.id + ':paralysis'; condition.profile = self.profile();
        condition.episode = self; condition.durationSeconds = 3600;
        condition.approved = true; condition.evidence = self.evidence;
        condition.positionAssessed = self.positionAssessed; condition.balanced = self.balanced;
        return condition;
    }
    assess()
    {
        local value = new RpgExpandedDecompressionIllnessResult();
        if (self.id == nil || self.id == '' || self.source == nil || !self.source.ofKind(RpgExpandedPressureExposure))
            rpgExpandedReject('decompression-illness-definition');
        if (self.result != nil) { self.validateReceipt(); value.status = 'reused'; return value; }
        self.source.validateBinding();
        if (!self.approved || !self.unsafeReturn || self.evidence == nil || self.evidence == '')
        { value.reason = 'decompression-unsafe-return-evidence'; return value; }
        if (!holds(['unconscious','paralysis'],self.failureMode)) rpgExpandedReject('decompression-failure-mode');
        if (self.failureMode == 'paralysis' && self.paralysisEpisode().assess().status != 'ready')
        { value.reason = 'decompression-paralysis-unavailable'; return value; }
        if (self.source.endedAt != rpgLedger.seconds) { value.reason = 'decompression-return-not-current'; return value; }
        if (self.source.assessReturnToNative(self.humanExamples).safeReturn)
        { value.reason = 'decompression-return-not-at-risk'; return value; }
        if (self.profile().dead || self.profile().unconscious) { value.reason = 'decompression-patient-unavailable'; return value; }
        foreach (local plan in self.profile().decompressionPlans)
            if (plan.completedAt == nil) { value.reason = 'decompression-plan-active'; return value; }
        foreach (local prior in self.profile().decompressionIllnesses)
        {
            prior.validateReceipt();
            if (prior.id == self.id || prior.source == self.source || holds(['agony','unconscious','paralysis'],prior.phase))
                rpgExpandedReject('decompression-illness-overlap');
        }
        if (self.painEpisode(0).assess().status != 'ready') { value.reason = 'decompression-agony-unavailable'; return value; }
        rpgInteger(rpgLedger.seconds,0,2147480047);
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status == 'reused') return self.result;
        if (value.status != 'ready') return value;
        value.check = rpgLiteAttributeCheck(self.profile(),rpgHT,'resistance',0);
        value.phase = value.check.critical == 'success' ? 'recovered' : value.check.critical == 'failure' ? 'dead'
            : value.check.achieved ? 'agony' : self.failureMode;
        self.startedAt = rpgLedger.seconds; self.dueAt = self.startedAt + 3600;
        self.phase = value.phase; self.boundDefinition = self.definition();
        value.status = 'resolved'; self.result = value;
        self.profile().decompressionIllnesses = self.profile().decompressionIllnesses + [self];
        if (self.phase == 'agony')
        { self.agony = self.painEpisode(0); if (self.agony.apply().status != 'resolved') rpgExpandedReject('decompression-agony-changed'); }
        if (self.phase == 'paralysis')
        { self.paralysis = self.paralysisEpisode(); if (self.paralysis.apply().status != 'resolved') rpgExpandedReject('decompression-paralysis-changed'); }
        if (self.phase == 'dead') self.profile().dead = true;
        if (holds(['dead','unconscious'],self.phase)) self.profile().becomeUnconscious();
        self.validateReceipt(); return value;
    }
;
class RpgExpandedDecompressionRecovery: object
    episode = nil
    result = nil
    boundEpisode = nil
    assess()
    {
        if (self.episode == nil || !self.episode.ofKind(RpgExpandedDecompressionIllness)) rpgExpandedReject('decompression-recovery-episode');
        self.episode.validateReceipt(); local value = new RpgExpandedDecompressionIllnessResult();
        if (self.result != nil)
        {
            if (self.episode != self.boundEpisode || !holds(self.episode.recoveries,self)) rpgExpandedReject('decompression-recovery-owner');
            value.status = 'reused'; return value;
        }
        if (!holds(['agony','unconscious','paralysis'],self.episode.phase) || self.episode.profile().dead)
        { value.reason = 'decompression-recovery-inactive'; return value; }
        if (rpgLedger.seconds != self.episode.dueAt) { value.reason = 'decompression-recovery-time'; return value; }
        if (self.episode.painEpisode(self.episode.recoveries.length()+1).assess().status != 'ready') { value.reason = 'decompression-agony-unavailable'; return value; }
        rpgInteger(rpgLedger.seconds,0,2147480047); value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status == 'reused') return self.result;
        if (value.status != 'ready') return value;
        local e = self.episode; local oldPhase = e.phase;
        value.check = rpgLiteAttributeCheck(e.profile(),rpgHT,'resistance',0);
        value.phase = value.check.achieved ? (oldPhase == 'agony' ? 'recovered' : 'agony') : oldPhase;
        self.boundEpisode = e; value.status = 'resolved'; self.result = value;
        e.recoveries = e.recoveries + [self]; e.phase = value.phase; e.dueAt += 3600;
        if (holds(['unconscious','paralysis'],oldPhase) && !value.check.achieved)
        { value.injury = rpgRandom.die(); rpgLiteWound(e.profile(),value.injury); }
        if (value.phase == 'agony')
        {
            e.agony = e.painEpisode(e.recoveries.length()); if (e.agony.apply().status != 'resolved') rpgExpandedReject('decompression-agony-changed');
            if (oldPhase == 'unconscious' && !e.profile().unconsciousRecoveryOwned() && !e.profile().mortal
                && e.profile().hp() > 0 && e.profile().fp() > 0) e.profile().unconscious = nil;
        }
        e.validateReceipt(); return value;
    }
;
modify rpgLedger
    validateAdvance(seconds)
    {
        inherited(seconds);
        for (local episode = firstObj(RpgExpandedDecompressionIllness); episode != nil;
            episode = nextObj(episode,RpgExpandedDecompressionIllness))
            if (episode.result != nil && !episode.profile().dead)
            {
                episode.validateReceipt();
                if (holds(['agony','unconscious','paralysis'],episode.phase) && self.seconds + seconds > episode.dueAt)
                    rpgExpandedReject('decompression-recovery-boundary');
            }
        return nil;
    }
;

/** The illness, rather than a guessed fixed duration, owns this paralysis. */
class RpgExpandedDecompressionParalysis: RpgExpandedParalysis
    episode = nil
    definition() { return inherited() + [self.episode]; }
    active()
    {
        self.validateReceipt();
        if (self.episode == nil || self.episode.paralysis != self || self.episode.profile() != self.profile)
            rpgExpandedReject('decompression-paralysis-owner');
        self.episode.validateReceipt();
        return !self.profile.dead && self.episode.phase == 'paralysis';
    }
;

/** Keep pain active at the hourly boundary until its recovery is committed. */
class RpgExpandedDecompressionAgony: RpgExpandedAgony
    episode = nil
    requiresPayments() { return self.episode.phase == 'agony' && self.episode.agony == self; }
    definition() { return inherited() + [self.episode]; }
    active()
    {
        self.validateReceipt(); self.episode.validateReceipt();
        if (self.profile != self.episode.profile()) rpgExpandedReject('decompression-agony-owner');
        return !self.profile.dead && self.episode.phase == 'agony' && self.episode.agony == self;
    }
    overlaps(prior)
    {
        if (prior.ofKind(RpgExpandedDecompressionAgony) && prior.episode == self.episode
            && rpgLedger.seconds == prior.expiresAt) return nil;
        return inherited(prior);
    }
;

/** B435 sustained recompression: five-minute HT+4 symptom recovery. */
class RpgExpandedRecompression: object
    id = nil
    episode = nil
    exposure = nil
    highestConfirmed = nil
    approved = nil
    evidence = nil
    startedAt = nil
    dueAt = nil
    cancelledAt = nil
    boundCancelledAt = nil
    checks = []
    boundDefinition = nil
    definition() { return [self.id,self.episode,self.exposure,self.highestConfirmed,self.approved,self.evidence,self.startedAt]; }
    active() { return self.startedAt != nil && self.cancelledAt == nil && !self.episode.profile().dead
        && holds(['agony','unconscious','paralysis'],self.episode.phase); }
    validate()
    {
        self.episode.validateReceipt(); self.exposure.validateBinding();
        local current = self.definition();
        if (!holds(self.episode.recompressions,self)) rpgExpandedReject('recompression-owner');
        for (local i = 1; i <= current.length(); i += 1)
            if (current[i] != self.boundDefinition[i]) rpgExpandedReject('recompression-binding');
        if (self.cancelledAt != self.boundCancelledAt || self.dueAt != self.startedAt + (self.checks.length()+1)*300)
            rpgExpandedReject('recompression-clock-binding');
        for (local i = 1; i <= self.checks.length(); i += 1)
        {
            local check = self.checks[i];
            if (check.treatment != self || check.boundTreatment != self || check.result == nil
                || check.checkedAt != self.startedAt + i*300) rpgExpandedReject('recompression-check-history');
        }
        if (self.active() && self.exposure.endedAt != nil) rpgExpandedReject('recompression-pressure-interrupted');
        return nil;
    }
    assess()
    {
        local value = new RpgExpandedResult();
        if (self.id == nil || self.id == '' || self.episode == nil || !self.episode.ofKind(RpgExpandedDecompressionIllness)
            || self.exposure == nil || !self.exposure.ofKind(RpgExpandedPressureExposure)) rpgExpandedReject('recompression-definition');
        if (self.startedAt != nil) { self.validate(); value.status = 'reused'; return value; }
        self.episode.validateReceipt(); self.exposure.validateBinding();
        if (!self.approved || !self.highestConfirmed || self.evidence == nil || self.evidence == '')
        { value.reason = 'recompression-highest-pressure-evidence'; return value; }
        if (!holds(['agony','unconscious','paralysis'],self.episode.phase) || self.episode.profile().dead)
        { value.reason = 'recompression-patient-inactive'; return value; }
        if (self.exposure.profile != self.episode.profile() || self.exposure.endedAt != nil
            || self.exposure.pressure != self.episode.source.pressure)
        { value.reason = 'recompression-pressure-required'; return value; }
        foreach (local prior in self.episode.recompressions)
        {
            prior.validate();
            if (prior.id == self.id || prior.active()) rpgExpandedReject('recompression-overlap');
        }
        rpgInteger(rpgLedger.seconds,0,2147483347);
        value.status = 'ready'; value.modifier = 4; value.seconds = 300; return value;
    }
    begin()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        self.startedAt = rpgLedger.seconds; self.dueAt = self.startedAt + 300;
        self.boundDefinition = self.definition(); self.episode.recompressions = self.episode.recompressions + [self];
        value.status = 'resolved'; return value;
    }
    cancel()
    {
        self.validate(); local value = new RpgExpandedResult();
        if (self.cancelledAt != nil) { value.status = 'reused'; return value; }
        self.cancelledAt = rpgLedger.seconds; self.boundCancelledAt = self.cancelledAt;
        value.status = 'resolved'; return value;
    }
;
class RpgExpandedRecompressionCheck: object
    treatment = nil
    boundTreatment = nil
    checkedAt = nil
    result = nil
    assess()
    {
        if (self.treatment == nil || !self.treatment.ofKind(RpgExpandedRecompression)) rpgExpandedReject('recompression-check-treatment');
        self.treatment.validate(); local value = new RpgExpandedDecompressionIllnessResult();
        if (self.result != nil)
        {
            if (self.treatment != self.boundTreatment || !holds(self.treatment.checks,self)) rpgExpandedReject('recompression-check-owner');
            value.status = 'reused'; return value;
        }
        if (!self.treatment.active()) { value.reason = 'recompression-check-inactive'; return value; }
        if (rpgLedger.seconds != self.treatment.dueAt) { value.reason = 'recompression-check-time'; return value; }
        rpgInteger(rpgLedger.seconds,0,2147483347);
        value.modifier = 4; value.seconds = 300; value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status == 'reused') return self.result;
        if (value.status != 'ready') return value;
        local treatment = self.treatment; local episode = treatment.episode; local oldPhase = episode.phase;
        value.check = rpgLiteAttributeCheck(episode.profile(),rpgHT,'resistance',4);
        value.phase = value.check.achieved ? 'recovered' : episode.phase;
        self.boundTreatment = treatment; self.checkedAt = rpgLedger.seconds;
        value.status = 'resolved'; self.result = value;
        treatment.checks = treatment.checks + [self]; treatment.dueAt += 300;
        if (value.check.achieved)
        {
            episode.symptomRelief = self; episode.phase = 'recovered';
            if (oldPhase == 'unconscious' && !episode.profile().unconsciousRecoveryOwned() && !episode.profile().dead && !episode.profile().mortal
                && episode.profile().hp() > 0 && episode.profile().fp() > 0) episode.profile().unconscious = nil;
        }
        treatment.validate(); return value;
    }
;
modify rpgLedger
    validateAdvance(seconds)
    {
        inherited(seconds);
        for (local treatment = firstObj(RpgExpandedRecompression); treatment != nil; treatment = nextObj(treatment,RpgExpandedRecompression))
            if (treatment.startedAt != nil)
            {
                treatment.validate();
                if (treatment.active() && self.seconds + seconds > treatment.dueAt) rpgExpandedReject('recompression-check-boundary');
            }
        return nil;
    }
;

/** B434 acceleration in thousandths of standard gravity. */
class RpgExpandedAccelerationResult: RpgExpandedResult
    checkRequired = nil
    fatigueLoss = nil
    blackoutSeconds = 0
;
rpgExpandedAssessAcceleration(acceleration,homeGravity,orientation)
{
    rpgInteger(acceleration,0,1000000); rpgInteger(homeGravity,0,1000000);
    if (!holds(['upright','seated','prone','inverted'],orientation)) rpgExpandedReject('acceleration-orientation');
    local home = homeGravity < 100 ? 100 : homeGravity;
    local value = new RpgExpandedAccelerationResult(); value.status = 'ready';
    value.checkRequired = acceleration * 2 >= home * 5;
    local threshold = home * 5; value.modifier = 0;
    while (acceleration >= threshold) { value.modifier -= 2; threshold *= 2; }
    if (holds(['seated','prone'],orientation)) value.modifier += 2;
    if (orientation == 'inverted') value.modifier -= 2;
    return value;
}
modify RpgExpandedProfile
    accelerations = []
    accelerationFatigueLosses = []
    unconsciousRecoveryApartFrom(owner)
    {
        foreach (local episode in self.accelerations)
        {
            episode.validateReceipt();
            if (episode != owner && episode.result.blackoutSeconds > 0 && episode.recoveredAt == nil) return true;
        }
        return inherited(owner);
    }
;
class RpgExpandedAccelerationFatigueLoss: RpgExpandedFearFatigueLoss
    maximumAmount() { return 15; }
    fatigueCause() { return 'acceleration'; }
    history() { return self.profile.accelerationFatigueLosses; }
    remember() { self.profile.accelerationFatigueLosses = self.profile.accelerationFatigueLosses + [self]; }
    woundId(index) { return 'acceleration-fatigue:' + self.id + ':' + index; }
;
class RpgExpandedAcceleration: object
    id = nil
    profile = nil
    acceleration = nil
    homeGravity = nil
    orientation = 'upright'
    approved = nil
    evidence = nil
    dropDestination = nil
    startedAt = nil
    recoveredAt = nil
    boundRecoveredAt = nil
    boundDefinition = nil
    result = nil
    definition() { return [self.id,self.profile,self.acceleration,self.homeGravity,self.orientation,self.approved,self.evidence,self.dropDestination,self.startedAt]; }
    validateReceipt()
    {
        if (self.result == nil || !holds(self.profile.accelerations,self)) rpgExpandedReject('acceleration-owner');
        local current = self.definition();
        for (local i = 1; i <= current.length(); i += 1)
            if (current[i] != self.boundDefinition[i]) rpgExpandedReject('acceleration-binding');
        if (self.recoveredAt != self.boundRecoveredAt) rpgExpandedReject('acceleration-recovery-binding');
        return nil;
    }
    loss(amount)
    {
        local loss = new RpgExpandedAccelerationFatigueLoss(); loss.id = self.id;
        loss.profile = self.profile; loss.amount = amount; loss.dropDestination = self.dropDestination; return loss;
    }
    assess()
    {
        if (self.id == nil || self.id == '' || self.profile == nil || !self.profile.ofKind(RpgExpandedProfile))
            rpgExpandedReject('acceleration-definition');
        if (self.result != nil)
        { self.validateReceipt(); local reused = new RpgExpandedAccelerationResult(); reused.status = 'reused'; return reused; }
        local value = rpgExpandedAssessAcceleration(self.acceleration,self.homeGravity,self.orientation);
        value.status = 'blocked';
        if (!self.approved || self.evidence == nil || self.evidence == '') { value.reason = 'acceleration-evidence'; return value; }
        rpgExpandedValidate(self.profile);
        if (self.profile.dead || self.profile.unconscious || self.profile.unconsciousRecoveryOwned())
        { value.reason = 'acceleration-existing-unconsciousness'; return value; }
        foreach (local prior in self.profile.accelerations)
        { prior.validateReceipt(); if (prior.id == self.id) rpgExpandedReject('acceleration-duplicate'); }
        if (value.checkRequired)
        {
            local context = new RpgLiteContext(); context.attribute = rpgHT; context.kind = 'resistance';
            context.modifier = value.modifier;
            local score = rpgLiteScore(self.profile,context);
            if (score == nil || score < 3 || score > 16)
            { value.reason = 'acceleration-score-range-unimplemented'; return value; }
            // Preflight every possible fatigue amount before consuming the onset roll.
            for (local amount = 1; amount <= 18-score; amount += 1)
                if (self.loss(amount).assess().status != 'ready') { value.reason = 'acceleration-fatigue-unavailable'; return value; }
            rpgInteger(rpgLedger.seconds,0,2147483497);
        }
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status == 'reused') return self.result;
        if (value.status != 'ready') return value;
        if (value.checkRequired)
        {
            value.check = rpgLiteAttributeCheck(self.profile,rpgHT,'resistance',value.modifier);
            if (!value.check.achieved)
            {
                value.fatigueLoss = self.loss(-value.check.margin);
                if (value.check.critical == 'failure') value.blackoutSeconds = -value.check.margin * 10;
            }
        }
        self.startedAt = rpgLedger.seconds; self.boundDefinition = self.definition();
        value.status = 'resolved'; self.result = value; self.profile.accelerations = self.profile.accelerations + [self];
        if (value.fatigueLoss != nil && value.fatigueLoss.apply().status != 'resolved') rpgExpandedReject('acceleration-fatigue-changed');
        if (value.blackoutSeconds > 0) self.profile.becomeUnconscious();
        self.validateReceipt(); return value;
    }
    recover()
    {
        self.validateReceipt(); local value = new RpgExpandedResult();
        if (self.recoveredAt != nil) { value.status = 'reused'; return value; }
        if (self.result.blackoutSeconds == 0 || self.profile.dead) { value.reason = 'acceleration-no-blackout'; return value; }
        if (rpgLedger.seconds < self.startedAt + self.result.blackoutSeconds) { value.reason = 'acceleration-blackout-not-due'; return value; }
        self.recoveredAt = rpgLedger.seconds; self.boundRecoveredAt = self.recoveredAt;
        if (!self.profile.unconsciousRecoveryOwned() && !self.profile.mortal && self.profile.hp() > 0 && self.profile.fp() > 0
            && self.profile.cardiacArrest == nil && self.profile.fearSeconds == 0 && !self.profile.apparentDeath && !self.profile.needsMedicalHelp)
        { self.profile.unconscious = nil; self.profile.unconsciousClock = 0; }
        value.status = 'resolved'; return value;
    }
;
modify rpgLedger
    validateAdvance(seconds)
    {
        inherited(seconds);
        for (local episode = firstObj(RpgExpandedAcceleration); episode != nil; episode = nextObj(episode,RpgExpandedAcceleration))
            if (episode.result != nil && !episode.profile.dead)
            {
                episode.validateReceipt();
                if (episode.recoveredAt == nil && episode.result.blackoutSeconds > 0
                    && self.seconds + seconds > episode.startedAt + episode.result.blackoutSeconds)
                    rpgExpandedReject('acceleration-blackout-boundary');
            }
        return nil;
    }
;


/** B434 acceleration impact: thousandths-G numerically equals hundredths yd/s. */
class RpgExpandedAccelerationImpact: RpgExpandedFallImpact
    accelerationEvent = nil
    velocityScale = 100
    definition() { return inherited() + [self.accelerationEvent]; }
    assess()
    {
        if (self.accelerationEvent == nil || !self.accelerationEvent.ofKind(RpgExpandedAcceleration))
            rpgExpandedReject('acceleration-impact-event');
        self.accelerationEvent.validateReceipt();
        if (self.injury == nil || !self.injury.ofKind(RpgExpandedFallInjury)
            || self.injury.profile != self.accelerationEvent.profile || self.injury.fall != self.accelerationEvent
            || self.injury.damageVelocity != self.accelerationEvent.acceleration || self.velocityScale != 100
            || self.injury.landing != nil) rpgExpandedReject('acceleration-impact-binding');
        if (self.result == nil && rpgLedger.seconds != self.accelerationEvent.startedAt)
        { local value = new RpgExpandedFallImpactResult(); value.reason = 'acceleration-impact-time'; return value; }
        return inherited();
    }
;

/** B434 free-fall entry/adaptation; physiological facts require author evidence. */
class RpgExpandedFreeFallResult: RpgExpandedResult
    context = nil
    score = nil
    unaffected = nil
;
class RpgExpandedFreeFallExposure: object
    id = nil
    profile = nil
    skill = nil
    native = nil
    susceptible = nil
    entrySusceptible = nil
    effectiveSusceptibility() { return self.result == nil ? (self.susceptible || self.profile.freeFallSusceptible(true)) : self.entrySusceptible; }
    approved = nil
    evidence = nil
    startedAt = nil
    dueAt = nil
    nausea = nil
    motion = nil
    endedAt = nil
    boundEndedAt = nil
    endEvidence = nil
    boundEndEvidence = nil
    adapted = nil
    checks = []
    result = nil
    boundDefinition = nil
    definition() { return [self.id,self.profile,self.skill,self.native,self.susceptible,self.approved,self.evidence,self.startedAt,self.entrySusceptible]; }
    validateReceipt()
    {
        if (self.result == nil || !holds(self.profile.freeFallExposures,self)) rpgExpandedReject('free-fall-owner');
        local current = self.definition();
        for (local i = 1; i <= current.length(); i += 1)
            if (current[i] != self.boundDefinition[i]) rpgExpandedReject('free-fall-binding');
        if (self.endedAt == nil && !self.adapted && self.entrySusceptible != (self.susceptible || self.profile.freeFallSusceptible(true)))
            rpgExpandedReject('free-fall-susceptibility-changed');
        local expected = self.result.unaffected;
        foreach (local check in self.checks)
        {
            if (check.exposure != self || check.boundExposure != self || check.result == nil) rpgExpandedReject('free-fall-check-history');
            expected = check.result.unaffected;
        }
        if (self.endedAt != self.boundEndedAt || self.endEvidence != self.boundEndEvidence) rpgExpandedReject('free-fall-exit-binding');
        if (self.adapted != expected || self.dueAt != self.startedAt + (self.checks.length()+1)*28800)
            rpgExpandedReject('free-fall-state');
        return nil;
    }
    resistance()
    {
        local value = new RpgExpandedFreeFallResult();
        value.context = new RpgLiteContext(); value.context.attribute = rpgHT; value.context.kind = 'resistance';
        value.context.modifier = self.effectiveSusceptibility() ? -4 : 0;
        value.score = rpgLiteScore(self.profile,value.context);
        if (!self.effectiveSusceptibility())
        {
            local skill = self.skill;
            if (skill == nil)
            { skill = new RpgExpandedFreeFallSkill(); }
            if (!skill.ofKind(RpgExpandedSkill) || skill.id != 'free-fall' || skill.attribute != rpgDX || skill.difficulty != 1)
                rpgExpandedReject('free-fall-skill-definition');
            local alternative = new RpgLiteContext(); alternative.skill = skill; alternative.kind = 'resistance';
            local score = rpgLiteScore(self.profile,alternative);
            if (score != nil && (value.score == nil || score > value.score)) { value.score = score; value.context = alternative; }
        }
        if (value.score == nil || value.score < 3) { value.reason = 'free-fall-resistance-unavailable'; return value; }
        value.status = 'ready'; return value;
    }
    leave(normalGravityConfirmed,evidence)
    {
        self.validateReceipt(); local value = new RpgExpandedResult();
        if (self.endedAt != nil) { value.status = 'reused'; return value; }
        if (!normalGravityConfirmed || evidence == nil || evidence == '')
        { value.reason = 'free-fall-return-gravity-evidence'; return value; }
        if (self.motion != nil)
        {
            self.motion.validateReceipt(); self.nausea.validateReceipt();
            if (!self.profile.dead && self.motion.endedAt == nil && rpgLedger.seconds >= self.motion.nextCheckAt)
            { value.reason = 'free-fall-motion-hour-due'; return value; }
            if (self.motion.endedAt == nil)
            { self.motion.endEvidence = evidence; if (self.motion.end().status != 'resolved') rpgExpandedReject('free-fall-exit-motion'); }
            if (self.nausea.endedAt == nil)
            { self.nausea.endEvidence = evidence; if (self.nausea.end().status != 'resolved') rpgExpandedReject('free-fall-exit-nausea'); }
        }
        self.endedAt = rpgLedger.seconds; self.boundEndedAt = self.endedAt;
        self.endEvidence = evidence; self.boundEndEvidence = evidence;
        value.status = 'resolved'; return value;
    }
    prepareNausea()
    {
        local nausea = new RpgExpandedNausea(); nausea.id = 'free-fall:' + self.id; nausea.profile = self.profile;
        nausea.approved = true; nausea.causeEvidence = self.evidence; return nausea;
    }
    prepareMotion()
    {
        local motion = new RpgExpandedNauseaMotion(); motion.id = 'free-fall:' + self.id; motion.profile = self.profile;
        motion.kind = 'free-fall'; motion.approved = true; motion.evidence = self.evidence; return motion;
    }
    assess()
    {
        if (self.id == nil || self.id == '' || self.profile == nil || !self.profile.ofKind(RpgExpandedProfile)) rpgExpandedReject('free-fall-definition');
        local value = new RpgExpandedFreeFallResult();
        if (self.result != nil) { self.validateReceipt(); value.status = 'reused'; return value; }
        if (!self.approved || self.evidence == nil || self.evidence == '') { value.reason = 'free-fall-physiology-evidence'; return value; }
        rpgExpandedValidate(self.profile);
        if (self.profile.dead || self.profile.unconscious) { value.reason = 'free-fall-patient-unavailable'; return value; }
        foreach (local prior in self.profile.freeFallExposures)
        { prior.validateReceipt(); if (prior.id == self.id || prior.endedAt == nil) rpgExpandedReject('free-fall-overlap'); }
        if (self.native && self.effectiveSusceptibility()) rpgExpandedReject('free-fall-physiology-conflict');
        if (!self.native)
        {
            value = self.resistance(); if (value.status != 'ready') return value;
            if (self.prepareNausea().assess().status != 'ready' || self.prepareMotion().assess().status != 'ready')
            { value.status = 'blocked'; value.reason = 'free-fall-nausea-unavailable'; return value; }
        }
        rpgInteger(rpgLedger.seconds,0,2147454847); value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status == 'reused') return self.result;
        if (value.status != 'ready') return value;
        if (!self.native) value.check = rpgLiteCheck(self.profile,value.context);
        value.unaffected = self.native || value.check.achieved;
        self.entrySusceptible = self.effectiveSusceptibility();
        self.startedAt = rpgLedger.seconds; self.dueAt = self.startedAt + 28800; self.adapted = value.unaffected;
        self.boundDefinition = self.definition(); value.status = 'resolved'; self.result = value;
        self.profile.freeFallExposures = self.profile.freeFallExposures + [self];
        if (!self.adapted)
        {
            self.nausea = self.prepareNausea(); self.motion = self.prepareMotion();
            if (self.nausea.apply().status != 'resolved' || self.motion.apply().status != 'resolved') rpgExpandedReject('free-fall-onset-changed');
        }
        return value;
    }
;
modify RpgExpandedProfile
    freeFallExposures = []
;
class RpgExpandedFreeFallAdaptation: object
    exposure = nil
    boundExposure = nil
    result = nil
    assess()
    {
        if (self.exposure == nil || !self.exposure.ofKind(RpgExpandedFreeFallExposure)) rpgExpandedReject('free-fall-adaptation-exposure');
        self.exposure.validateReceipt(); local value = new RpgExpandedFreeFallResult();
        if (self.result != nil)
        {
            if (self.exposure != self.boundExposure || !holds(self.exposure.checks,self)) rpgExpandedReject('free-fall-adaptation-owner');
            value.status = 'reused'; return value;
        }
        if (self.exposure.endedAt != nil || self.exposure.adapted || self.exposure.profile.dead || self.exposure.effectiveSusceptibility())
        { value.reason = 'free-fall-adaptation-unavailable'; return value; }
        if (rpgLedger.seconds != self.exposure.dueAt) { value.reason = 'free-fall-adaptation-time'; return value; }
        self.exposure.motion.validateReceipt(); self.exposure.nausea.validateReceipt();
        if (self.exposure.motion.endedAt != nil || self.exposure.nausea.endedAt != nil)
        { value.reason = 'free-fall-cause-ended'; return value; }
        // Resolve the completed eighth motion hour before changing the cause.
        if (self.exposure.motion.nextCheckAt <= rpgLedger.seconds)
        { value.reason = 'free-fall-motion-hour-due'; return value; }
        rpgInteger(rpgLedger.seconds,0,2147454847); return self.exposure.resistance();
    }
    apply()
    {
        local value = self.assess(); if (value.status == 'reused') return self.result;
        if (value.status != 'ready') return value;
        local e = self.exposure; value.check = rpgLiteCheck(e.profile,value.context); value.unaffected = value.check.achieved;
        value.status = 'resolved'; self.result = value; self.boundExposure = e;
        e.checks = e.checks + [self]; e.dueAt += 28800; e.adapted = value.unaffected;
        if (e.adapted)
        {
            e.nausea.endEvidence = 'Successful eight-hour adaptation'; e.motion.endEvidence = e.nausea.endEvidence;
            if (e.nausea.end().status != 'resolved' || e.motion.end().status != 'resolved') rpgExpandedReject('free-fall-recovery-changed');
        }
        e.validateReceipt(); return value;
    }
;
modify rpgLedger
    validateAdvance(seconds)
    {
        inherited(seconds);
        for (local exposure = firstObj(RpgExpandedFreeFallExposure); exposure != nil; exposure = nextObj(exposure,RpgExpandedFreeFallExposure))
            if (exposure.result != nil && !exposure.profile.dead)
            {
                exposure.validateReceipt();
                if (exposure.endedAt == nil && !exposure.adapted && !exposure.effectiveSusceptibility() && self.seconds+seconds > exposure.dueAt)
                    rpgExpandedReject('free-fall-adaptation-boundary');
            }
        return nil;
    }
;


/** B197 environmental base cap. Situational modifiers are applied once afterward. */
modify RpgExpandedProfile
    environmentBaseScore(context,score)
    {
        local base = inherited(context,score);
        if (base == nil || context.controllingAttribute() != rpgDX) return base;
        foreach (local exposure in self.freeFallExposures)
        {
            exposure.validateReceipt();
            if (exposure.endedAt == nil)
            {
                local skill = exposure.skill == nil ? new RpgExpandedFreeFallSkill() : exposure.skill;
                local limit = self.skillScore(skill);
                if (limit == nil) return nil;
                if (limit < base) base = limit;
            }
        }
        return base;
    }
;

modify RpgExpandedProfile
    sustenanceDeprivations = []
;
/** B130 confirmed missed access; calendar/dose satisfaction remains authored. */
class RpgExpandedSustenanceDeprivation: object
    id = nil
    profile = nil
    requirement = nil
    approved = nil
    evidence = nil
    dropDestination = nil
    startedAt = nil
    intervalSeconds = nil
    boundDefinition = nil
    ticks = []
    contact = nil
    contacts = []
    restoration = nil
    definition()
    {
        return [self.id,self.profile,self.requirement,self.approved,self.evidence,self.dropDestination,self.startedAt,self.intervalSeconds,self.requirement.scope,self.requirement.level,self.requirement.points]
            + self.requirement.templatePurchaseOptions();
    }
    nextTickAt() { return self.startedAt + (self.ticks.length() + 1) * self.intervalSeconds; }
    validateReceipt()
    {
        if (self.startedAt == nil || !holds(self.profile.sustenanceDeprivations,self) || self.boundDefinition == nil)
            rpgExpandedReject('sustenance-deprivation-history');
        local facts = self.definition();
        if (facts.length() != self.boundDefinition.length()) rpgExpandedReject('sustenance-deprivation-binding');
        for (local index = 1; index <= facts.length(); index += 1)
            if (facts[index] != self.boundDefinition[index]) rpgExpandedReject('sustenance-deprivation-binding');
        local index = 0; local ids = [];
        foreach (local tick in self.ticks)
        {
            index += 1;
            if (tick == nil || !tick.ofKind(RpgExpandedSustenanceInjury) || tick.episode != self || holds(ids,tick.id)
                || tick.recordedAt != self.startedAt + index * self.intervalSeconds || tick.recordedAt > rpgLedger.seconds)
                rpgExpandedReject('sustenance-tick-history');
            ids = ids + [tick.id]; tick.validateReceipt();
        }
        local previous = nil; local seen = [];
        foreach (local contact in self.contacts)
        {
            if (contact == nil || !contact.ofKind(RpgExpandedSustenanceContact) || contact.episode != self || holds(seen,contact)
                || contact.previousContact != previous || contact.startedAt < self.startedAt || contact.startedAt > rpgLedger.seconds
                || previous != nil && (previous.interruptedAt == nil || contact.startedAt < previous.interruptedAt))
                rpgExpandedReject('sustenance-contact-sequence');
            contact.validateReceipt(); seen = seen + [contact]; previous = contact;
        }
        if (self.contact != previous) rpgExpandedReject('sustenance-contact-sequence');
        if (self.restoration != nil)
        {
            if (self.restoration.ofKind(RpgExpandedSustenanceContact))
            {
                if (self.restoration != self.contact || self.restoration.completedAt == nil)
                    rpgExpandedReject('sustenance-restoration-history');
            }
            else if (self.restoration.ofKind(RpgExpandedSustenanceDose))
            {
                if (self.restoration.episode != self || self.contact != nil) rpgExpandedReject('sustenance-restoration-history');
                self.restoration.validateReceipt();
            }
            else if (self.restoration.ofKind(RpgExpandedContinuousSustenanceAccess))
            {
                if (self.restoration.episode != self || self.contact != nil) rpgExpandedReject('sustenance-restoration-history');
                self.restoration.validateReceipt();
            }
            else rpgExpandedReject('sustenance-restoration-type');
        }
        return nil;
    }
    assess()
    {
        if (self.id == nil || self.id == '' || self.profile == nil || !self.profile.ofKind(RpgExpandedProfile) || self.requirement == nil)
            rpgExpandedReject('sustenance-deprivation-definition');
        local value = new RpgExpandedResult();
        if (self.startedAt != nil) { self.validateReceipt(); value.status = 'reused'; return value; }
        if (self.boundDefinition != nil || self.intervalSeconds != nil || self.ticks.length() != 0 || self.contacts.length() != 0 || self.contact != nil || self.restoration != nil)
            rpgExpandedReject('sustenance-deprivation-uncommitted-state');
        if (!self.approved || self.evidence == nil || self.evidence == '')
        { value.reason = 'sustenance-missed-access-evidence'; return value; }
        if (self.profile.dead) { value.reason = 'sustenance-dead'; return value; }
        local interval = self.profile.sustenanceInjuryInterval(self.requirement);
        rpgInteger(rpgLedger.seconds,0,2147483647 - interval);
        foreach (local prior in self.profile.sustenanceDeprivations)
        {
            prior.validateReceipt();
            if (prior.id == self.id || prior.requirement == self.requirement && prior.restoration == nil) rpgExpandedReject('sustenance-deprivation-duplicate');
        }
        value.status = 'ready'; return value;
    }
    begin()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        self.intervalSeconds = self.profile.sustenanceInjuryInterval(self.requirement); self.startedAt = rpgLedger.seconds;
        self.boundDefinition = self.definition(); self.profile.sustenanceDeprivations = self.profile.sustenanceDeprivations + [self];
        self.profile.recordContinuousSustenanceLoss(self);
        value.status = 'resolved'; return value;
    }
;
class RpgExpandedSustenanceInjury: object
    id = nil
    episode = nil
    recordedAt = nil
    wound = nil
    agingAdvance = nil
    boundDefinition = nil
    definition() { return [self.id,self.episode,self.recordedAt,self.wound,self.agingAdvance]; }
    validateReceipt()
    {
        if (self.recordedAt == nil || self.wound == nil || self.boundDefinition == nil || !holds(self.episode.ticks,self))
            rpgExpandedReject('sustenance-injury-history');
        local facts = self.definition();
        for (local index = 1; index <= facts.length(); index += 1)
            if (facts[index] != self.boundDefinition[index]) rpgExpandedReject('sustenance-injury-binding');
        self.wound.assess(); if (self.agingAdvance != nil) self.agingAdvance.validateReceipt(); return nil;
    }
    makeWound()
    {
        local wound = new RpgExpandedWound(); wound.id = 'sustenance:' + self.episode.id + ':' + self.id;
        wound.profile = self.episode.profile; wound.amount = 1; wound.dropDestination = self.episode.dropDestination; return wound;
    }
    assess()
    {
        if (self.id == nil || self.id == '' || self.episode == nil || !self.episode.ofKind(RpgExpandedSustenanceDeprivation))
            rpgExpandedReject('sustenance-injury-definition');
        local value = new RpgExpandedResult(); self.episode.validateReceipt();
        if (self.recordedAt != nil) { self.validateReceipt(); value.status = 'reused'; return value; }
        if (self.wound != nil || self.boundDefinition != nil) rpgExpandedReject('sustenance-injury-uncommitted-state');
        if (self.episode.profile.dead) { value.reason = 'sustenance-dead'; return value; }
        if (self.episode.restoration != nil) { value.reason = 'sustenance-access-restored'; return value; }
        self.episode.profile.sustenanceInjuryInterval(self.episode.requirement);
        if (rpgLedger.seconds != self.episode.nextTickAt()) { value.reason = 'sustenance-injury-not-due'; return value; }
        foreach (local tick in self.episode.ticks) if (tick.id == self.id) rpgExpandedReject('sustenance-injury-duplicate');
        rpgInteger(rpgLedger.seconds,0,2147483647 - self.episode.intervalSeconds);
        local injury = self.makeWound().assess(); if (injury.status != 'ready') return injury;
        if (self.episode.profile.sustenanceAgingRequired(self.episode.requirement))
        {
            if (self.agingAdvance == nil || !self.agingAdvance.ofKind(RpgExpandedSustenanceAgingAdvance) || self.agingAdvance.tick != self)
                rpgExpandedReject('sustenance-aging-advance-required');
            local aging = self.agingAdvance.assess(); if (aging.status != 'ready') return aging;
        }
        else if (self.agingAdvance != nil) rpgExpandedReject('sustenance-aging-modifier-required');
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        self.wound = self.makeWound(); self.wound.apply(); self.recordedAt = rpgLedger.seconds;
        self.boundDefinition = self.definition(); self.episode.ticks = self.episode.ticks + [self];
        if (self.agingAdvance != nil) self.agingAdvance.commit();
        value.status = 'resolved'; return value;
    }
;
modify rpgLedger
    validateAdvance(seconds)
    {
        inherited(seconds);
        for (local episode = firstObj(RpgExpandedSustenanceDeprivation); episode != nil; episode = nextObj(episode,RpgExpandedSustenanceDeprivation))
            if (episode.startedAt != nil && !episode.profile.dead)
            {
                episode.validateReceipt();
                if (episode.restoration == nil && self.seconds + seconds > episode.nextTickAt()) rpgExpandedReject('sustenance-injury-boundary');
            }
        return nil;
    }
;

/** One uninterrupted, authored object/environment contact interval. */
class RpgExpandedSustenanceContact: object
    episode = nil
    approved = nil
    evidence = nil
    boundaryOrder = nil
    contactPolicy = nil
    previousContact = nil
    startedAt = nil
    requiredSeconds = nil
    boundDefinition = nil
    completedAt = nil
    completionEvidence = nil
    boundCompletion = nil
    interruptedAt = nil
    interruptionEvidence = nil
    boundInterruption = nil
    definition() { return [self.episode,self.approved,self.evidence,self.boundaryOrder,self.contactPolicy,self.previousContact,self.startedAt,self.requiredSeconds]; }
    validateReceipt()
    {
        if (self.startedAt == nil || !holds(self.episode.contacts,self) || self.boundDefinition == nil)
            rpgExpandedReject('sustenance-contact-history');
        local facts = self.definition();
        for (local index = 1; index <= facts.length(); index += 1)
            if (facts[index] != self.boundDefinition[index]) rpgExpandedReject('sustenance-contact-binding');
        if (self.completedAt != nil)
        {
            if (self.episode.restoration != self || self.completedAt != self.boundCompletion[1]
                || self.completionEvidence != self.boundCompletion[2] || self.completedAt < self.startedAt + self.requiredSeconds
                || self.completedAt > rpgLedger.seconds) rpgExpandedReject('sustenance-contact-completion-binding');
        }
        else if (self.boundCompletion != nil || self.completionEvidence != nil) rpgExpandedReject('sustenance-contact-incomplete-state');
        if (self.interruptedAt != nil)
        {
            if (self.completedAt != nil || self.boundInterruption == nil || self.interruptedAt != self.boundInterruption[1]
                || self.interruptionEvidence != self.boundInterruption[2] || self.interruptedAt < self.startedAt
                || self.interruptedAt > rpgLedger.seconds) rpgExpandedReject('sustenance-contact-interruption-binding');
        }
        else if (self.boundInterruption != nil || self.interruptionEvidence != nil)
            rpgExpandedReject('sustenance-contact-interruption-state');
        return nil;
    }
    assess()
    {
        if (self.episode == nil || !self.episode.ofKind(RpgExpandedSustenanceDeprivation)) rpgExpandedReject('sustenance-contact-episode');
        local value = new RpgExpandedResult(); self.episode.validateReceipt();
        if (self.startedAt != nil) { self.validateReceipt(); value.status = 'reused'; return value; }
        if (self.previousContact != nil || self.boundDefinition != nil || self.requiredSeconds != nil || self.completedAt != nil || self.boundCompletion != nil
            || self.completionEvidence != nil || self.interruptedAt != nil || self.interruptionEvidence != nil || self.boundInterruption != nil)
            rpgExpandedReject('sustenance-contact-uncommitted-state');
        if (self.episode.contact != nil && self.episode.contact.interruptedAt == nil || self.episode.restoration != nil) rpgExpandedReject('sustenance-contact-duplicate');
        if (!self.approved || self.evidence == nil || self.evidence == '')
        { value.reason = 'sustenance-contact-author-facts'; return value; }
        if (self.contactPolicy != 'uninterrupted') rpgExpandedReject('sustenance-contact-policy-required');
        if (!holds(['injury-first','access-first'],self.boundaryOrder)) rpgExpandedReject('sustenance-contact-boundary-ruling');
        if (self.episode.profile.dead) { value.reason = 'sustenance-dead'; return value; }
        local duration = self.episode.profile.sustenanceContactSeconds(self.episode.requirement);
        rpgInteger(rpgLedger.seconds,0,2147483647 - duration); value.seconds = duration; value.status = 'ready'; return value;
    }
    begin()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        self.previousContact = self.episode.contact; self.requiredSeconds = value.seconds;
        self.startedAt = rpgLedger.seconds; self.boundDefinition = self.definition();
        self.episode.contacts = self.episode.contacts + [self]; self.episode.contact = self; value.status = 'resolved'; return value;
    }
    assessCompletion()
    {
        self.episode.validateReceipt(); self.validateReceipt(); local value = new RpgExpandedResult();
        if (self.completedAt != nil) { value.status = 'reused'; return value; }
        if (self.interruptedAt != nil) { value.reason = 'sustenance-contact-interrupted'; return value; }
        if (self.episode.profile.dead) { value.reason = 'sustenance-dead'; return value; }
        self.episode.profile.sustenanceContactSeconds(self.episode.requirement);
        if (rpgLedger.seconds < self.startedAt + self.requiredSeconds)
        { value.reason = 'sustenance-contact-too-short'; return value; }
        if (self.episode.nextTickAt() < rpgLedger.seconds
            || self.boundaryOrder == 'injury-first' && self.episode.nextTickAt() == rpgLedger.seconds)
        { value.reason = 'sustenance-contact-injury-due'; return value; }
        value.status = 'ready'; return value;
    }
    interrupt(approved,evidence)
    {
        self.episode.validateReceipt(); self.validateReceipt(); local value = new RpgExpandedResult();
        if (self.interruptedAt != nil) { value.status = 'reused'; return value; }
        if (self.completedAt != nil) { value.reason = 'sustenance-contact-already-complete'; return value; }
        if (!approved || evidence == nil || evidence == '')
        { value.reason = 'sustenance-contact-interruption-evidence'; return value; }
        self.interruptedAt = rpgLedger.seconds; self.interruptionEvidence = evidence;
        self.boundInterruption = [self.interruptedAt,self.interruptionEvidence]; value.status = 'resolved'; return value;
    }
    finish(approved,evidence)
    {
        local value = self.assessCompletion(); if (value.status != 'ready') return value;
        if (!approved || evidence == nil || evidence == '')
        { value.status = 'blocked'; value.reason = 'sustenance-contact-continuity-evidence'; return value; }
        self.completedAt = rpgLedger.seconds; self.completionEvidence = evidence;
        self.boundCompletion = [self.completedAt,self.completionEvidence]; self.episode.restoration = self;
        value.status = 'resolved'; return value;
    }
;

/** One inventory quantity is one authored sufficient dose for this requirement scope. */
class RpgExpandedSustenanceStock: RpgLiteItem
    requirementScope = nil
;
class RpgExpandedSustenanceDose: object
    id = nil
    episode = nil
    stock = nil
    approved = nil
    evidence = nil
    boundaryOrder = nil
    completedAt = nil
    boundDefinition = nil
    definition()
    {
        return [self.id,self.episode,self.stock,self.approved,self.evidence,self.boundaryOrder,self.completedAt,
            self.stock.id,self.stock.requirementScope];
    }
    validateReceipt()
    {
        if (self.completedAt == nil || self.boundDefinition == nil || self.episode.restoration != self)
            rpgExpandedReject('sustenance-dose-history');
        local facts = self.definition();
        for (local index = 1; index <= facts.length(); index += 1)
            if (facts[index] != self.boundDefinition[index]) rpgExpandedReject('sustenance-dose-binding');
        rpgInteger(self.completedAt,self.episode.startedAt,rpgLedger.seconds); return nil;
    }
    assess()
    {
        if (self.id == nil || self.id == '' || self.episode == nil || !self.episode.ofKind(RpgExpandedSustenanceDeprivation)
            || self.stock == nil || !self.stock.ofKind(RpgExpandedSustenanceStock)) rpgExpandedReject('sustenance-dose-definition');
        local value = new RpgExpandedResult(); self.episode.validateReceipt();
        if (self.completedAt != nil) { self.validateReceipt(); value.status = 'reused'; return value; }
        if (self.boundDefinition != nil) rpgExpandedReject('sustenance-dose-uncommitted-state');
        if (self.episode.restoration != nil || self.episode.contact != nil) rpgExpandedReject('sustenance-dose-already-restored');
        local profile = self.episode.profile; profile.validateSustenanceDose(self.episode.requirement);
        if (!self.approved || self.evidence == nil || self.evidence == '')
        { value.reason = 'sustenance-dose-ingestion-evidence'; return value; }
        if (!holds(['injury-first','access-first'],self.boundaryOrder)) rpgExpandedReject('sustenance-dose-boundary-ruling');
        if (profile.dead || profile.unconscious || profile.retchingEpisode != nil)
        { value.reason = 'sustenance-dose-ingestion-unavailable'; return value; }
        if (self.stock.id == nil || self.stock.id == '' || self.stock.requirementScope != self.episode.requirement.scope)
            rpgExpandedReject('sustenance-dose-mismatch');
        rpgInteger(self.stock.quantity,0,1000000);
        if (!holds(profile.equipment,self.stock) || !self.stock.usableBy(profile) || self.stock.quantity == 0)
        { value.reason = 'sustenance-dose-unavailable'; return value; }
        local owners = 0;
        for (local owner = firstObj(RpgLiteProfile); owner != nil; owner = nextObj(owner,RpgLiteProfile))
            foreach (local item in owner.equipment) if (item == self.stock) owners += 1;
        if (owners != 1) rpgExpandedReject('sustenance-dose-ownership');
        foreach (local prior in profile.sustenanceDeprivations)
            if (prior.restoration != nil && prior.restoration.ofKind(RpgExpandedSustenanceDose) && prior.restoration.id == self.id)
                rpgExpandedReject('sustenance-dose-duplicate');
        if (self.episode.nextTickAt() < rpgLedger.seconds
            || self.boundaryOrder == 'injury-first' && self.episode.nextTickAt() == rpgLedger.seconds)
        { value.reason = 'sustenance-dose-injury-due'; return value; }
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        rpgExpandedConsumeSustenanceUnit(self.episode.profile,self.stock);
        self.completedAt = rpgLedger.seconds; self.boundDefinition = self.definition(); self.episode.restoration = self;
        value.status = 'resolved'; return value;
    }
;

modify RpgExpandedProfile
    sustenanceDeadlines = []
;
/** Own the next deadline after actual restored access; calendar dates are authored. */
class RpgExpandedSustenanceDeadline: object
    id = nil
    source = nil
    previous = nil
    approved = nil
    evidence = nil
    calendarId = nil
    boundaryId = nil
    calendarDueAt = nil
    registeredAt = nil
    dueAt = nil
    boundDefinition = nil
    missedEpisode = nil
    fulfillment = nil
    timelyContact = nil
    definition()
    {
        return [self.id,self.source,self.previous,self.approved,self.evidence,self.calendarId,self.boundaryId,self.calendarDueAt,
            self.registeredAt,self.dueAt];
    }
    validateReceipt()
    {
        if (self.registeredAt == nil || self.boundDefinition == nil || !holds(self.source.profile.sustenanceDeadlines,self))
            rpgExpandedReject('sustenance-deadline-history');
        self.source.validateReceipt(); local facts = self.definition();
        for (local index = 1; index <= facts.length(); index += 1)
            if (facts[index] != self.boundDefinition[index]) rpgExpandedReject('sustenance-deadline-binding');
        if (self.previous != nil)
        {
            if (!self.previous.ofKind(RpgExpandedSustenanceDeadline) || self.previous.source != self.source
                || self.previous.fulfillment == nil || self.previous.fulfillment.completedAt != self.registeredAt
                || self.previous.registeredAt >= self.registeredAt) rpgExpandedReject('sustenance-deadline-predecessor');
            self.previous.validateReceipt();
        }
        if (self.missedEpisode != nil)
        {
            if (self.missedEpisode.startedAt != self.dueAt || self.missedEpisode.profile != self.source.profile
                || self.missedEpisode.requirement != self.source.requirement)
                rpgExpandedReject('sustenance-deadline-missed-binding');
            self.missedEpisode.validateReceipt();
        }
        if (self.fulfillment != nil)
        {
            if (self.missedEpisode != nil || (!self.fulfillment.ofKind(RpgExpandedSustenanceDueDose)
                && !self.fulfillment.ofKind(RpgExpandedSustenanceDueContact)) || self.fulfillment.deadline != self)
                rpgExpandedReject('sustenance-deadline-fulfillment-history');
            self.fulfillment.validateReceipt();
        }
        if (self.timelyContact != nil)
        {
            if (!self.timelyContact.ofKind(RpgExpandedSustenanceDueContact) || self.timelyContact.deadline != self)
                rpgExpandedReject('sustenance-timely-contact-history');
            self.timelyContact.validateReceipt();
        }
        return nil;
    }
    assess()
    {
        if (self.id == nil || self.id == '' || self.source == nil
            || (!self.source.ofKind(RpgExpandedSustenanceDeprivation) && !self.source.ofKind(RpgExpandedSustenanceInitialAccess)))
            rpgExpandedReject('sustenance-deadline-definition');
        self.source.validateReceipt(); local value = new RpgExpandedResult();
        if (self.registeredAt != nil) { self.validateReceipt(); value.status = 'reused'; return value; }
        if (self.boundDefinition != nil || self.dueAt != nil || self.missedEpisode != nil || self.fulfillment != nil || self.timelyContact != nil)
            rpgExpandedReject('sustenance-deadline-uncommitted-state');
        if (self.source.satisfiedAt() == nil) { value.reason = 'sustenance-deadline-restoration-required'; return value; }
        if (self.source.profile.dead) { value.reason = 'sustenance-dead'; return value; }
        if (!self.approved || self.evidence == nil || self.evidence == '')
        { value.reason = 'sustenance-deadline-author-facts'; return value; }
        local anchor = self.source.satisfiedAt();
        if (self.previous != nil)
        {
            if (!self.previous.ofKind(RpgExpandedSustenanceDeadline) || self.previous == self || self.previous.source != self.source)
                rpgExpandedReject('sustenance-deadline-predecessor');
            self.previous.validateReceipt();
            if (self.previous.fulfillment == nil) { value.reason = 'sustenance-deadline-previous-unfulfilled'; return value; }
            anchor = self.previous.fulfillment.completedAt;
            if (self.calendarId != self.previous.calendarId) rpgExpandedReject('sustenance-deadline-calendar-changed');
        }
        if (rpgLedger.seconds != anchor)
        { value.reason = 'sustenance-deadline-register-at-restoration'; return value; }
        local period = self.source.profile.sustenancePeriod(self.source.requirement);
        if (period[1] > 0)
        {
            if (self.calendarId != nil || self.boundaryId != nil || self.calendarDueAt != nil)
                rpgExpandedReject('sustenance-fixed-period-calendar');
            rpgInteger(rpgLedger.seconds,0,2147483647 - period[1]); value.seconds = period[1];
        }
        else
        {
            if (self.calendarId == nil || self.calendarId == '' || self.boundaryId == nil || self.boundaryId == '')
                rpgExpandedReject('sustenance-calendar-identity');
            rpgInteger(self.calendarDueAt,rpgLedger.seconds + 1,2147483647); value.seconds = self.calendarDueAt - rpgLedger.seconds;
        }
        local latest = nil;
        foreach (local prior in self.source.profile.sustenanceDeadlines)
        {
            prior.validateReceipt();
            if (prior.source == self.source) latest = prior;
            if (prior.id == self.id
                || self.calendarId != nil && prior.calendarId == self.calendarId && prior.boundaryId == self.boundaryId
                    && prior.source.requirement == self.source.requirement) rpgExpandedReject('sustenance-deadline-duplicate');
        }
        if (latest != self.previous) rpgExpandedReject('sustenance-deadline-predecessor');
        value.status = 'ready'; return value;
    }
    register()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        self.registeredAt = rpgLedger.seconds; self.dueAt = self.registeredAt + value.seconds; self.boundDefinition = self.definition();
        self.source.profile.sustenanceDeadlines = self.source.profile.sustenanceDeadlines + [self]; value.status = 'resolved'; return value;
    }
    assessMissed(episode)
    {
        self.validateReceipt(); local value = new RpgExpandedResult();
        if (self.missedEpisode != nil)
        {
            if (episode != self.missedEpisode) rpgExpandedReject('sustenance-deadline-replacement');
            value.status = 'reused'; return value;
        }
        if (self.fulfillment != nil) { value.reason = 'sustenance-deadline-fulfilled'; return value; }
        if (episode == nil || !episode.ofKind(RpgExpandedSustenanceDeprivation) || episode.startedAt != nil
            || episode.profile != self.source.profile || episode.requirement != self.source.requirement)
            rpgExpandedReject('sustenance-deadline-episode');
        if (rpgLedger.seconds != self.dueAt) { value.reason = 'sustenance-deadline-not-due'; return value; }
        return episode.assess();
    }
    miss(episode)
    {
        local value = self.assessMissed(episode); if (value.status != 'ready') return value;
        episode.begin(); self.missedEpisode = episode; value.status = 'resolved'; return value;
    }
;
modify rpgLedger
    validateAdvance(seconds)
    {
        inherited(seconds);
        for (local deadline = firstObj(RpgExpandedSustenanceDeadline); deadline != nil; deadline = nextObj(deadline,RpgExpandedSustenanceDeadline))
            if (deadline.registeredAt != nil)
            {
                deadline.validateReceipt();
                if (!deadline.source.profile.dead && deadline.missedEpisode == nil && deadline.fulfillment == nil && self.seconds + seconds > deadline.dueAt)
                    rpgExpandedReject('sustenance-deadline-boundary');
            }
        return nil;
    }
;

/** Commit only after the caller's ownership, availability and action preflight. */
rpgExpandedConsumeSustenanceUnit(profile,stock)
{
    stock.quantity -= 1;
    if (stock.quantity == 0)
    {
        local remaining = [];
        foreach (local item in profile.equipment) if (item != stock) remaining = remaining + [item];
        profile.equipment = remaining;
    }
    return nil;
}
/** A sufficient dose exactly at an owned deadline, before deprivation begins. */
class RpgExpandedSustenanceDueDose: object
    deadline = nil
    stock = nil
    approved = nil
    evidence = nil
    completedAt = nil
    boundDefinition = nil
    definition() { return [self.deadline,self.stock,self.approved,self.evidence,self.completedAt,self.stock.id,self.stock.requirementScope]; }
    validateReceipt()
    {
        if (self.completedAt == nil || self.boundDefinition == nil || self.deadline.fulfillment != self
            || self.deadline.missedEpisode != nil || self.completedAt != self.deadline.dueAt)
            rpgExpandedReject('sustenance-due-dose-history');
        local facts = self.definition();
        for (local index = 1; index <= facts.length(); index += 1)
            if (facts[index] != self.boundDefinition[index]) rpgExpandedReject('sustenance-due-dose-binding');
        return nil;
    }
    assess()
    {
        if (self.deadline == nil || !self.deadline.ofKind(RpgExpandedSustenanceDeadline)
            || self.stock == nil || !self.stock.ofKind(RpgExpandedSustenanceStock)) rpgExpandedReject('sustenance-due-dose-definition');
        self.deadline.validateReceipt(); local value = new RpgExpandedResult();
        if (self.completedAt != nil) { self.validateReceipt(); value.status = 'reused'; return value; }
        if (self.boundDefinition != nil) rpgExpandedReject('sustenance-due-dose-uncommitted-state');
        if (self.deadline.fulfillment != nil || self.deadline.missedEpisode != nil)
        { value.reason = 'sustenance-deadline-already-settled'; return value; }
        local profile = self.deadline.source.profile; local requirement = self.deadline.source.requirement;
        profile.validateSustenanceDose(requirement);
        if (!self.approved || self.evidence == nil || self.evidence == '')
        { value.reason = 'sustenance-dose-ingestion-evidence'; return value; }
        if (profile.dead || profile.unconscious || profile.retchingEpisode != nil)
        { value.reason = 'sustenance-dose-ingestion-unavailable'; return value; }
        if (rpgLedger.seconds != self.deadline.dueAt) { value.reason = 'sustenance-deadline-not-due'; return value; }
        if (self.stock.id == nil || self.stock.id == '' || self.stock.requirementScope != requirement.scope)
            rpgExpandedReject('sustenance-dose-mismatch');
        rpgInteger(self.stock.quantity,0,1000000);
        if (!holds(profile.equipment,self.stock) || !self.stock.usableBy(profile) || self.stock.quantity == 0)
        { value.reason = 'sustenance-dose-unavailable'; return value; }
        local owners = 0;
        for (local owner = firstObj(RpgLiteProfile); owner != nil; owner = nextObj(owner,RpgLiteProfile))
            foreach (local item in owner.equipment) if (item == self.stock) owners += 1;
        if (owners != 1) rpgExpandedReject('sustenance-dose-ownership');
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        rpgExpandedConsumeSustenanceUnit(self.deadline.source.profile,self.stock);
        self.completedAt = rpgLedger.seconds; self.boundDefinition = self.definition(); self.deadline.fulfillment = self;
        value.status = 'resolved'; return value;
    }
;

/** Full uninterrupted contact ending at the owned period boundary. */
class RpgExpandedSustenanceDueContact: object
    deadline = nil
    approved = nil
    evidence = nil
    contactPolicy = nil
    startedAt = nil
    requiredSeconds = nil
    boundDefinition = nil
    completedAt = nil
    completionEvidence = nil
    boundCompletion = nil
    definition() { return [self.deadline,self.approved,self.evidence,self.contactPolicy,self.startedAt,self.requiredSeconds]; }
    validateReceipt()
    {
        if (self.startedAt == nil || self.boundDefinition == nil || self.deadline.timelyContact != self)
            rpgExpandedReject('sustenance-timely-contact-history');
        local facts = self.definition();
        for (local index = 1; index <= facts.length(); index += 1)
            if (facts[index] != self.boundDefinition[index]) rpgExpandedReject('sustenance-timely-contact-binding');
        if (self.completedAt != nil)
        {
            if (self.boundCompletion == nil || self.completedAt != self.boundCompletion[1] || self.completionEvidence != self.boundCompletion[2]
                || self.completedAt != self.deadline.dueAt || self.deadline.fulfillment != self || self.deadline.missedEpisode != nil
                || self.completedAt - self.startedAt < self.requiredSeconds) rpgExpandedReject('sustenance-timely-contact-completion');
        }
        else if (self.boundCompletion != nil || self.completionEvidence != nil) rpgExpandedReject('sustenance-timely-contact-incomplete-state');
        return nil;
    }
    assess()
    {
        if (self.deadline == nil || !self.deadline.ofKind(RpgExpandedSustenanceDeadline)) rpgExpandedReject('sustenance-timely-contact-definition');
        self.deadline.validateReceipt(); local value = new RpgExpandedResult();
        if (self.startedAt != nil) { self.validateReceipt(); value.status = 'reused'; return value; }
        if (self.boundDefinition != nil || self.requiredSeconds != nil || self.completedAt != nil || self.completionEvidence != nil || self.boundCompletion != nil)
            rpgExpandedReject('sustenance-timely-contact-uncommitted-state');
        if (self.deadline.timelyContact != nil) rpgExpandedReject('sustenance-timely-contact-duplicate');
        if (self.deadline.fulfillment != nil || self.deadline.missedEpisode != nil)
        { value.reason = 'sustenance-deadline-already-settled'; return value; }
        if (!self.approved || self.evidence == nil || self.evidence == '')
        { value.reason = 'sustenance-contact-author-facts'; return value; }
        if (self.contactPolicy != 'uninterrupted') rpgExpandedReject('sustenance-contact-policy-required');
        local profile = self.deadline.source.profile;
        if (profile.dead) { value.reason = 'sustenance-dead'; return value; }
        local duration = profile.sustenanceContactSeconds(self.deadline.source.requirement);
        if (rpgLedger.seconds < self.deadline.registeredAt || self.deadline.dueAt - rpgLedger.seconds < duration)
        { value.reason = 'sustenance-timely-contact-insufficient-time'; return value; }
        value.seconds = duration; value.status = 'ready'; return value;
    }
    begin()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        self.startedAt = rpgLedger.seconds; self.requiredSeconds = value.seconds; self.boundDefinition = self.definition();
        self.deadline.timelyContact = self; value.status = 'resolved'; return value;
    }
    assessCompletion()
    {
        self.deadline.validateReceipt(); self.validateReceipt(); local value = new RpgExpandedResult();
        if (self.completedAt != nil) { value.status = 'reused'; return value; }
        if (self.deadline.fulfillment != nil || self.deadline.missedEpisode != nil)
        { value.reason = 'sustenance-deadline-already-settled'; return value; }
        if (self.deadline.source.profile.dead) { value.reason = 'sustenance-dead'; return value; }
        self.deadline.source.profile.sustenanceContactSeconds(self.deadline.source.requirement);
        if (rpgLedger.seconds != self.deadline.dueAt) { value.reason = 'sustenance-deadline-not-due'; return value; }
        if (rpgLedger.seconds - self.startedAt < self.requiredSeconds)
        { value.reason = 'sustenance-contact-too-short'; return value; }
        value.status = 'ready'; return value;
    }
    finish(approved,evidence)
    {
        local value = self.assessCompletion(); if (value.status != 'ready') return value;
        if (!approved || evidence == nil || evidence == '')
        { value.status = 'blocked'; value.reason = 'sustenance-contact-continuity-evidence'; return value; }
        self.completedAt = rpgLedger.seconds; self.completionEvidence = evidence; self.boundCompletion = [self.completedAt,self.completionEvidence];
        self.deadline.fulfillment = self; value.status = 'resolved'; return value;
    }
;

modify RpgExpandedSustenanceDeprivation
    satisfiedAt() { return self.restoration == nil ? nil : self.restoration.completedAt; }
;
modify RpgExpandedProfile
    sustenanceInitialAccess = []
;
/** Initial campaign fact only; live ingestion uses inventory-backed dose operations. */
class RpgExpandedSustenanceInitialAccess: object
    id = nil
    profile = nil
    requirement = nil
    approved = nil
    evidence = nil
    completedAt = nil
    boundDefinition = nil
    satisfiedAt() { return self.completedAt; }
    definition()
    {
        return [self.id,self.profile,self.requirement,self.approved,self.evidence,self.completedAt,
            self.requirement.scope,self.requirement.level,self.requirement.points] + self.requirement.templatePurchaseOptions();
    }
    validateReceipt()
    {
        if (self.completedAt == nil || self.boundDefinition == nil || !holds(self.profile.sustenanceInitialAccess,self))
            rpgExpandedReject('sustenance-initial-history');
        local facts = self.definition();
        for (local index = 1; index <= facts.length(); index += 1)
            if (facts[index] != self.boundDefinition[index]) rpgExpandedReject('sustenance-initial-binding');
        return nil;
    }
    assess()
    {
        if (self.id == nil || self.id == '' || self.profile == nil || !self.profile.ofKind(RpgExpandedProfile) || self.requirement == nil)
            rpgExpandedReject('sustenance-initial-definition');
        local value = new RpgExpandedResult();
        if (self.completedAt != nil) { self.validateReceipt(); value.status = 'reused'; return value; }
        if (self.boundDefinition != nil) rpgExpandedReject('sustenance-initial-uncommitted-state');
        if (!self.approved || self.evidence == nil || self.evidence == '')
        { value.reason = 'sustenance-initial-author-facts'; return value; }
        if (self.profile.dead) { value.reason = 'sustenance-dead'; return value; }
        self.profile.sustenancePeriod(self.requirement);
        foreach (local prior in self.profile.sustenanceInitialAccess)
        {
            prior.validateReceipt();
            if (prior.id == self.id || prior.requirement == self.requirement) rpgExpandedReject('sustenance-initial-duplicate');
        }
        foreach (local episode in self.profile.sustenanceDeprivations)
            if (episode.requirement == self.requirement) rpgExpandedReject('sustenance-initial-existing-history');
        foreach (local deadline in self.profile.sustenanceDeadlines)
            if (deadline.source.requirement == self.requirement) rpgExpandedReject('sustenance-initial-existing-history');
        value.status = 'ready'; return value;
    }
    record()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        self.completedAt = rpgLedger.seconds; self.boundDefinition = self.definition();
        self.profile.sustenanceInitialAccess = self.profile.sustenanceInitialAccess + [self]; value.status = 'resolved'; return value;
    }
;

modify RpgExpandedProfile
    continuousSustenanceAccess = []
;
/** Continuous object/environment access is an authored world fact, not a periodic dose. */
class RpgExpandedContinuousSustenanceAccess: object
    id = nil
    profile = nil
    requirement = nil
    episode = nil
    approved = nil
    evidence = nil
    boundaryOrder = nil
    completedAt = nil
    boundDefinition = nil
    endedAt = nil
    lostEpisode = nil
    boundLoss = nil
    definition()
    {
        return [self.id,self.profile,self.requirement,self.episode,self.approved,self.evidence,self.boundaryOrder,
            self.completedAt,self.requirement.scope] + self.requirement.templatePurchaseOptions();
    }
    validateReceipt()
    {
        if (self.completedAt == nil || self.boundDefinition == nil || !holds(self.profile.continuousSustenanceAccess,self))
            rpgExpandedReject('sustenance-continuous-history');
        local facts = self.definition();
        for (local index = 1; index <= facts.length(); index += 1)
            if (facts[index] != self.boundDefinition[index]) rpgExpandedReject('sustenance-continuous-binding');
        if (self.episode != nil && self.episode.restoration != self) rpgExpandedReject('sustenance-continuous-restoration');
        if (self.endedAt != nil)
        {
            if (self.boundLoss == nil || self.endedAt != self.boundLoss[1] || self.lostEpisode != self.boundLoss[2]
                || self.lostEpisode == nil || self.lostEpisode.startedAt != self.endedAt
                || self.lostEpisode.profile != self.profile || self.lostEpisode.requirement != self.requirement
                || self.endedAt < self.completedAt || self.endedAt > rpgLedger.seconds)
                rpgExpandedReject('sustenance-continuous-loss-binding');
        }
        else if (self.lostEpisode != nil || self.boundLoss != nil) rpgExpandedReject('sustenance-continuous-loss-state');
        return nil;
    }
    assess()
    {
        if (self.id == nil || self.id == '' || self.profile == nil || !self.profile.ofKind(RpgExpandedProfile) || self.requirement == nil)
            rpgExpandedReject('sustenance-continuous-definition');
        local value = new RpgExpandedResult();
        if (self.completedAt != nil) { self.validateReceipt(); value.status = 'reused'; return value; }
        if (self.boundDefinition != nil || self.endedAt != nil || self.lostEpisode != nil || self.boundLoss != nil)
            rpgExpandedReject('sustenance-continuous-uncommitted-state');
        self.profile.validateContinuousSustenance(self.requirement);
        if (self.profile.dead) { value.reason = 'sustenance-dead'; return value; }
        if (!self.approved || self.evidence == nil || self.evidence == '')
        { value.reason = 'sustenance-continuous-world-facts'; return value; }
        if (!holds(['access-first','injury-first'],self.boundaryOrder)) rpgExpandedReject('sustenance-contact-boundary-ruling');
        foreach (local prior in self.profile.continuousSustenanceAccess)
        {
            prior.validateReceipt();
            if (prior.id == self.id || prior.requirement == self.requirement && prior.endedAt == nil)
                rpgExpandedReject('sustenance-continuous-duplicate');
        }
        local pending = nil;
        foreach (local prior in self.profile.sustenanceDeprivations)
        {
            prior.validateReceipt();
            if (prior.requirement == self.requirement && prior.restoration == nil)
            {
                if (pending != nil) rpgExpandedReject('sustenance-continuous-multiple-deprivations');
                pending = prior;
            }
        }
        if (pending != self.episode) rpgExpandedReject('sustenance-continuous-episode');
        if (self.episode != nil)
        {
            if (self.episode.profile != self.profile || self.episode.requirement != self.requirement)
                rpgExpandedReject('sustenance-continuous-episode');
            if (self.episode.nextTickAt() < rpgLedger.seconds
                || self.boundaryOrder == 'injury-first' && self.episode.nextTickAt() == rpgLedger.seconds)
            { value.reason = 'sustenance-contact-injury-due'; return value; }
        }
        value.status = 'ready'; return value;
    }
    begin()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        self.completedAt = rpgLedger.seconds; self.boundDefinition = self.definition();
        self.profile.continuousSustenanceAccess = self.profile.continuousSustenanceAccess + [self];
        if (self.episode != nil) self.episode.restoration = self;
        value.status = 'resolved'; return value;
    }
    assessLoss(episode)
    {
        self.validateReceipt(); local value = new RpgExpandedResult();
        if (self.endedAt != nil)
        {
            if (episode != self.lostEpisode) rpgExpandedReject('sustenance-continuous-loss-replacement');
            episode.validateReceipt(); value.status = 'reused'; return value;
        }
        if (episode == nil || !episode.ofKind(RpgExpandedSustenanceDeprivation) || episode.startedAt != nil
            || episode.profile != self.profile || episode.requirement != self.requirement)
            rpgExpandedReject('sustenance-continuous-loss-episode');
        return episode.assess();
    }
    lose(episode)
    {
        local value = self.assessLoss(episode); if (value.status != 'ready') return value;
        episode.begin(); self.endedAt = rpgLedger.seconds; self.lostEpisode = episode; self.boundLoss = [self.endedAt,self.lostEpisode];
        value.status = 'resolved'; return value;
    }
;


modify RpgExpandedProfile
    recordContinuousSustenanceLoss(episode)
    {
        foreach (local access in self.continuousSustenanceAccess)
            if (access.requirement == episode.requirement && access.endedAt == nil)
            {
                access.validateReceipt(); access.endedAt = episode.startedAt;
                access.lostEpisode = episode; access.boundLoss = [access.endedAt,episode];
            }
        return nil;
    }
;

class RpgExpandedSustenanceAgingPlan: RpgExpandedResult
    oldAgeMonths = 0
    newAgeMonths = 0
    boundaryAgeMonths = []
    addedYears = 2
;
/** B130 two years per injury point; B444/B53/B154 existing aging schedule.
 * This assessment deliberately does not exempt ordinarily ageless characters. */
rpgExpandedSustenanceAgingPlan(profile,oldAgeMonths)
{
    if (profile == nil || !profile.ofKind(RpgExpandedProfile)) rpgExpandedReject('sustenance-aging-profile');
    rpgInteger(oldAgeMonths,0,11999976);
    local value = new RpgExpandedSustenanceAgingPlan(); value.oldAgeMonths = oldAgeMonths; value.newAgeMonths = oldAgeMonths + 24;
    local schedule = rpgExpandedAgingSchedule(profile.level('short-lifespan'),profile.level('extended-lifespan'));
    if (schedule.status != 'ready') { value.reason = schedule.reason; return value; }
    for (local month = oldAgeMonths + 1; month <= value.newAgeMonths; month += 1)
    {
        local band = nil;
        foreach (local candidate in schedule.bands) if (month >= candidate[1] * 12) band = candidate;
        if (band == nil) continue;
        if (band[2] == 'day')
        {
            value.reason = 'sustenance-aging-day-calendar-required'; value.boundaryAgeMonths = []; return value;
        }
        local interval = band[2] == 'year' ? band[3] * 12 : band[3];
        if ((month - band[1] * 12) % interval == 0) value.boundaryAgeMonths = value.boundaryAgeMonths + [month];
    }
    value.status = 'ready'; return value;
}

modify RpgExpandedProfile
    sustenanceAgingAdvances = []
;
/** Two years caused by exactly one owned deprivation wound, not a second age counter. */
class RpgExpandedSustenanceAgingAdvance: object
    id = nil
    tick = nil
    oldAgeMonths = nil
    calendarId = nil
    calendar = nil
    approved = nil
    evidence = nil
    medicalTL = 3
    recordedAt = nil
    era = nil
    plan = nil
    boundPlan = nil
    boundaries = []
    boundDefinition = nil
    profile() { return self.tick.episode.profile; }
    definition()
    {
        local facts = [self.id,self.tick,self.oldAgeMonths,self.calendarId,self.calendar,self.approved,self.evidence,self.medicalTL,self.recordedAt,self.era];
        return self.calendar == nil ? facts : facts + self.calendar.definition();
    }
    assessPlan()
    {
        if (self.calendar == nil) return rpgExpandedSustenanceAgingPlan(self.profile(),self.oldAgeMonths);
        if (!self.calendar.ofKind(RpgExpandedSustenanceAgingCalendar) || self.calendar.calendarId != self.calendarId)
            rpgExpandedReject('sustenance-aging-calendar-identity');
        return rpgExpandedSustenanceCalendarAgingPlan(self.profile(),self.oldAgeMonths,self.calendar);
    }
    planFacts()
    {
        return [self.plan.oldAgeMonths,self.plan.newAgeMonths,self.plan.addedYears,self.plan.oldAgeCalendarDay,self.plan.newAgeCalendarDay,self.plan.boundaryAgeMonths.length()]
            + self.plan.boundaryAgeMonths + [self.plan.boundaryCalendarDays.length()] + self.plan.boundaryCalendarDays;
    }
    validateBinding()
    {
        if (self.recordedAt == nil || self.boundDefinition == nil || self.tick.agingAdvance != self
            || self.tick.recordedAt != self.recordedAt || !holds(self.profile().sustenanceAgingAdvances,self))
            rpgExpandedReject('sustenance-aging-history');
        local facts = self.definition();
        for (local index = 1; index <= facts.length(); index += 1)
            if (facts[index] != self.boundDefinition[index]) rpgExpandedReject('sustenance-aging-binding');
        local planFacts = self.planFacts();
        if (self.boundPlan == nil || planFacts.length() != self.boundPlan.length()) rpgExpandedReject('sustenance-aging-plan-binding');
        for (local index = 1; index <= planFacts.length(); index += 1)
            if (planFacts[index] != self.boundPlan[index]) rpgExpandedReject('sustenance-aging-plan-binding');
        return nil;
    }
    validateReceipt()
    {
        self.validateBinding(); local index = 0;
        foreach (local boundary in self.boundaries)
        {
            index += 1;
            if (boundary.advance != self || boundary.boundaryIndex != index || boundary.result == nil)
                rpgExpandedReject('sustenance-aging-boundary-history');
            boundary.assess();
        }
        return nil;
    }
    assess()
    {
        if (self.id == nil || self.id == '' || self.tick == nil || !self.tick.ofKind(RpgExpandedSustenanceInjury)
            || self.tick.episode == nil || self.calendarId == nil || self.calendarId == '') rpgExpandedReject('sustenance-aging-definition');
        local value = new RpgExpandedResult();
        if (self.recordedAt != nil) { self.validateReceipt(); value.status = 'reused'; return value; }
        if (self.boundDefinition != nil || self.plan != nil || self.boundPlan != nil || self.era != nil || self.boundaries.length() != 0)
            rpgExpandedReject('sustenance-aging-uncommitted-state');
        if (!self.approved || self.evidence == nil || self.evidence == '')
        { value.reason = 'sustenance-aging-author-age'; return value; }
        local profile = self.profile(); rpgInteger(self.medicalTL,0,1000);
        local plan = self.assessPlan(); if (plan.status != 'ready') return plan;
        foreach (local prior in profile.sustenanceAgingAdvances)
        {
            prior.validateReceipt();
            if (prior.id == self.id || prior.tick == self.tick || prior.calendarId != self.calendarId)
                rpgExpandedReject('sustenance-aging-duplicate');
            if (prior.era == profile.rejuvenations.length() && prior.oldAgeMonths + 24 > self.oldAgeMonths)
                rpgExpandedReject('sustenance-aging-age-overlap');
            if (prior.era == profile.rejuvenations.length() && prior.oldAgeMonths + 24 == self.oldAgeMonths
                && prior.plan.newAgeCalendarDay != nil && (plan.oldAgeCalendarDay == nil || plan.oldAgeCalendarDay < prior.plan.newAgeCalendarDay))
                rpgExpandedReject('sustenance-aging-day-overlap');
            if (!profile.dead && prior.boundaries.length() != prior.plan.boundaryAgeMonths.length())
                rpgExpandedReject('sustenance-aging-unsettled');
        }
        foreach (local prior in profile.agingHistory)
            if (prior.calendarId != self.calendarId || prior.era == profile.rejuvenations.length() && prior.ageYears * 12 > self.oldAgeMonths)
                rpgExpandedReject('sustenance-aging-calendar-history');
        local preflight = rpgExpandedSustenanceAgingPreflight(profile,plan.boundaryAgeMonths.length(),self.medicalTL);
        if (preflight.status != 'ready') return preflight;
        value.status = 'ready'; return value;
    }
    commit()
    {
        if (self.recordedAt != nil) { self.validateReceipt(); return nil; }
        if (self.tick.recordedAt == nil || self.tick.wound == nil || !holds(self.tick.episode.ticks,self.tick))
            rpgExpandedReject('sustenance-aging-injury-required');
        local prepared = self.assess(); if (prepared.status != 'ready') rpgExpandedReject('sustenance-aging-assessment-changed');
        self.plan = self.assessPlan();
        if (self.plan.status != 'ready') rpgExpandedReject('sustenance-aging-plan-changed');
        self.boundPlan = self.planFacts();
        self.recordedAt = self.tick.recordedAt; self.era = self.profile().rejuvenations.length(); self.boundDefinition = self.definition();
        local profile = self.profile(); profile.sustenanceAgingAdvances = profile.sustenanceAgingAdvances + [self]; return nil;
    }
    applyNextBoundary()
    {
        self.validateReceipt(); local value = new RpgExpandedResult(); local profile = self.profile();
        if (profile.dead || self.boundaries.length() == self.plan.boundaryAgeMonths.length()) { value.status = 'complete'; return value; }
        local index = self.boundaries.length() + 1; local event = new RpgExpandedSustenanceAgingBoundary();
        event.advance = self; event.boundaryIndex = index; event.profile = profile; event.calendarId = self.calendarId;
        local identity = new RpgExpandedSustenanceAgingBoundaryIdentity(); identity.advance = self; identity.index = index;
        event.boundaryId = identity;
        event.ageYears = self.plan.boundaryAgeMonths[index] / 12; event.ordinal = profile.agingHistory.length() + 1;
        event.reached = true; event.evidence = self.evidence; event.medicalTL = self.medicalTL;
        value = event.apply(); if (value.status == 'resolved') self.boundaries = self.boundaries + [event]; return value;
    }
;
class RpgExpandedSustenanceAgingBoundary: RpgExpandedAgingEvent
    advance = nil
    boundaryIndex = nil
    exemptFromAging() { return nil; }
    assess()
    {
        if (self.advance == nil || !self.advance.ofKind(RpgExpandedSustenanceAgingAdvance)) rpgExpandedReject('sustenance-aging-boundary-cause');
        self.advance.validateBinding();
        if (self.boundaryId == nil || !self.boundaryId.ofKind(RpgExpandedSustenanceAgingBoundaryIdentity)
            || self.boundaryId.advance != self.advance || self.boundaryId.index != self.boundaryIndex)
            rpgExpandedReject('sustenance-aging-boundary-identity');
        rpgInteger(self.boundaryIndex,1,self.advance.plan.boundaryAgeMonths.length());
        if (self.profile != self.advance.profile() || self.calendarId != self.advance.calendarId
            || self.ageYears != self.advance.plan.boundaryAgeMonths[self.boundaryIndex] / 12 || self.medicalTL != self.advance.medicalTL)
            rpgExpandedReject('sustenance-aging-boundary-definition');
        if (self.result == nil && self.boundaryIndex != self.advance.boundaries.length() + 1)
            rpgExpandedReject('sustenance-aging-boundary-order');
        if (self.result != nil && !holds(self.advance.boundaries,self)) rpgExpandedReject('sustenance-aging-boundary-history');
        return inherited();
    }
;
modify rpgLedger
    validateAdvance(seconds)
    {
        inherited(seconds);
        for (local advance = firstObj(RpgExpandedSustenanceAgingAdvance); advance != nil; advance = nextObj(advance,RpgExpandedSustenanceAgingAdvance))
            if (advance.recordedAt != nil)
            {
                advance.validateReceipt();
                if (seconds > 0 && !advance.profile().dead && advance.boundaries.length() < advance.plan.boundaryAgeMonths.length())
                    rpgExpandedReject('sustenance-aging-unsettled');
            }
        return nil;
    }
;


/** Preflight every boundary using lowest still-living scores, without touching the owner. */
rpgExpandedSustenanceAgingPreflight(profile,count,medicalTL)
{
    rpgInteger(count,0,10000); rpgInteger(medicalTL,0,1000);
    local value = new RpgExpandedResult(); local probe = new RpgExpandedAgingEvent(); probe.profile = profile;
    local fitness = probe.fitnessModifier(); local longevity = profile.level('longevity') > 0; local maximumLoss = longevity ? 1 : 2;
    local scratch = new RpgExpandedProfile();
    scratch.hpAdjustment = profile.hpAdjustment; scratch.fpAdjustment = profile.fpAdjustment;
    scratch.willAdjustment = profile.willAdjustment; scratch.perceptionAdjustment = profile.perceptionAdjustment;
    scratch.speedQuarterAdjustment = profile.speedQuarterAdjustment; scratch.moveAdjustment = profile.moveAdjustment;
    for (local index = 0; index < count; index += 1)
    {
        scratch.st = profile.st - maximumLoss * index; if (scratch.st < 1) scratch.st = 1;
        scratch.dx = profile.dx - maximumLoss * index; if (scratch.dx < 1) scratch.dx = 1;
        scratch.iq = profile.iq - maximumLoss * index; if (scratch.iq < 1) scratch.iq = 1;
        scratch.ht = profile.ht - maximumLoss * index; if (scratch.ht < 1) scratch.ht = 1;
        local worst = rpgExpandedAgingSequence(scratch,medicalTL,fitness,longevity,[18,18,18,18]);
        if (worst.status != 'ready') { value.reason = worst.reason; return value; }
        if (scratch.hpAdjustment < 0 && worst.healthCapacity <= 0
            || scratch.fpAdjustment < 0 && worst.fatigueCapacity <= 0
            || scratch.willAdjustment < 0 && worst.will <= 0
            || scratch.perceptionAdjustment < 0 && worst.perception <= 0
            || worst.speedQuarters < 0 || worst.move < 0)
        { value.reason = 'aging-derived-state-unavailable'; return value; }
    }
    value.status = 'ready'; return value;
}

/** Explicit campaign calendar map for one two-year span; no fixed month length. */
class RpgExpandedSustenanceAgingCalendar: object
    calendarId = nil
    approved = nil
    evidence = nil
    months = []
    dayBandOrigins = []
    startDay = nil
    endDay = nil
    firstDay() { return self.startDay == nil ? self.months[1][2] : self.startDay; }
    lastDay() { return self.endDay == nil ? self.months[25][2] : self.endDay; }
    definition()
    {
        local facts = [self.calendarId,self.approved,self.evidence,self.startDay,self.endDay,self.months.length(),self.dayBandOrigins.length()];
        foreach (local row in self.months) facts = facts + row;
        foreach (local row in self.dayBandOrigins) facts = facts + row;
        return facts;
    }
    validate(oldAgeMonths)
    {
        if (self.calendarId == nil || self.calendarId == '' || !self.approved || self.evidence == nil || self.evidence == ''
            || (self.startDay == nil) != (self.endDay == nil)
            || self.months.length() != (self.startDay == nil ? 25 : 26)) rpgExpandedReject('sustenance-aging-calendar-definition');
        local index = 0; local prior = nil;
        foreach (local row in self.months)
        {
            if (row.length() != 2 || row[1] != oldAgeMonths + index) rpgExpandedReject('sustenance-aging-calendar-month-order');
            rpgInteger(row[2],0,2147483646);
            if (prior != nil && row[2] <= prior) rpgExpandedReject('sustenance-aging-calendar-day-order');
            prior = row[2]; index += 1;
        }
        if (self.startDay != nil)
        {
            rpgInteger(self.startDay,self.months[1][2],self.months[2][2] - 1);
            rpgInteger(self.endDay,self.months[25][2],self.months[26][2] - 1);
        }
        rpgInteger(self.lastDay() - self.firstDay(),1,10000);
        local ages = [];
        foreach (local row in self.dayBandOrigins)
        {
            if (row.length() != 2 || holds(ages,row[1])) rpgExpandedReject('sustenance-aging-calendar-origin');
            rpgInteger(row[1],0,1000000); rpgInteger(row[2],0,2147483646); ages = ages + [row[1]];
            foreach (local month in self.months)
                if (month[1] == row[1] * 12 && month[2] != row[2]) rpgExpandedReject('sustenance-aging-calendar-origin-date');
        }
        return nil;
    }
    originDay(ageYears)
    {
        foreach (local row in self.dayBandOrigins) if (row[1] == ageYears) return row[2];
        rpgExpandedReject('sustenance-aging-calendar-origin-required');
    }
;
modify RpgExpandedSustenanceAgingPlan
    boundaryCalendarDays = []
    oldAgeCalendarDay = nil
    newAgeCalendarDay = nil
;
rpgExpandedSustenanceCalendarAgingPlan(profile,oldAgeMonths,calendar)
{
    if (profile == nil || !profile.ofKind(RpgExpandedProfile)) rpgExpandedReject('sustenance-aging-profile');
    if (calendar == nil || !calendar.ofKind(RpgExpandedSustenanceAgingCalendar)) rpgExpandedReject('sustenance-aging-calendar-required');
    rpgInteger(oldAgeMonths,0,11999976); calendar.validate(oldAgeMonths);
    local value = new RpgExpandedSustenanceAgingPlan(); value.oldAgeMonths = oldAgeMonths; value.newAgeMonths = oldAgeMonths + 24;
    local schedule = rpgExpandedAgingSchedule(profile.level('short-lifespan'),profile.level('extended-lifespan'));
    if (schedule.status != 'ready') { value.reason = schedule.reason; return value; }
    value.oldAgeCalendarDay = calendar.firstDay(); value.newAgeCalendarDay = calendar.lastDay();
    local monthIndex = 1;
    for (local day = calendar.firstDay() + 1; day <= calendar.lastDay(); day += 1)
    {
        while (monthIndex < 25 && calendar.months[monthIndex + 1][2] <= day) monthIndex += 1;
        local month = calendar.months[monthIndex]; local band = nil;
        foreach (local candidate in schedule.bands) if (month[1] >= candidate[1] * 12) band = candidate;
        if (band == nil) continue;
        local due = nil;
        if (band[2] == 'day')
        {
            local origin = calendar.originDay(band[1]);
            if (origin > day) rpgExpandedReject('sustenance-aging-calendar-origin-future');
            due = (day - origin) % band[3] == 0;
        }
        else
        {
            local interval = band[2] == 'year' ? band[3] * 12 : band[3];
            due = day == month[2] && (month[1] - band[1] * 12) % interval == 0;
        }
        if (due)
        {
            value.boundaryAgeMonths = value.boundaryAgeMonths + [month[1]];
            value.boundaryCalendarDays = value.boundaryCalendarDays + [day];
        }
    }
    value.status = 'ready'; return value;
}
class RpgExpandedSustenanceAgingBoundaryIdentity: object
    advance = nil
    index = nil
;

modify RpgExpandedSustenanceAgingBoundary
    ageCalendarDay()
    {
        self.advance.validateBinding();
        if (self.advance.plan.boundaryCalendarDays.length() == 0) return nil;
        return self.advance.plan.boundaryCalendarDays[self.boundaryIndex];
    }
;
/** B444 restoration using exact authored age dates and the existing loss ledger. */
class RpgExpandedDatedRejuvenation: RpgExpandedRejuvenation
    oldAgeCalendarDay = nil
    newAgeCalendarDay = nil
    extraDefinition() { return [self.oldAgeCalendarDay,self.newAgeCalendarDay]; }
    validateAgeRange()
    {
        rpgInteger(self.oldAgeYears,0,1000000); rpgInteger(self.newAgeYears,0,self.oldAgeYears);
        rpgInteger(self.oldAgeCalendarDay,1,2147483646); rpgInteger(self.newAgeCalendarDay,0,self.oldAgeCalendarDay - 1);
    }
    entryPosition(entry)
    {
        local day = entry.ageCalendarDay();
        if (day == nil)
        {
            if (entry.ageYears > self.oldAgeYears) return 'future';
            if (entry.ageYears == self.oldAgeYears || entry.ageYears == self.newAgeYears) return 'ambiguous';
            return entry.ageYears > self.newAgeYears ? 'restore' : 'keep';
        }
        if (day > self.oldAgeCalendarDay) return 'future';
        return day > self.newAgeCalendarDay ? 'restore' : 'keep';
    }
;

/** Published outcome only, full-2008 B144/B436. Journey persistence, vomiting
 * and action penalties must be committed by the owning journey procedure. */
class RpgExpandedSeasicknessResult: RpgExpandedResult
    checkRequired = nil
    vomits = nil
    penalty = 0
    score = nil
;
/** Ordinary passengers check on their first day on qualifying vessels. Trait
 * susceptibility instead checks daily aboard any moving vehicle, including
 * stabilized vessels. day is one-based elapsed journey day, supplied by author. */
rpgExpandedSeasickness(health,susceptible,movingVehicle,seagoing,stabilized,day,roll)
{
    rpgInteger(health,1,1000); rpgInteger(day,1,1000000);
    local value = new RpgExpandedSeasicknessResult();
    value.checkRequired = movingVehicle && (susceptible || (seagoing && !stabilized && day == 1));
    if (!value.checkRequired) { value.status = 'ready'; return value; }
    rpgInteger(roll,3,18);
    value.score = health + (susceptible ? 0 : 5);
    if (value.score > 1000) rpgExpandedReject('seasickness-score-limit');
    if (value.score < 3) { value.reason = 'seasickness-score-unavailable'; return value; }
    value.check = rpgCheck(value.score,roll);
    if (!value.check.achieved) { value.vomits = true; value.penalty = -5; }
    else if (susceptible || (value.check.critical != 'success' && value.check.margin < 5))
        value.penalty = -2;
    value.status = 'ready'; return value;
}

modify RpgExpandedProfile
    motionJourneys = []
;
/** One continuous authored journey. Daily boundaries are elapsed 24-hour periods. */
class RpgExpandedMotionJourney: object
    id = nil
    profile = nil
    movingVehicle = true
    seagoing = nil
    stabilized = nil
    approved = nil
    evidence = nil
    startedAt = nil
    endedAt = nil
    endEvidence = nil
    boundEndEvidence = nil
    boundDefinition = nil
    days = []
    currentPenalty = 0
    nextCheckAt = nil
    definition()
    { return [self.id,self.profile,self.movingVehicle,self.seagoing,self.stabilized,self.approved,self.evidence]; }
    validateReceipt()
    {
        if (self.startedAt == nil || self.boundDefinition == nil || !holds(self.profile.motionJourneys,self))
            rpgExpandedReject('motion-journey-history');
        local facts = self.definition();
        for (local i = 1; i <= facts.length(); i += 1)
            if (facts[i] != self.boundDefinition[i]) rpgExpandedReject('motion-journey-binding');
        if (self.days.length() == 0) rpgExpandedReject('motion-journey-day-history');
        local last = self.days[self.days.length()];
        if (last == nil || !last.ofKind(RpgExpandedMotionDay) || last.journey != self
            || last.result == nil || last.result.penalty != last.boundPenalty
            || self.currentPenalty != (self.endedAt == nil ? last.boundPenalty : 0))
            rpgExpandedReject('motion-journey-penalty-binding');
        if (self.endedAt != nil && self.endEvidence != self.boundEndEvidence)
            rpgExpandedReject('motion-journey-end-binding');
        return nil;
    }
    end()
    {
        self.validateReceipt(); local value = new RpgExpandedResult();
        if (self.endedAt != nil) { value.status = 'reused'; return value; }
        if (self.endEvidence == nil || self.endEvidence == '') { value.reason = 'motion-journey-end-evidence'; return value; }
        self.endedAt = rpgLedger.seconds; self.boundEndEvidence = self.endEvidence;
        self.currentPenalty = 0; value.status = 'resolved'; return value;
    }
;
class RpgExpandedMotionDayResult: RpgExpandedSeasicknessResult
    context = nil
    retching = nil
;
/** Owns one actual check and its vomiting consequences; preparation is pure. */
class RpgExpandedMotionDay: object
    boundPenalty = nil
    journey = nil
    day = 1
    episode = nil
    result = nil
    boundDefinition = nil
    definition() { return [self.journey,self.day,self.episode]; }
    assess()
    {
        if (self.journey == nil || !self.journey.ofKind(RpgExpandedMotionJourney)) rpgExpandedReject('motion-day-journey');
        local j = self.journey; local value = new RpgExpandedMotionDayResult();
        rpgInteger(self.day,1,1000000);
        if (self.result != nil)
        {
            j.validateReceipt(); local facts = self.definition();
            for (local i = 1; i <= facts.length(); i += 1)
                if (facts[i] != self.boundDefinition[i]) rpgExpandedReject('motion-day-binding');
            if (!holds(j.days,self)) rpgExpandedReject('motion-day-history');
            if (self.result.retching != nil) self.result.retching.assess();
            value.status = 'reused'; return value;
        }
        if (j.id == nil || j.id == '' || j.profile == nil || !j.profile.ofKind(RpgExpandedProfile))
            rpgExpandedReject('motion-journey-definition');
        rpgExpandedValidate(j.profile);
        if (!j.approved || j.evidence == nil || j.evidence == '') { value.reason = 'motion-journey-evidence'; return value; }
        if (j.profile.dead || j.profile.unconscious) { value.reason = 'motion-journey-unavailable'; return value; }
        if (j.startedAt == nil)
        {
            if (self.day != 1 || j.days.length() != 0) rpgExpandedReject('motion-journey-first-day');
            foreach (local prior in j.profile.motionJourneys)
            {
                prior.validateReceipt();
                if (prior.id == j.id) rpgExpandedReject('motion-journey-duplicate');
                if (prior.endedAt == nil) { value.reason = 'motion-journey-overlap'; return value; }
            }
        }
        else
        {
            j.validateReceipt();
            if (j.endedAt != nil) { value.reason = 'motion-journey-ended'; return value; }
            if (self.day != j.days.length() + 1 || rpgLedger.seconds != j.nextCheckAt)
            { value.reason = 'motion-journey-day-not-due'; return value; }
        }
        rpgInteger(rpgLedger.seconds,0,2147397247);
        local susceptible = j.profile.motionSusceptible(true);
        value.checkRequired = j.movingVehicle && (susceptible || (j.seagoing && !j.stabilized && self.day == 1));
        if (value.checkRequired)
        {
            if (self.episode == nil || !self.episode.ofKind(RpgExpandedRetching)
                || self.episode.context == nil || self.episode.context.profile != j.profile)
                rpgExpandedReject('motion-day-retching');
            if (self.episode.assess().status != 'ready') { value.reason = 'motion-day-retching-unavailable'; return value; }
            value.context = new RpgLiteContext(); value.context.attribute = rpgHT;
            value.context.kind = 'motion-sickness'; value.context.modifier = susceptible ? 0 : 5;
            value.score = rpgLiteScore(j.profile,value.context);
            if (value.score == nil || value.score < 3) { value.reason = 'seasickness-score-unavailable'; return value; }
        }
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        local j = self.journey;
        if (value.checkRequired)
        {
            value.check = rpgLiteCheck(j.profile,value.context);
            if (!value.check.achieved)
            {
                value.vomits = true; value.penalty = -5;
                if (self.episode.apply().status != 'resolved') rpgExpandedReject('motion-day-retching-changed');
                value.retching = self.episode;
            }
            else if (j.profile.motionSusceptible(true) || (value.check.critical != 'success' && value.check.margin < 5))
                value.penalty = -2;
        }
        else value.penalty = j.currentPenalty;
        if (j.startedAt == nil)
        {
            j.startedAt = rpgLedger.seconds; j.boundDefinition = j.definition();
            j.profile.motionJourneys = j.profile.motionJourneys + [j];
        }
        j.nextCheckAt = rpgLedger.seconds + 86400; j.days = j.days + [self]; j.currentPenalty = value.penalty;
        self.boundDefinition = self.definition(); self.boundPenalty = value.penalty;
        self.result = value; value.status = 'resolved'; return value;
    }
;
modify rpgLedger
    validateAdvance(seconds)
    {
        inherited(seconds);
        for (local j = firstObj(RpgExpandedMotionJourney); j != nil; j = nextObj(j,RpgExpandedMotionJourney))
            if (j.startedAt != nil && j.endedAt == nil && !j.profile.dead)
            {
                j.validateReceipt();
                if (self.seconds + seconds > j.nextCheckAt) rpgExpandedReject('motion-journey-day-boundary');
            }
        return nil;
    }
;


modify RpgExpandedProfile
    activeMotionJourney()
    {
        local active = nil;
        foreach (local journey in self.motionJourneys)
        {
            if (journey == nil || !journey.ofKind(RpgExpandedMotionJourney) || journey.profile != self)
                rpgExpandedReject('motion-journey-profile-history');
            journey.validateReceipt();
            if (journey.endedAt == nil)
            {
                if (active != nil) rpgExpandedReject('motion-journey-overlapping-history');
                active = journey;
            }
        }
        return active;
    }
    healthAttributeModifier(context)
    {
        local value = inherited(context); local journey = self.activeMotionJourney();
        if (journey == nil || context.kind == 'defense') return value;
        local attribute = context.controllingAttribute();
        if (context.skill == nil && !holds([rpgDX,rpgIQ],attribute)) return value;
        local penalty = journey.currentPenalty;
        /* The same vomiting cause already imposes -5 through retching on these
         * attributes. Preserve unrelated condition penalties from inherited(). */
        if (penalty == -5 && self.retchingEpisode != nil && holds([rpgDX,rpgIQ,rpgPerception],attribute))
            foreach (local day in journey.days)
                if (day.result != nil && day.result.retching == self.retchingEpisode) return value;
        return value + penalty;
    }
;


/** B436-B437 explicit complete-air-loss handoff from an unconscious swimmer.
 * World evidence establishes submersion: unconsciousness alone does not prove it. */
class RpgExpandedDrowningExposure: RpgExpandedAirlessExposure
    swimming = nil
    resuscitations = []
    clearedBy = nil
    approved = nil
    boundSwimming = nil
    boundApproval = nil
    assessSubmersion()
    {
        local value = new RpgExpandedResult();
        if (self.startedAt != nil) { self.validateBinding(); value.status = 'reused'; return value; }
        if (self.id == nil || self.id == '' || self.profile == nil || !self.profile.ofKind(RpgExpandedProfile)
            || self.swimming == nil || !self.swimming.ofKind(RpgExpandedSwimmingEncounter)
            || self.swimming.profile != self.profile) rpgExpandedReject('drowning-submersion-definition');
        self.swimming.validateBinding(); self.swimming.validateWillHistory();
        if (!self.approved || self.evidence == nil || self.evidence == '')
        { value.reason = 'drowning-submersion-evidence'; return value; }
        if (self.profile.dead || !self.profile.unconscious || self.profile.swimmingEncounter != self.swimming
            || self.swimming.endedAt != nil || self.swimming.submersion != nil)
        { value.reason = 'drowning-submersion-not-active'; return value; }
        if (self.profile.airlessExposure != nil || self.profile.airClock != 0 || self.profile.breathReserve != nil)
        { value.reason = 'drowning-air-ledger-owned'; return value; }
        foreach (local prior in self.profile.airlessHistory)
            if (prior.id == self.id) rpgExpandedReject('airless-duplicate');
        value.status = 'ready'; return value;
    }
    start()
    {
        local value = self.assessSubmersion(); if (value.status != 'ready') return value;
        self.boundSwimming = self.swimming; self.boundApproval = self.approved;
        self.swimming.submersion = self; self.swimming.endedAt = rpgLedger.seconds;
        self.swimming.exitEvidence = self.evidence; self.profile.swimmingEncounter = nil;
        value = inherited();
        if (value.status != 'resolved') rpgExpandedReject('drowning-air-handoff-changed');
        return value;
    }
    validateSwimmingExit(encounter)
    {
        if (encounter != self.swimming || encounter != self.boundSwimming || encounter.submersion != self
            || self.startedAt == nil || encounter.endedAt != self.startedAt || encounter.exitEvidence != self.boundEvidence
            || self.profile != encounter.profile || !holds(self.profile.airlessHistory,self))
            rpgExpandedReject('drowning-swimming-handoff-binding');
        return nil;
    }
    validateBinding()
    {
        inherited();
        if (self.swimming != self.boundSwimming || self.approved != self.boundApproval)
            rpgExpandedReject('drowning-submersion-binding');
        self.validateSwimmingExit(self.swimming); return nil;
    }
    assessAir(evidence)
    {
        local value = new RpgExpandedAirlessResult();
        self.validateBinding();
        if (self.clearedBy == nil || self.clearedBy.exposure != self || self.clearedBy.result == nil
            || self.clearedBy.result.check == nil || !self.clearedBy.result.check.achieved
            || !holds(self.resuscitations,self.clearedBy))
        { value.reason = 'drowning-resuscitation-required'; return value; }
        self.clearedBy.validateReceipt();
        return inherited(evidence);
    }
;


class RpgExpandedDrowningCareResult: RpgExpandedResult
    context = nil
    recovery = nil
;
/** B425 staged minute of treatment; callers advance the existing airless seconds. */
class RpgExpandedDrowningResuscitation: object
    id = nil
    exposure = nil
    healer = nil
    skill = nil
    modernTechnique = nil
    modifier = 0
    approved = nil
    evidence = nil
    startedAt = nil
    completedAt = nil
    cancelledAt = nil
    cancellationEvidence = nil
    boundCancellation = nil
    boundCancelledAt = nil
    boundStartedAt = nil
    boundSucceeded = nil
    boundDefinition = nil
    result = nil
    definition()
    { return [self.id,self.exposure,self.healer,self.skill,self.modernTechnique,self.modifier,self.approved,self.evidence]; }
    validateReceipt()
    {
        if (self.startedAt == nil || self.startedAt != self.boundStartedAt || self.boundDefinition == nil
            || !holds(self.exposure.resuscitations,self)) rpgExpandedReject('drowning-care-history');
        local facts = self.definition();
        if (facts.length() != self.boundDefinition.length()) rpgExpandedReject('drowning-care-binding');
        for (local i = 1; i <= facts.length(); i += 1)
            if (facts[i] != self.boundDefinition[i]) rpgExpandedReject('drowning-care-binding');
        if (self.cancelledAt == nil && (self.boundCancelledAt != nil || self.cancellationEvidence != nil || self.boundCancellation != nil))
            rpgExpandedReject('drowning-care-cancellation-binding');
        if (self.result == nil && (self.completedAt != nil || self.boundSucceeded != nil))
            rpgExpandedReject('drowning-care-result-binding');
        if (self.cancelledAt != nil)
        {
            if (self.cancelledAt != self.boundCancelledAt || self.cancelledAt < self.startedAt || self.cancelledAt > rpgLedger.seconds
                || self.cancellationEvidence != self.boundCancellation || self.result != nil || self.completedAt != nil)
                rpgExpandedReject('drowning-care-cancellation-binding');
        }
        else if (self.result != nil && (self.completedAt != self.startedAt + 60 || self.completedAt > rpgLedger.seconds
            || self.result.check == nil || self.result.check.achieved != self.boundSucceeded))
            rpgExpandedReject('drowning-care-result-binding');
        return nil;
    }
    cancel(evidence)
    {
        local value = new RpgExpandedResult();
        if (self.startedAt == nil) { value.reason = 'drowning-care-not-started'; return value; }
        self.validateReceipt();
        if (self.cancelledAt != nil) { value.status = 'reused'; return value; }
        if (self.result != nil) { value.reason = 'drowning-care-already-completed'; return value; }
        if (evidence == nil || evidence == '') { value.reason = 'drowning-care-cancellation-evidence'; return value; }
        self.cancelledAt = rpgLedger.seconds; self.boundCancelledAt = self.cancelledAt; self.cancellationEvidence = evidence; self.boundCancellation = evidence;
        value.status = 'resolved'; return value;
    }
    assess()
    {
        local value = new RpgExpandedDrowningCareResult();
        if (self.id == nil || self.id == '' || self.exposure == nil || !self.exposure.ofKind(RpgExpandedDrowningExposure)
            || self.healer == nil || !self.healer.ofKind(RpgLiteProfile) || self.skill == nil || !self.skill.ofKind(RpgLiteSkill)
            || !holds(['first-aid','physician'],self.skill.id) || self.skill.attribute != rpgIQ
            || self.skill.difficulty != (self.skill.id == 'first-aid' ? 0 : 2) || self.skill.techLevel == nil)
            rpgExpandedReject('drowning-care-definition');
        self.exposure.validateBinding();
        if (self.startedAt != nil) self.validateReceipt();
        if (self.cancelledAt != nil) { value.reason = 'drowning-care-cancelled'; return value; }
        if (self.result != nil) { value.status = 'reused'; return value; }
        local patient = self.exposure.profile;
        if (patient.dead || self.exposure.endedAt != nil || patient.airlessExposure != self.exposure)
        { value.reason = 'drowning-care-not-active'; return value; }
        if (!self.approved || self.evidence == nil || self.evidence == '')
        { value.reason = 'drowning-care-access-required'; return value; }
        if (self.healer == patient || self.healer.dead || self.healer.unconscious || self.healer.stunned
            || self.healer.mentalStun || self.healer.mortal || self.healer.fp() <= 0 || self.healer.voluntaryMovementUnavailable())
        { value.reason = 'drowning-care-healer-unavailable'; return value; }
        for (local other = firstObj(RpgExpandedDrowningResuscitation); other != nil; other = nextObj(other,RpgExpandedDrowningResuscitation))
            if (other != self && other.startedAt != nil && other.healer == self.healer)
            {
                other.validateReceipt();
                if (other.cancelledAt == nil && other.result == nil)
                { value.reason = 'drowning-care-healer-busy'; return value; }
            }
        local trained = nil;
        foreach (local training in self.healer.skills) if (training.skill == self.skill && training.points > 0) trained = true;
        local procedure = rpgExpandedResuscitationProcedure(self.skill.id,self.skill.techLevel,trained,self.modernTechnique,'drowning');
        if (procedure.status != 'ready') { value.reason = procedure.reason; return value; }
        rpgInteger(self.modifier,-100,100);
        value.context = new RpgLiteContext(); value.context.skill = self.skill; value.context.kind = 'resuscitation';
        value.context.modifier = procedure.modifier + self.modifier;
        local score = rpgLiteScore(self.healer,value.context);
        if (score == nil || score < 3) { value.reason = 'drowning-care-score-unavailable'; return value; }
        foreach (local prior in self.exposure.resuscitations)
            if (prior != self && (prior.id == self.id || prior.result == nil && prior.cancelledAt == nil))
                rpgExpandedReject('drowning-care-overlap');
        if (self.startedAt == nil && patient.airClock + procedure.seconds >= 240)
        { value.reason = 'drowning-care-insufficient-time'; return value; }
        value.seconds = procedure.seconds; value.status = 'ready'; return value;
    }
    start()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        if (self.startedAt != nil) { value.status = 'reused'; return value; }
        if (rpgLedger.seconds != self.exposure.lastSecondAt)
        { value.status = 'blocked'; value.reason = 'drowning-care-unresolved-air'; return value; }
        rpgInteger(rpgLedger.seconds,0,2147483587);
        self.startedAt = rpgLedger.seconds; self.boundStartedAt = self.startedAt; self.boundDefinition = self.definition();
        self.exposure.resuscitations = self.exposure.resuscitations + [self]; value.status = 'resolved'; return value;
    }
    finish()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        if (self.startedAt == nil || rpgLedger.seconds != self.startedAt + value.seconds)
        { value.status = 'blocked'; value.reason = 'drowning-care-minute-not-complete'; return value; }
        local recovery = self.exposure.assessAirRecovery(self.evidence);
        if (recovery.status != 'ready') { value.status = 'blocked'; value.reason = recovery.reason; return value; }
        value.check = rpgLiteCheck(self.healer,value.context);
        self.completedAt = rpgLedger.seconds; self.boundSucceeded = value.check.achieved; self.result = value;
        if (value.check.achieved)
        {
            self.exposure.clearedBy = self; value.recovery = self.exposure.resumeAir(self.evidence);
            if (value.recovery.status != 'resolved') rpgExpandedReject('drowning-care-recovery-changed');
        }
        value.status = 'resolved'; return value;
    }
;


modify rpgLedger
    validateAdvance(seconds)
    {
        inherited(seconds);
        for (local care = firstObj(RpgExpandedDrowningResuscitation); care != nil; care = nextObj(care,RpgExpandedDrowningResuscitation))
            if (care.startedAt != nil && care.cancelledAt == nil && care.result == nil && !care.exposure.profile.dead)
            {
                care.validateReceipt();
                if (self.seconds + seconds > care.startedAt + 60) rpgExpandedReject('drowning-care-completion-boundary');
            }
        return nil;
    }
;


modify RpgExpandedProfile
    validateFeatures()
    {
        inherited();
        foreach (local exposure in self.airlessHistory)
            if (exposure.ofKind(RpgExpandedDrowningExposure))
            {
                local ids = []; local receipts = []; local active = nil;
                foreach (local care in exposure.resuscitations)
                {
                    if (care == nil || !care.ofKind(RpgExpandedDrowningResuscitation) || care.exposure != exposure
                        || holds(ids,care.id) || holds(receipts,care)) rpgExpandedReject('drowning-care-history');
                    care.validateReceipt(); ids = ids + [care.id]; receipts = receipts + [care];
                    if (care.cancelledAt == nil && care.result == nil)
                    {
                        if (active != nil) rpgExpandedReject('drowning-care-overlap');
                        active = care;
                    }
                }
            }
        for (local care = firstObj(RpgExpandedDrowningResuscitation); care != nil; care = nextObj(care,RpgExpandedDrowningResuscitation))
            if (care.startedAt != nil && (care.healer == self || care.exposure.profile == self)) care.validateReceipt();
        return nil;
    }
;

/** Native action adapter. Authors bind an attempt and expose their own verbs.
 * Dialogue choices call perform(context.asker) to share the same transaction. */
class RpgExpandedDrowningCareAction: Action
    attempt = nil
    operation = 'start'
    cancellationEvidence = nil
    perform(actor)
    {
        if (self.attempt == nil || !self.attempt.ofKind(RpgExpandedDrowningResuscitation)
            || !holds(['start','finish','cancel'],self.operation)) rpgExpandedReject('drowning-care-action-definition');
        local value = new RpgExpandedResult();
        if (actor == nil || !actor.ofKind(Thing) || actor.rpgProfile != self.attempt.healer)
            value.reason = 'drowning-care-acting-healer-required';
        else if (self.operation == 'start') value = self.attempt.start();
        else if (self.operation == 'finish') value = self.attempt.finish();
        else value = self.attempt.cancel(self.cancellationEvidence);
        event('rpg.expanded.drowning-care'); eventValue(self.operation); eventValue(value.status); eventValue(value.reason);
        return value;
    }
    exec(context) { return self.perform(context.actor); }
;
