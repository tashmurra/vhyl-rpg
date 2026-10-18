/* Include after expanded foundation. Sources: full-2008, B175 and B458-B459. */

/** Complete general-training day table; nil means that level is unattainable. */
rpgExpandedAnimalTrainingDays(intelligence, level)
{
    rpgInteger(intelligence,2,5); rpgInteger(level,2,5);
    local rows = [[60,nil,nil,nil],[30,360,nil,nil],[7,180,360,nil],[2,90,180,720]];
    return rows[intelligence-1][level-1];
}

/** A single approved trick is distinct from acquiring a whole training level. */
rpgExpandedAnimalTrickDays(intelligence)
{
    rpgInteger(intelligence,2,5);
    if (intelligence == 3) return 90;
    if (intelligence == 4) return 30;
    if (intelligence == 5) return 14;
    return nil;
}

rpgExpandedAnimalTaskModifier(familiar, stressful, complexityPenalty)
{
    rpgInteger(complexityPenalty,0,1000);
    if (complexityPenalty != 0 && complexityPenalty < 3) rpgExpandedReject('animal-task-complexity');
    return (familiar ? 0 : -5) + (stressful ? -5 : 0) - complexityPenalty;
}
rpgExpandedAnimalCalmingModifier(wild, frightened, manKiller)
{
    return manKiller ? -10 : wild || frightened ? -5 : 0;
}
rpgExpandedAnimalCombatPenalty(handlingScore)
{
    rpgInteger(handlingScore,-1000,1000);
    return handlingScore >= 20 ? -2 : handlingScore >= 15 ? -1 : 0;
}

class RpgExpandedAnimalTrainingAssessment: RpgExpandedResult
    days = nil
    dailySeconds = 14400
    sessionsPerDay = 2
    sessionSeconds = 7200
;

/** Author-approved training plan; assessment grants no learned behavior or time credit. */
class RpgExpandedAnimalTrainingPlan: object
    animal = nil
    trainer = nil
    skill = nil
    appropriateSpecialty = nil
    approved = nil
    evidence = nil
    kind = 'general'
    level = 2
    trick = nil
    wild = nil
    assess()
    {
        if (self.animal == nil || !self.animal.ofKind(RpgExpandedProfile)
            || self.trainer == nil || !self.trainer.ofKind(RpgExpandedProfile) || self.animal == self.trainer
            || self.skill == nil || !self.skill.ofKind(RpgLiteSkill) || self.skill.id != 'animal-handling')
            rpgExpandedReject('animal-training-definition');
        if (!holds(['general','trick'],self.kind)) rpgExpandedReject('animal-training-kind');
        local value = new RpgExpandedAnimalTrainingAssessment();
        if (!self.approved || !self.appropriateSpecialty || self.evidence == nil || self.evidence == '')
        { value.reason = 'animal-training-author-facts'; return value; }
        local known = nil;
        foreach (local training in self.trainer.skills)
            if (training.skill == self.skill && training.points > 0) known = true;
        if (!known) { value.reason = 'animal-training-specialty-required'; return value; }
        if (self.animal.iq < 2 || self.animal.iq > 5)
        { value.reason = 'animal-training-intelligence-unavailable'; return value; }
        if (self.kind == 'general')
        {
            if (self.trick != nil) rpgExpandedReject('animal-training-unused-trick');
            value.days = rpgExpandedAnimalTrainingDays(self.animal.iq,self.level);
        }
        else
        {
            if (self.trick == nil || self.trick == '') rpgExpandedReject('animal-training-trick');
            value.days = rpgExpandedAnimalTrickDays(self.animal.iq);
        }
        if (value.days == nil) { value.reason = 'animal-training-unattainable'; return value; }
        rpgInteger(self.animal.animalTrainingLevel,0,5);
        if (self.animal.animalTrainingLevel == 1) rpgExpandedReject('animal-training-level');
        if (self.kind == 'general' && self.animal.animalTrainingLevel >= self.level
            || self.kind == 'trick' && holds(self.animal.animalKnownTricks,self.trick))
        { value.reason = 'animal-training-already-known'; return value; }
        value.modifier = self.wild ? -5 : 0; value.status = 'ready'; return value;
    }
;

modify RpgExpandedProfile
    animalHandlingAttempts = []
;
class RpgExpandedAnimalHandlingResult: RpgExpandedResult
    score = nil
    succeeded = nil
    authorResolutionRequired = true
;

