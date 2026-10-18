/* Include after expanded foundation and expanded health. Partial hazard assessments, full-2008 B444. */

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
