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
        return [self.id,self.animal,self.handler,self.skill,self.appropriateSpecialty,self.mode,self.taskId,
            self.trainingEstablished,self.familiar,self.stressful,self.complexityPenalty,self.wild,self.frightened,
            self.manKiller,self.speciesModifier,self.performance,self.seconds,self.evidence];
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
            if (!self.trainingEstablished) { value.reason = 'animal-handling-training-required'; return value; }
        }
        else if (self.taskId != nil || self.complexityPenalty != 0 || self.stressful || self.trainingEstablished)
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