/** B175 handling check receipt. The author still controls the animal's behavior. */
class RpgExpandedAnimalHandlingAttempt: object
    id = nil
    animal = nil
    handler = nil
    skill = nil
    appropriateSpecialty = nil
    mode = 'task'
    taskId = nil
    taskDefinition = nil
    trainingEstablished = nil
    familiar = nil
    stressful = nil
    complexityPenalty = 0
    wild = nil
    frightened = nil
    manKiller = nil
    speciesModifier = 0
    performance = nil
    seconds = 0
    approved = nil
    available = nil
    uninterrupted = nil
    evidence = nil
    result = nil
    definitionSnapshot = nil
    definition()
    {
        local value = [self.id,self.animal,self.handler,self.skill,self.appropriateSpecialty,self.mode,self.taskId,
            self.trainingEstablished,self.familiar,self.stressful,self.complexityPenalty,self.wild,self.frightened,
            self.manKiller,self.speciesModifier,self.performance,self.seconds,self.evidence,self.taskDefinition];
        if (self.taskDefinition != nil)
        {
            if (!self.taskDefinition.ofKind(RpgExpandedAnimalTask)) rpgExpandedReject('animal-handling-task-definition');
            value = value + self.taskDefinition.definition();
        }
        return value;
    }
    context()
    {
        local value = new RpgLiteContext(); value.skill = self.skill;
        value.modifier = self.speciesModifier + (self.mode == 'task'
            ? rpgExpandedAnimalTaskModifier(self.familiar,self.stressful,self.complexityPenalty)
            : rpgExpandedAnimalCalmingModifier(self.wild,self.frightened,self.manKiller));
        return value;
    }
    assess()
    {
        if (self.animal == nil || !self.animal.ofKind(RpgExpandedProfile)
            || self.handler == nil || !self.handler.ofKind(RpgExpandedProfile) || self.animal == self.handler
            || self.skill == nil || !self.skill.ofKind(RpgLiteSkill) || self.skill.id != 'animal-handling')
            rpgExpandedReject('animal-handling-definition');
        local value = new RpgExpandedAnimalHandlingResult();
        if (self.result != nil)
        {
            local current = self.definition();
            if (self.definitionSnapshot == nil || current.length() != self.definitionSnapshot.length())
                rpgExpandedReject('animal-handling-binding');
            for (local index = 1; index <= current.length(); index += 1)
                if (current[index] != self.definitionSnapshot[index]) rpgExpandedReject('animal-handling-binding');
            if (!holds(self.animal.animalHandlingAttempts,self)) rpgExpandedReject('animal-handling-history');
            value.status = 'reused'; value.score = self.result.score; value.check = self.result.check;
            value.modifier = self.result.modifier; value.seconds = self.result.seconds; value.succeeded = self.result.succeeded; return value;
        }
        if (self.id == nil || self.id == '' || !holds(['task','calm'],self.mode)) rpgExpandedReject('animal-handling-request');
        rpgInteger(self.seconds,0,86400); rpgInteger(self.speciesModifier,-1000,0);
        if (!self.approved || !self.available || !self.uninterrupted || !self.appropriateSpecialty
            || self.evidence == nil || self.evidence == '')
        { value.reason = 'animal-handling-author-facts'; return value; }
        if (self.performance) { value.reason = 'animal-performance-check-required'; return value; }
        if (self.mode == 'task')
        {
            if (self.taskId == nil || self.taskId == '') rpgExpandedReject('animal-handling-task');
            if (self.taskDefinition != nil)
            {
                if (!self.taskDefinition.ofKind(RpgExpandedAnimalTask) || self.taskDefinition.id != self.taskId)
                    rpgExpandedReject('animal-handling-task-definition');
                local eligibility = self.taskDefinition.assess(self.animal);
                if (eligibility.status != 'ready') { value.reason = eligibility.reason; return value; }
            }
            else if (!self.trainingEstablished) { value.reason = 'animal-handling-training-required'; return value; }
        }
        else if (self.taskId != nil || self.taskDefinition != nil || self.complexityPenalty != 0 || self.stressful || self.trainingEstablished)
            rpgExpandedReject('animal-calming-unused-task-fields');
        foreach (local prior in self.animal.animalHandlingAttempts)
            if (prior.id == self.id) rpgExpandedReject('animal-handling-duplicate');
        foreach (local participant in [self.animal,self.handler])
            if (participant.dead || participant.unconscious || participant.stunned || participant.hp() <= 0 || participant.fp() <= 0)
            { value.reason = 'animal-handling-participant-unavailable'; return value; }
        local context = self.context(); value.score = rpgLiteScore(self.handler,context); value.modifier = context.modifier;
        if (value.score == nil) { value.reason = context.unavailableReason(self.handler); return value; }
        if (value.score < 3) { value.reason = 'too-difficult'; return value; }
        value.seconds = self.seconds; value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        local current = self.definition(); local start = rpgLedger.seconds; rpgSpendTime(value.seconds);
        local changed = self.definition();
        if (changed.length() != current.length()) rpgExpandedReject('animal-handling-definition-changed');
        for (local index = 1; index <= current.length(); index += 1)
            if (current[index] != changed[index]) rpgExpandedReject('animal-handling-definition-changed');
        local refreshed = self.assess();
        if (refreshed.status != 'ready' || rpgLedger.seconds != start + value.seconds)
            rpgExpandedReject('animal-handling-interrupted');
        value.score = refreshed.score; value.check = rpgLiteCheck(self.handler,self.context());
        if (value.check.status != 'resolved') rpgExpandedReject('animal-handling-check-changed');
        value.succeeded = value.check.achieved;
        self.definitionSnapshot = current; self.animal.animalHandlingAttempts = self.animal.animalHandlingAttempts + [self];
        value.status = 'resolved'; self.result = value; return value;
    }
;

modify RpgExpandedAnimalHandlingAttempt
    performanceReceipt = nil
;
class RpgExpandedAnimalPerformanceResult: RpgExpandedAnimalHandlingResult
    handlingCheck = nil
;

