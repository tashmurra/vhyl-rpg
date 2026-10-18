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
            value.check = rpgLiteCheck(self.wound.profile,value.context); value.infected = !value.check.achieved;
            if (self.wound.profile.diseaseResistance(self.diseaseId) == nil)
            {
                local record = new RpgExpandedDiseaseResistance(); record.diseaseId = self.diseaseId;
                record.profile = self.wound.profile; record.firstExposure = self; record.firstRoll = value.check.roll;
                record.immune = rpgExpandedNaturalDiseaseImmunity(value.check.roll);
                value.immune = record.immune;
                self.wound.profile.diseaseResistances = self.wound.profile.diseaseResistances + [record];
            }
        }
        self.boundDiseaseId = self.diseaseId;
        self.boundWound = self.wound; self.boundConditions = self.conditions; self.boundEvidence = self.evidence;
        self.infectedMatter = self.conditions.infectedMatter; self.specialLocale = self.conditions.specialLocale;
        self.antibiotics = self.conditions.antibiotics; self.medicalTL = self.conditions.medicalTL;
        self.criticalTreatmentFailure = self.conditions.criticalTreatmentFailure;
        self.untreatedDirtyWound = self.conditions.untreatedDirtyWound;
        self.acquiredAt = rpgLedger.seconds; self.wound.infectionExposure = self;
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
        local patient = self.exposure.wound.profile;
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
        value.failureWound.id = 'infection-' + self.exposure.wound.id + '-' + self.id;
        value.failureWound.amount = 1; value.failureWound.dropDestination = self.dropDestination;
        local failure = value.failureWound.assess();
        if (failure.status != 'ready') { value.reason = failure.reason; return value; }
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        local patient = self.exposure.wound.profile;
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
                || record.firstExposure.wound.profile != self || record.firstExposure.diseaseId != record.diseaseId
                || !holds(self.expandedWounds,record.firstExposure.wound)
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
        if (self.profile.coldExposure != nil) { value.status = 'blocked'; value.reason = 'cold-exposure-active'; return value; }
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
            if (patient.fp() <= -patient.maxEnergy) { patient.unconscious = true; patient.fatigueCollapse = true; }
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