/** Separate B175 entertainment check for an already timed handling task. */
class RpgExpandedAnimalPerformance: object
    handling = nil
    skill = nil
    modifier = 0
    approved = nil
    available = nil
    evidence = nil
    result = nil
    definitionSnapshot = nil
    definition() { return [self.handling,self.skill,self.modifier,self.evidence]; }
    context()
    { local value = new RpgLiteContext(); value.skill = self.skill; value.modifier = self.modifier; return value; }
    assess()
    {
        if (self.handling == nil || !self.handling.ofKind(RpgExpandedAnimalHandlingAttempt)
            || self.skill == nil || !self.skill.ofKind(RpgLiteSkill) || self.skill.id != 'performance')
            rpgExpandedReject('animal-performance-definition');
        local value = new RpgExpandedAnimalPerformanceResult();
        if (self.handling.result == nil || self.handling.mode != 'task')
        { value.reason = 'animal-performance-handling-required'; return value; }
        self.handling.assess(); value.handlingCheck = self.handling.result.check;
        if (self.result != nil)
        {
            local current = self.definition();
            if (self.definitionSnapshot == nil || current.length() != self.definitionSnapshot.length())
                rpgExpandedReject('animal-performance-binding');
            for (local index = 1; index <= current.length(); index += 1)
                if (current[index] != self.definitionSnapshot[index]) rpgExpandedReject('animal-performance-binding');
            if (self.handling.performanceReceipt != self) rpgExpandedReject('animal-performance-history');
            value.status = 'reused'; value.check = self.result.check; value.score = self.result.score;
            value.modifier = self.result.modifier; value.succeeded = self.result.succeeded; return value;
        }
        if (self.handling.performanceReceipt != nil) { value.reason = 'animal-performance-already-resolved'; return value; }
        if (!self.approved || !self.available || self.evidence == nil || self.evidence == '')
        { value.reason = 'animal-performance-author-facts'; return value; }
        rpgInteger(self.modifier,-1000,1000);
        local performer = self.handling.handler;
        if (performer.dead || performer.unconscious || performer.stunned || performer.hp() <= 0 || performer.fp() <= 0)
        { value.reason = 'animal-performance-performer-unavailable'; return value; }
        local context = self.context(); value.score = rpgLiteScore(performer,context); value.modifier = self.modifier;
        if (value.score == nil) { value.reason = context.unavailableReason(performer); return value; }
        if (value.score < 3) { value.reason = 'too-difficult'; return value; }
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        value.check = rpgLiteCheck(self.handling.handler,self.context());
        if (value.check.status != 'resolved') rpgExpandedReject('animal-performance-check-changed');
        value.succeeded = value.check.achieved;
        self.handling.performanceReceipt = self; self.definitionSnapshot = self.definition();
        value.status = 'resolved'; self.result = value; return value;
    }
;

modify RpgExpandedAnimalTrainingPlan
    definition()
    {
        return [self.animal,self.trainer,self.skill,self.appropriateSpecialty,self.approved,self.evidence,
            self.kind,self.level,self.trick,self.wild,self.animal.iq];
    }
;
modify RpgExpandedProfile
    animalTrainingSessions = []
    pendingAnimalTrainingCourse = nil
;

/** Owned attendance course; daily checks and learned milestones are separate. */
class RpgExpandedAnimalCourse: object
    plan = nil
    definitionSnapshot = nil
    sessions = []
    requiredDays = nil
    successfulDays = 0
    pendingDay = nil
    assess()
    {
        if (self.plan == nil || !self.plan.ofKind(RpgExpandedAnimalTrainingPlan)) rpgExpandedReject('animal-course-plan');
        if (self.definitionSnapshot != nil)
        {
            local current = self.plan.definition();
            if (current.length() != self.definitionSnapshot.length()) rpgExpandedReject('animal-course-binding');
            for (local index = 1; index <= current.length(); index += 1)
                if (current[index] != self.definitionSnapshot[index]) rpgExpandedReject('animal-course-binding');
        }
        return self.plan.assess();
    }
;
class RpgExpandedAnimalSessionResult: RpgExpandedResult
    day = nil
    attendance = 0
    dailyCheckRequired = nil
;

/** One of the two source-prescribed two-hour sessions; attendance is not learning. */
class RpgExpandedAnimalTrainingSession: object
    id = nil
    course = nil
    approved = nil
    uninterrupted = nil
    evidence = nil
    result = nil
    definitionSnapshot = nil
    startedAt = nil
    endedAt = nil
    definition() { return [self.id,self.course,self.evidence]; }
    assess()
    {
        if (self.course == nil || !self.course.ofKind(RpgExpandedAnimalCourse)) rpgExpandedReject('animal-session-course');
        local quote = self.course.assess(); local value = new RpgExpandedAnimalSessionResult();
        if (self.result != nil)
        {
            local current = self.definition();
            if (self.definitionSnapshot == nil || current.length() != self.definitionSnapshot.length())
                rpgExpandedReject('animal-session-binding');
            for (local index = 1; index <= current.length(); index += 1)
                if (current[index] != self.definitionSnapshot[index]) rpgExpandedReject('animal-session-binding');
            if (!holds(self.course.sessions,self) || !holds(self.course.plan.animal.animalTrainingSessions,self))
                rpgExpandedReject('animal-session-history');
            value.status = 'reused'; value.seconds = self.result.seconds; value.day = self.result.day;
            value.attendance = self.result.attendance; value.dailyCheckRequired = self.result.dailyCheckRequired; return value;
        }
        if (quote.status != 'ready') { value.reason = quote.reason; return value; }
        if (self.id == nil || self.id == '') rpgExpandedReject('animal-session-id');
        if (!self.approved || !self.uninterrupted || self.evidence == nil || self.evidence == '')
        { value.reason = 'animal-session-author-facts'; return value; }
        local animal = self.course.plan.animal;
        if (self.course.requiredDays != nil && self.course.successfulDays >= self.course.requiredDays)
        { value.reason = 'animal-training-milestone-required'; return value; }
        if (self.course.pendingDay != nil || animal.pendingAnimalTrainingCourse != nil)
        { value.reason = 'animal-training-daily-check-required'; return value; }
        foreach (local participant in [animal,self.course.plan.trainer])
            if (participant.dead || participant.unconscious || participant.stunned || participant.hp() <= 0 || participant.fp() <= 0)
            { value.reason = 'animal-training-participant-unavailable'; return value; }
        value.day = rpgLedger.seconds / 86400; value.seconds = quote.sessionSeconds;
        rpgInteger(rpgLedger.seconds,0,2147483647-value.seconds);
        if ((rpgLedger.seconds + value.seconds - 1) / 86400 != value.day)
        { value.reason = 'animal-training-session-crosses-day'; return value; }
        foreach (local prior in animal.animalTrainingSessions)
        {
            if (prior == nil || !prior.ofKind(RpgExpandedAnimalTrainingSession) || prior.result == nil)
                rpgExpandedReject('animal-session-history');
            prior.assess();
            if (prior.course == self.course && prior.id == self.id) rpgExpandedReject('animal-session-duplicate');
            if (prior.result.day == value.day)
            {
                if (prior.course != self.course) { value.reason = 'animal-training-other-course-today'; return value; }
                value.attendance += 1;
            }
        }
        if (value.attendance >= 2) { value.reason = 'animal-training-day-full'; return value; }
        value.attendance += 1; value.dailyCheckRequired = value.attendance == 2;
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        local current = self.definition(); local plan = self.course.plan.definition(); local start = rpgLedger.seconds;
        local courseCount = self.course.sessions.length(); local animalCount = self.course.plan.animal.animalTrainingSessions.length();
        rpgSpendTime(value.seconds);
        local changed = self.definition(); local changedPlan = self.course.plan.definition();
        if (changed.length() != current.length() || changedPlan.length() != plan.length())
            rpgExpandedReject('animal-session-definition-changed');
        for (local index = 1; index <= current.length(); index += 1)
            if (current[index] != changed[index]) rpgExpandedReject('animal-session-definition-changed');
        for (local index = 1; index <= plan.length(); index += 1)
            if (plan[index] != changedPlan[index]) rpgExpandedReject('animal-session-definition-changed');
        // Revalidate live participants without assessing a new session at the ending clock.
        local quote = self.course.assess();
        if (quote.status != 'ready' || !self.approved || !self.uninterrupted
            || rpgLedger.seconds != start + value.seconds || self.course.pendingDay != nil
            || self.course.plan.animal.pendingAnimalTrainingCourse != nil
            || self.course.sessions.length() != courseCount || self.course.plan.animal.animalTrainingSessions.length() != animalCount)
            rpgExpandedReject('animal-session-interrupted');
        foreach (local participant in [self.course.plan.animal,self.course.plan.trainer])
            if (participant.dead || participant.unconscious || participant.stunned || participant.hp() <= 0 || participant.fp() <= 0)
                rpgExpandedReject('animal-session-interrupted');
        if (self.course.definitionSnapshot == nil)
        { self.course.definitionSnapshot = plan; self.course.requiredDays = quote.days; }
        self.startedAt = start; self.endedAt = rpgLedger.seconds; self.definitionSnapshot = current;
        self.course.sessions = self.course.sessions + [self];
        self.course.plan.animal.animalTrainingSessions = self.course.plan.animal.animalTrainingSessions + [self];
        if (value.dailyCheckRequired)
        { self.course.pendingDay = value.day; self.course.plan.animal.pendingAnimalTrainingCourse = self.course; }
        value.status = 'resolved'; self.result = value; return value;
    }
;

modify RpgExpandedAnimalCourse
    checks = []
    pendingFailure = nil
;
class RpgExpandedAnimalTrainingCheckResult: RpgExpandedResult
    day = nil
    score = nil
    creditedDays = 0
    failureAdjudicationRequired = nil
;

/** B175 daily check: credit learning only after both sessions. */
class RpgExpandedAnimalTrainingCheck: object
    course = nil
    speciesModifier = 0
    approved = nil
    evidence = nil
    result = nil
    definitionSnapshot = nil
    failureResolution = nil
    definition() { return [self.course,self.speciesModifier,self.evidence]; }
    context()
    {
        local value = new RpgLiteContext(); value.skill = self.course.plan.skill;
        value.modifier = (self.course.plan.wild ? -5 : 0) + self.speciesModifier; return value;
    }
    assess()
    {
        if (self.course == nil || !self.course.ofKind(RpgExpandedAnimalCourse)) rpgExpandedReject('animal-training-check-course');
        local quote = self.course.assess(); local value = new RpgExpandedAnimalTrainingCheckResult();
        if (self.result != nil)
        {
            local current = self.definition();
            if (self.definitionSnapshot == nil || current.length() != self.definitionSnapshot.length())
                rpgExpandedReject('animal-training-check-binding');
            for (local index = 1; index <= current.length(); index += 1)
                if (current[index] != self.definitionSnapshot[index]) rpgExpandedReject('animal-training-check-binding');
            if (!holds(self.course.checks,self)) rpgExpandedReject('animal-training-check-history');
            value.status = 'reused'; value.check = self.result.check; value.score = self.result.score; value.day = self.result.day;
            value.creditedDays = self.result.creditedDays; value.failureAdjudicationRequired = self.result.failureAdjudicationRequired; return value;
        }
        if (quote.status != 'ready') { value.reason = quote.reason; return value; }
        rpgInteger(self.speciesModifier,-1000,0);
        if (!self.approved || self.evidence == nil || self.evidence == '')
        { value.reason = 'animal-training-check-author-facts'; return value; }
        if (self.course.pendingDay == nil || self.course.plan.animal.pendingAnimalTrainingCourse != self.course)
        { value.reason = 'animal-training-check-attendance-required'; return value; }
        if (self.course.pendingFailure != nil) { value.reason = 'animal-training-failure-unresolved'; return value; }
        value.day = self.course.pendingDay;
        foreach (local prior in self.course.checks)
            if (prior.result.day == value.day) { value.reason = 'animal-training-day-already-checked'; return value; }
        local attendance = 0;
        foreach (local session in self.course.sessions)
            if (session.result != nil && session.result.day == value.day) { session.assess(); attendance += 1; }
        if (attendance != 2) rpgExpandedReject('animal-training-check-attendance');
        foreach (local participant in [self.course.plan.animal,self.course.plan.trainer])
            if (participant.dead || participant.unconscious || participant.stunned || participant.hp() <= 0 || participant.fp() <= 0)
            { value.reason = 'animal-training-participant-unavailable'; return value; }
        local context = self.context(); value.score = rpgLiteScore(self.course.plan.trainer,context);
        if (value.score == nil) { value.reason = context.unavailableReason(self.course.plan.trainer); return value; }
        if (value.score < 3) { value.reason = 'too-difficult'; return value; }
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        value.check = rpgLiteCheck(self.course.plan.trainer,self.context());
        if (value.check.status != 'resolved') rpgExpandedReject('animal-training-check-changed');
        if (value.check.achieved)
        {
            self.course.successfulDays += 1; value.creditedDays = 1;
            self.course.pendingDay = nil; self.course.plan.animal.pendingAnimalTrainingCourse = nil;
        }
        else
        { self.course.pendingFailure = self; value.failureAdjudicationRequired = true; }
        self.course.checks = self.course.checks + [self]; self.definitionSnapshot = self.definition();
        value.status = 'resolved'; self.result = value; return value;
    }
;

/** Source leaves "badly failed" to adjudication; no numerical threshold is invented. */
class RpgExpandedAnimalTrainingFailure: object
    attempt = nil
    classification = nil
    approved = nil
    evidence = nil
    result = nil
    boundAttempt = nil
    boundClassification = nil
    boundEvidence = nil
    assess()
    {
        if (self.attempt == nil || !self.attempt.ofKind(RpgExpandedAnimalTrainingCheck) || self.attempt.result == nil
            || self.attempt.result.check.achieved) rpgExpandedReject('animal-training-failure-attempt');
        self.attempt.assess(); local value = new RpgExpandedResult();
        if (self.result != nil)
        {
            if (self.attempt != self.boundAttempt || self.classification != self.boundClassification
                || self.evidence != self.boundEvidence || self.attempt.failureResolution != self)
                rpgExpandedReject('animal-training-failure-binding');
            value.status = 'reused'; return value;
        }
        if (!holds(['ordinary','attack'],self.classification)) rpgExpandedReject('animal-training-failure-classification');
        if (!self.approved || self.evidence == nil || self.evidence == '')
        { value.reason = 'animal-training-failure-author-facts'; return value; }
        if (self.attempt.course.pendingFailure != self.attempt || self.attempt.failureResolution != nil
            || self.attempt.course.pendingDay != self.attempt.result.day
            || self.attempt.course.plan.animal.pendingAnimalTrainingCourse != self.attempt.course)
        { value.reason = 'animal-training-failure-not-pending'; return value; }
        if (self.classification == 'attack') { value.reason = 'animal-training-attack-execution-unavailable'; return value; }
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        local course = self.attempt.course;
        course.pendingFailure = nil; course.pendingDay = nil; course.plan.animal.pendingAnimalTrainingCourse = nil;
        self.attempt.failureResolution = self; self.boundAttempt = self.attempt;
        self.boundClassification = self.classification; self.boundEvidence = self.evidence;
        value.status = 'resolved'; self.result = value; return value;
    }
;

modify RpgExpandedProfile
    animalTrainingLevel = 0
    animalKnownTricks = []
    animalTrainingMilestones = []
;
modify RpgExpandedAnimalCourse
    milestone = nil
;
class RpgExpandedAnimalMilestoneResult: RpgExpandedResult
    level = nil
    trick = nil
;

/** Record the learned level or single trick after verified successful training days. */
class RpgExpandedAnimalTrainingMilestone: object
    course = nil
    approved = nil
    evidence = nil
    result = nil
    boundCourse = nil
    boundEvidence = nil
    assess()
    {
        if (self.course == nil || !self.course.ofKind(RpgExpandedAnimalCourse)) rpgExpandedReject('animal-milestone-course');
        local quote = self.course.assess(); local value = new RpgExpandedAnimalMilestoneResult();
        local animal = self.course.plan.animal;
        if (self.result != nil)
        {
            if (self.course != self.boundCourse || self.evidence != self.boundEvidence
                || self.course.milestone != self || !holds(animal.animalTrainingMilestones,self))
                rpgExpandedReject('animal-milestone-binding');
            value.status = 'reused'; value.level = self.result.level; value.trick = self.result.trick; return value;
        }
        if (quote.status != 'ready') { value.reason = quote.reason; return value; }
        if (!self.approved || self.evidence == nil || self.evidence == '')
        { value.reason = 'animal-milestone-author-facts'; return value; }
        if (self.course.milestone != nil) { value.reason = 'animal-milestone-already-recorded'; return value; }
        if (self.course.requiredDays == nil || self.course.successfulDays < self.course.requiredDays)
        { value.reason = 'animal-milestone-training-incomplete'; return value; }
        if (self.course.pendingDay != nil || self.course.pendingFailure != nil || animal.pendingAnimalTrainingCourse != nil)
        { value.reason = 'animal-milestone-unresolved-training'; return value; }
        local days = []; local credited = 0;
        foreach (local attempt in self.course.checks)
        {
            if (attempt == nil || !attempt.ofKind(RpgExpandedAnimalTrainingCheck) || attempt.course != self.course || attempt.result == nil)
                rpgExpandedReject('animal-milestone-check-history');
            attempt.assess();
            if (holds(days,attempt.result.day)) rpgExpandedReject('animal-milestone-duplicate-day');
            days = days + [attempt.result.day];
            if (attempt.result.check.achieved) credited += 1;
            else
            {
                if (attempt.failureResolution == nil || attempt.failureResolution.result == nil)
                { value.reason = 'animal-milestone-unresolved-training'; return value; }
                attempt.failureResolution.assess();
            }
        }
        if (credited != self.course.successfulDays || credited != self.course.requiredDays)
            rpgExpandedReject('animal-milestone-credit-history');
        value.level = self.course.plan.kind == 'general' ? self.course.plan.level : nil;
        value.trick = self.course.plan.kind == 'trick' ? self.course.plan.trick : nil;
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        local animal = self.course.plan.animal;
        if (value.level != nil) animal.animalTrainingLevel = value.level;
        if (value.trick != nil) animal.animalKnownTricks = animal.animalKnownTricks + [value.trick];
        self.course.milestone = self; animal.animalTrainingMilestones = animal.animalTrainingMilestones + [self];
        self.boundCourse = self.course; self.boundEvidence = self.evidence;
        value.status = 'resolved'; self.result = value; return value;
    }
;

/** An authored species-appropriate task requirement, checked against learned metadata. */
class RpgExpandedAnimalTask: object
    id = nil
    kind = 'general'
    requiredLevel = 3
    approved = nil
    evidence = nil
    definition() { return [self.id,self.kind,self.requiredLevel,self.approved,self.evidence]; }
    assess(animal)
    {
        if (animal == nil || !animal.ofKind(RpgExpandedProfile) || self.id == nil || self.id == ''
            || !holds(['general','trick'],self.kind)) rpgExpandedReject('animal-task-definition');
        local value = new RpgExpandedResult();
        if (!self.approved || self.evidence == nil || self.evidence == '')
        { value.reason = 'animal-task-author-facts'; return value; }
        rpgInteger(animal.animalTrainingLevel,0,5);
        if (self.kind == 'general')
        {
            rpgInteger(self.requiredLevel,2,5);
            if (animal.animalTrainingLevel < self.requiredLevel)
            { value.reason = 'animal-task-level-required'; return value; }
        }
        else
        {
            if (self.requiredLevel != nil) rpgExpandedReject('animal-task-unused-level');
            if (!holds(animal.animalKnownTricks,self.id))
            { value.reason = 'animal-task-trick-required'; return value; }
        }
        value.status = 'ready'; return value;
    }
;

class RpgExpandedAnimalValue: RpgExpandedResult
    numerator = 0
    denominator = 1
    money = nil
;

/** Exact valuation fraction; no invented currency rounding or ledger mutation. */
rpgExpandedAnimalScaledValue(baseValue, numerator, denominator)
{
    rpgInteger(baseValue,0,2147483647); rpgInteger(numerator,1,10); rpgInteger(denominator,1,3);
    local left = numerator; local right = denominator;
    while (right != 0) { local remainder = left % right; left = right; right = remainder; }
    numerator /= left; denominator /= left;
    left = baseValue; right = denominator;
    while (right != 0) { local remainder = left % right; left = right; right = remainder; }
    baseValue /= left; denominator /= left;
    if (baseValue > 2147483647 / numerator) rpgExpandedReject('animal-value-limit');
    local value = new RpgExpandedAnimalValue(); value.numerator = baseValue * numerator; value.denominator = denominator;
    if (denominator == 1) value.money = value.numerator;
    value.status = 'ready'; return value;
}

/** B459 ordinary domestic training value, before exceptional-intelligence pricing. */
rpgExpandedDomesticAnimalValue(baseValue, intelligence, trainingLevel)
{
    rpgInteger(intelligence,2,5); rpgInteger(trainingLevel,0,intelligence);
    if (trainingLevel == 1) rpgExpandedReject('animal-training-level');
    if (intelligence == 2) return rpgExpandedAnimalScaledValue(baseValue,1,1);
    if (trainingLevel < 3) return rpgExpandedAnimalScaledValue(baseValue,2,3);
    if (trainingLevel == 4) return rpgExpandedAnimalScaledValue(baseValue,3,2);
    if (trainingLevel == 5) return rpgExpandedAnimalScaledValue(baseValue,2,1);
    return rpgExpandedAnimalScaledValue(baseValue,1,1);
}

/** B459 exceptional domestic intelligence: use the species base price directly. */
rpgExpandedEnhancedAnimalValue(baseValue, intelligence, speciesIntelligence, trainingLevel)
{
    rpgInteger(baseValue,0,2147483647); rpgInteger(intelligence,2,5); rpgInteger(speciesIntelligence,2,5);
    rpgInteger(trainingLevel,0,intelligence);
    if (trainingLevel == 1) rpgExpandedReject('animal-training-level');
    local value = new RpgExpandedAnimalValue();
    if (intelligence-speciesIntelligence < 1 || intelligence-speciesIntelligence > 2)
    { value.reason = 'animal-value-intelligence-increase-unavailable'; return value; }
    if (trainingLevel != intelligence) { value.reason = 'animal-value-full-training-required'; return value; }
    return rpgExpandedAnimalScaledValue(baseValue,intelligence-speciesIntelligence == 1 ? 4 : 10,1);
}

/** B459 use Basic Move increase, not the Enhanced Move speed multiplier. */
rpgExpandedMountMoveValue(baseValue, basicMoveIncrease)
{
    rpgInteger(basicMoveIncrease,0,2);
    return rpgExpandedAnimalScaledValue(baseValue,basicMoveIncrease == 2 ? 4 : basicMoveIncrease == 1 ? 2 : 1,1);
}

/** Initial war training doubles value unless already included in the supplied price. */
rpgExpandedWarTrainingValue(baseValue, priceIncludesWarTraining)
{
    return rpgExpandedAnimalScaledValue(baseValue,priceIncludesWarTraining ? 1 : 2,1);
}

class RpgExpandedNaturalDamage: RpgExpandedResult
    dice = 0
    adds = 0
    damageType = nil
    skillBonus = 0
    anatomyBonus = 0
;

/** B460: unmodified thrust input, with anatomy and trained brawling applied once. */
rpgExpandedNaturalDamage(thrustDice, thrustAdds, kind, anatomy, weakBite, horizontal, dexterity, brawlingScore)
{
    rpgInteger(thrustDice,1,100); rpgInteger(thrustAdds,-1000,1000);
    rpgInteger(dexterity,1,1000);
    if (brawlingScore != nil) rpgInteger(brawlingScore,-1000,1000);
    if (!holds(['bite','claw','kick','striker'],kind)) rpgExpandedReject('animal-natural-attack-kind');
    if (weakBite && kind != 'bite') rpgExpandedReject('animal-natural-unused-weak-bite');
    if (horizontal && kind != 'kick') rpgExpandedReject('animal-natural-unused-horizontal');
    local value = new RpgExpandedNaturalDamage(); value.dice = thrustDice;
    value.damageType = 'cr'; local perDie = 0; local flat = 0;
    if (kind == 'bite')
    {
        if (!holds(['ordinary','sharp-teeth','fangs'],anatomy)) rpgExpandedReject('animal-natural-bite-anatomy');
        flat = -1; if (weakBite) perDie -= 2;
        if (anatomy == 'sharp-teeth') value.damageType = 'cut';
        if (anatomy == 'fangs') value.damageType = 'imp';
    }
    else if (kind == 'striker')
    {
        if (!holds(['cr','cut','imp'],anatomy)) rpgExpandedReject('animal-natural-striker-type');
        value.damageType = anatomy; perDie = 1;
    }
    else
    {
        if (!holds(['ordinary','blunt-claws','sharp-claws','hooves'],anatomy)
            || (kind == 'claw' && anatomy == 'hooves')) rpgExpandedReject('animal-natural-limb-anatomy');
        if (kind == 'claw') flat = -1;
        if (anatomy == 'blunt-claws' || anatomy == 'hooves') perDie += 1;
        if (anatomy == 'sharp-claws') value.damageType = 'cut';
        if (kind == 'kick' && horizontal && !holds(['blunt-claws','sharp-claws'],anatomy)) perDie -= 1;
    }
    value.anatomyBonus = flat + perDie * thrustDice;
    value.skillBonus = brawlingScore != nil && brawlingScore >= dexterity + 2 ? thrustDice : 0;
    value.adds = thrustAdds + value.anatomyBonus + value.skillBonus;
    if (value.adds < -1000 || value.adds > 1000) rpgExpandedReject('animal-natural-damage-limit');
    value.status = 'ready'; return value;
}

/** Use the shared full-reference thrust lookup before applying natural anatomy. */
rpgExpandedNaturalDamageForStrength(strength, kind, anatomy, weakBite, horizontal, dexterity, brawlingScore)
{
    local thrust = rpgExpandedDamageDice(strength,nil);
    return rpgExpandedNaturalDamage(thrust[1],thrust[2],kind,anatomy,weakBite,horizontal,dexterity,brawlingScore);
}

class RpgExpandedSwarmProtectionResult: RpgExpandedResult
    elapsed = 0
    immune = nil
    dr = 0
;

modify RpgExpandedProfile
    swarmExposures = []
;

/** B461 exposure timer. Start once inside the caller's action transaction. */
class RpgExpandedSwarmExposure: object
    swarm = nil
    victim = nil
    tiny = nil
    protection = 'none'
    armorDR = 0
    specialEffective = nil
    approved = nil
    evidence = nil
    startedAt = nil
    snapshot = nil
    definition()
    { return [self.swarm,self.victim,self.tiny,self.protection,self.armorDR,self.specialEffective,self.evidence]; }
    assess()
    {
        if (self.swarm == nil || self.victim == nil || !self.victim.ofKind(RpgExpandedProfile)
            || !holds(['none','clothing','low-tech-armor','normal-armor','special'],self.protection))
            rpgExpandedReject('swarm-exposure-definition');
        rpgInteger(self.armorDR,0,10000);
        if (self.protection != 'special' && self.specialEffective) rpgExpandedReject('swarm-unused-special-protection');
        if (!holds(['low-tech-armor','normal-armor'],self.protection) && self.armorDR != 0)
            rpgExpandedReject('swarm-unused-armor');
        local value = new RpgExpandedSwarmProtectionResult();
        if (self.startedAt != nil)
        {
            if (!holds(self.victim.swarmExposures,self)) rpgExpandedReject('swarm-exposure-history');
            local current = self.definition();
            if (self.snapshot == nil || self.snapshot.length() != current.length()) rpgExpandedReject('swarm-exposure-binding');
            for (local index = 1; index <= current.length(); index += 1)
                if (current[index] != self.snapshot[index]) rpgExpandedReject('swarm-exposure-binding');
            if (rpgLedger.seconds < self.startedAt) rpgExpandedReject('swarm-exposure-clock');
            value.elapsed = rpgLedger.seconds - self.startedAt;
        }
        else if (!self.approved || self.evidence == nil || self.evidence == '')
        { value.reason = 'swarm-exposure-author-facts'; return value; }
        if (self.startedAt == nil)
            foreach (local prior in self.victim.swarmExposures)
                if (prior.swarm == self.swarm)
                { value.reason = 'swarm-exposure-already-recorded'; return value; }
        if (self.tiny && self.protection == 'normal-armor')
        { value.reason = 'swarm-tiny-armor-classification-required'; return value; }
        if (self.protection == 'special') value.immune = self.specialEffective;
        else if (self.tiny)
            value.immune = (self.protection == 'clothing' && value.elapsed < 2)
                || (self.protection == 'low-tech-armor' && value.elapsed < 5);
        else if (holds(['low-tech-armor','normal-armor'],self.protection)) value.dr = self.armorDR;
        value.status = self.startedAt == nil ? 'ready' : 'active'; return value;
    }
    begin()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        self.snapshot = self.definition(); self.startedAt = rpgLedger.seconds;
        self.victim.swarmExposures = self.victim.swarmExposures + [self];
        return self.assess();
    }
;

/** Mechanical B461 sample swarm, with independent encounter history. */
class RpgExpandedSwarm: object
    kind = 'stinging-insects'
    attacks = []
    dispersed = nil
;

class RpgExpandedSwarmAttackResult: RpgExpandedResult
    damage = 0
    injury = 0
    wound = nil
    immune = nil
;

/** Automatic contact attack. The caller owns the combat clock and map facts. */
class RpgExpandedSwarmAttack: object
    id = nil
    exposure = nil
    mapped = nil
    inContact = nil
    approved = nil
    evidence = nil
    distanceFromNest = nil
    victimChangeReason = nil
    dropDestination = nil
    result = nil
    snapshot = nil
    resolvedAt = nil
    definition()
    { return [self.id,self.exposure,self.exposure.swarm,self.exposure.victim,self.exposure.swarm.kind,
        self.mapped,self.evidence,self.dropDestination,self.distanceFromNest,self.victimChangeReason]; }
    injuryFor(damage, protection)
    {
        if (protection.immune) return 0;
        if (self.exposure.swarm.kind == 'stinging-insects') return 1;
        local penetration = damage - protection.dr;
        return penetration <= 0 ? 0 : penetration * 3 / 2;
    }
    assess()
    {
        if (self.id == nil || self.id == '' || self.exposure == nil || !self.exposure.ofKind(RpgExpandedSwarmExposure)
            || self.exposure.swarm == nil || !self.exposure.swarm.ofKind(RpgExpandedSwarm)) rpgExpandedReject('swarm-attack-definition');
        local swarm = self.exposure.swarm; local value = new RpgExpandedSwarmAttackResult();
        if (!holds(['stinging-insects','flying-biters','ground-biters'],swarm.kind)) rpgExpandedReject('swarm-attack-kind');
        if (self.result != nil)
        {
            local current = self.definition();
            if (self.snapshot == nil || self.snapshot.length() != current.length()) rpgExpandedReject('swarm-attack-binding');
            for (local index = 1; index <= current.length(); index += 1)
                if (current[index] != self.snapshot[index]) rpgExpandedReject('swarm-attack-binding');
            if (!holds(swarm.attacks,self)) rpgExpandedReject('swarm-attack-history');
            value.status = 'reused'; value.damage = self.result.damage; value.injury = self.result.injury;
            value.wound = self.result.wound; value.immune = self.result.immune; return value;
        }
        if (!self.approved || !self.inContact || self.evidence == nil || self.evidence == '')
        { value.reason = 'swarm-attack-author-facts'; return value; }
        if (swarm.kind == 'stinging-insects')
        {
            if (self.distanceFromNest == nil) { value.reason = 'swarm-nest-distance-required'; return value; }
            rpgInteger(self.distanceFromNest,0,100000000);
            if (self.distanceFromNest >= 50) { value.reason = 'swarm-pursuit-ended'; return value; }
        }
        else if (self.distanceFromNest != nil) rpgExpandedReject('swarm-unused-nest-distance');
        if (!self.mapped && swarm.attacks.length() > 0
            && swarm.attacks[swarm.attacks.length()].exposure.victim != self.exposure.victim
            && (self.victimChangeReason == nil || self.victimChangeReason == ''))
        { value.reason = 'swarm-victim-change-reason-required'; return value; }
        if (swarm.dispersed) { value.reason = 'swarm-dispersed'; return value; }
        if (self.exposure.tiny != (swarm.kind == 'stinging-insects')) rpgExpandedReject('swarm-attack-size');
        if (self.exposure.startedAt == nil) { value.reason = 'swarm-exposure-required'; return value; }
        local protection = self.exposure.assess();
        if (protection.status != 'active') { value.reason = protection.reason; return value; }
        foreach (local prior in swarm.attacks)
        {
            if (prior.id == self.id) rpgExpandedReject('swarm-attack-duplicate');
            if (prior.resolvedAt == rpgLedger.seconds && (!self.mapped || !prior.mapped
                || prior.exposure.victim == self.exposure.victim))
            { value.reason = 'swarm-attack-turn-used'; return value; }
        }
        value.immune = protection.immune;
        local maximum = swarm.kind == 'stinging-insects' ? 1 : 6;
        for (local damage = 1; damage <= maximum; damage += 1)
        {
            local injury = self.injuryFor(damage,protection);
            if (injury > 0)
            {
                local wound = self.exposure.victim.prepareSwarmWound(self.id,injury,self.dropDestination);
                if (wound == nil) { value.reason = 'swarm-health-module-required'; return value; }
                local assessed = wound.assess();
                if (assessed.status != 'ready') { value.reason = assessed.reason; return value; }
            }
        }
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        local protection = self.exposure.assess();
        /* Immunity prevents the damage roll as well as injury. No attack or defense roll. */
        value.damage = protection.immune ? 0 : self.exposure.swarm.kind == 'stinging-insects' ? 1 : rpgRandom.die();
        value.injury = self.injuryFor(value.damage,protection);
        if (value.injury > 0)
        {
            value.wound = self.exposure.victim.prepareSwarmWound(self.id,value.injury,self.dropDestination);
            local outcome = value.wound.apply();
            if (outcome.status != 'resolved') rpgExpandedReject('swarm-wound-commit');
        }
        self.snapshot = self.definition(); self.resolvedAt = rpgLedger.seconds;
        self.exposure.swarm.attacks = self.exposure.swarm.attacks + [self];
        value.status = 'resolved'; self.result = value; return value;
    }
;
