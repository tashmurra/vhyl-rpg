/* Include after expanded skills. Source: full-2008, B292-B293. */

modify RpgExpandedProfile
    studyDay = -1
    studyUsed = [0,0,0,0]
;

/** Owned study track. Time grants points directly to its owned training, never
 * to the spendable adventure-point bank. Credit uses quarter learning-seconds. */
class RpgExpandedStudy: object
    profile = nil
    training = nil
    mode = 'self'
    attentionSituation = nil
    attentionEvidence = nil
    permitted = nil
    employment = 'none'
    communicationLanguage = nil
    communicationMode = nil
    communicationEvidence = nil
    teacher = nil
    teachingScore = 0
    lavishMaterials = nil
    credit = 0
    awarded = 0
    creditOwner = nil
    creditTraining = nil
    creditSkill = nil
    creditThreshold = nil
    learningThreshold()
    {
        local percent = self.profile.studyTimePercent(self.training.skill);
        rpgInteger(percent,60,100);
        if (percent % 10 != 0) rpgExpandedReject('study-rate-definition');
        local threshold = 28800 * percent;
        if (self.creditThreshold != nil && self.creditThreshold != threshold && self.credit != 0)
            rpgExpandedReject('study-rate-change-unresolved');
        return threshold;
    }
    validateOwnership()
    {
        if (self.profile == nil || !self.profile.ofKind(RpgExpandedProfile)
            || self.training == nil || !self.training.ofKind(RpgTraining)
            || self.training.skill == nil || !self.training.skill.ofKind(RpgSkill)
            || !holds(self.profile.skills,self.training)) rpgExpandedReject('study-ownership');
        local copies = 0;
        for (local profile = firstObj(RpgProfile); profile != nil; profile = nextObj(profile,RpgProfile))
            foreach (local training in profile.skills)
                if (training == self.training) copies += 1;
        if (copies != 1 || rpgExpandedTrainingFor(self.profile,self.training.skill) != self.training)
            rpgExpandedReject('study-shared-training');
        return nil;
    }
    assess(seconds)
    {
        rpgInteger(seconds, 1, 57600);
        local value = new RpgExpandedResult();
        self.validateOwnership();
        value.reason = self.profile.nonTravelScheduleReason(rpgLedger.seconds,seconds);
        if (value.reason != nil) return value;
        if (self.creditOwner != nil && (self.creditOwner != self.profile
            || self.creditTraining != self.training || self.creditSkill != self.training.skill))
            rpgExpandedReject('study-retargeted');
        if (!holds(['job','self','education','intensive'], self.mode)
            || !holds(['none','part','full'], self.employment)) rpgExpandedReject('study-mode');
        local threshold = self.learningThreshold();
        rpgInteger(self.credit, 0, threshold - 1); rpgInteger(self.awarded, 0, 1000000);
        if (!self.permitted || !profile.developmentOpen)
        { value.reason = 'study-unavailable'; return value; }
        value.reason = profile.skillLearningWithTeacherReason(training.skill,
            self.mode == 'education' || self.mode == 'intensive' ? self.teacher : nil);
        if (value.reason != nil) return value;
        value.reason = self.profile.studyCommunicationReason(self); if (value.reason != nil) return value;
        if (profile.dead || profile.unconscious) { value.reason = 'cannot-study'; return value; }
        local index = self.modeIndex(); local limit = self.dailyLimit();
        local day = rpgLedger.seconds / 86400;
        local used = profile.studyDay == day ? profile.studyUsed[index] : 0;
        if (seconds > limit - used || seconds > 86400 - rpgLedger.seconds % 86400)
        { value.reason = 'study-day-limit'; return value; }
        if (self.mode == 'education' || self.mode == 'intensive')
        {
            if (self.teacher == nil || self.teacher == self.profile || self.teachingScore < 12)
            { value.reason = 'teacher-required'; return value; }
            value.reason = self.teacher.ofKind(RpgExpandedProfile) ? self.teacher.nonTravelScheduleReason(rpgLedger.seconds,seconds) : nil;
            if (value.reason != nil) return value;
            local teacherTraining = rpgExpandedTrainingFor(self.teacher, self.training.skill);
            local learnerScore = profile.skillScore(self.training.skill);
            local teacherScore = self.teacher.skillScore(self.training.skill);
            if (teacherTraining == nil || teacherTraining.points < 1 || teacherScore == nil)
            { value.reason = 'teacher-subject'; return value; }
            if (self.mode == 'education'
                && teacherTraining.points < self.training.points
                && learnerScore != nil && teacherScore < learnerScore)
            { value.reason = 'teacher-subject'; return value; }
            if (self.mode == 'intensive'
                && (!self.lavishMaterials || teacherTraining.points <= self.training.points
                    || learnerScore != nil && teacherScore <= learnerScore
                    || profile.ht + (profile.level('very-fit') > 0 ? 2 : profile.level('fit') > 0 ? 1 : 0) < 12))
            { value.reason = 'intensive-requirements'; return value; }
        }
        value.status = 'ready'; value.seconds = seconds;
        value.points = (self.credit + seconds * self.factor()) / threshold;
        if (self.training.points + value.points > 10000) rpgExpandedReject('training-limit');
        return value;
    }
    modeIndex() { return self.mode == 'job' ? 1 : self.mode == 'self' ? 2 : self.mode == 'education' ? 3 : 4; }
    factor() { return [1,2,4,8][self.modeIndex()]; }
    dailyLimit()
    {
        if (self.mode == 'job') return self.employment == 'part' ? 14400 : self.employment == 'full' ? 28800 : 0;
        if (self.mode == 'self') return self.employment == 'full' ? 14400 : self.employment == 'part' ? 28800 : 43200;
        return self.mode == 'education' ? 28800 : 57600;
    }
    sessionDefinition()
    {
        return [self.profile,self.training,self.training.skill,self.training.points,self.mode,self.permitted,
            self.employment,self.teacher,self.teachingScore,self.lavishMaterials,self.communicationMode,self.communicationEvidence,self.communicationLanguage,self.credit,self.awarded,
            self.creditOwner,self.creditTraining,self.creditSkill,self.profile.studyDay,self.creditThreshold,self.learningThreshold(),
            self.attentionSituation,self.attentionEvidence]
            + self.profile.studyUsed;
    }
    advance(seconds)
    {
        self.validateOwnership();
        local reason = self.profile.studyAttentionReason(self);
        if (reason != nil) { local value = new RpgExpandedResult(); value.reason = reason; return value; }
        return self.advanceCredit(seconds,true);
    }
    advanceAttention(control)
    {
        self.validateOwnership();
        local reason = self.profile.attentionStudyControlReason(control,self);
        if (reason != nil) rpgExpandedReject(reason);
        control.studyStarted = true;
        return self.advanceCredit(control.seconds,control.check.achieved);
    }
    /* Internal settlement shared by ordinary and attention-owned attempts. */
    advanceCredit(seconds,earnCredit)
    {
        local value = self.assess(seconds);
        if (value.status != 'ready') return value;
        local definition = self.sessionDefinition(); local start = rpgLedger.seconds;
        local day = start / 86400;
        local previousUsed = self.profile.studyDay == day ? self.profile.studyUsed : [0,0,0,0];
        local used = [];
        for (local i = 1; i <= 4; i += 1)
            used = used + [previousUsed[i] + (i == self.modeIndex() ? seconds : 0)];
        rpgSpendTime(seconds);
        local current = self.sessionDefinition();
        if (rpgLedger.seconds != start + seconds || current.length() != definition.length())
            rpgExpandedReject('study-interrupted');
        for (local i = 1; i <= current.length(); i += 1)
            if (current[i] != definition[i]) rpgExpandedReject('study-interrupted');
        /* One second probes continued eligibility without charging a second session
         * or reapplying the original duration to a new calendar day. */
        if (self.assess(1).status != 'ready') rpgExpandedReject('study-conditions-changed');
        self.creditOwner = self.profile; self.creditTraining = self.training;
        self.creditSkill = self.training.skill;
        self.profile.studyDay = day; self.profile.studyUsed = used;
        local threshold = self.learningThreshold(); self.creditThreshold = threshold;
        if (earnCredit)
        {
            self.credit = (self.credit + seconds * self.factor()) % threshold;
            self.training.points += value.points; self.awarded += value.points;
        }
        else { value.points = 0; value.reason = 'short-attention-task-failure'; }
        value.status = 'resolved'; return value;
    }
;

/** B125/B292 full-value communication time, without advancing the clock again. */
class RpgExpandedCommunicationStudy: object
    id = nil
    source = nil
    study = nil
    approved = nil
    evidence = nil
    result = nil
    boundDefinition = nil
    definition() { return [self.id,self.source,self.study,self.study.profile,self.study.training,
        self.study.training.skill,self.approved,self.evidence]; }
    assess()
    {
        if (self.id == nil || self.id == '' || self.source == nil || !self.source.ofKind(RpgExpandedCommunicationReceipt)
            || self.study == nil || !self.study.ofKind(RpgExpandedStudy) || self.study.profile == nil
            || !self.study.profile.ofKind(RpgExpandedProfile) || self.study.training == nil
            || !holds(self.study.profile.skills,self.study.training)) rpgExpandedReject('communication-study-ownership');
        self.study.validateOwnership();
        local value = new RpgExpandedResult();
        if (self.result != nil)
        {
            local current = self.definition();
            for (local i = 1; i <= current.length(); i += 1)
                if (current[i] != self.boundDefinition[i]) rpgExpandedReject('communication-study-binding');
            if (self.source.studyCredit(self.study.profile) != self || self.source.studySeconds(self.study.profile) != self.result.seconds)
                rpgExpandedReject('communication-study-history');
            value.status = 'reused'; return value;
        }
        if (!self.approved || self.evidence == nil || self.evidence == '' || !self.study.permitted)
        { value.reason = 'communication-study-related-skill-required'; return value; }
        if (self.source.studyCredit(self.study.profile) != nil) { value.reason = 'communication-study-already-credited'; return value; }
        value.seconds = self.source.studySeconds(self.study.profile);
        if (value.seconds <= 0) { value.reason = 'communication-study-no-eligible-time'; return value; }
        rpgInteger(value.seconds,1,86400);
        value.reason = self.study.profile.skillLearningWithTeacherReason(self.study.training.skill,nil);
        if (value.reason != nil) return value;
        if (self.study.creditOwner != nil && (self.study.creditOwner != self.study.profile
            || self.study.creditTraining != self.study.training || self.study.creditSkill != self.study.training.skill))
            rpgExpandedReject('study-retargeted');
        local threshold = self.study.learningThreshold();
        rpgInteger(self.study.credit,0,threshold-1); rpgInteger(self.study.awarded,0,1000000);
        value.points = (self.study.credit + value.seconds * 4) / threshold;
        rpgInteger(self.study.training.points,0,10000-value.points);
        rpgInteger(self.study.awarded,0,1000000-value.points);
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status == 'reused') return self.result;
        if (value.status != 'ready') return value;
        self.boundDefinition = self.definition();
        self.study.creditOwner = self.study.profile; self.study.creditTraining = self.study.training;
        self.study.creditSkill = self.study.training.skill;
        local threshold = self.study.learningThreshold(); self.study.creditThreshold = threshold;
        self.study.credit = (self.study.credit + value.seconds * 4) % threshold;
        self.study.training.points += value.points; self.study.awarded += value.points;
        self.source.recordStudyCredit(self.study.profile,self); value.status = 'resolved'; self.result = value; return value;
    }
;

modify RpgExpandedProfile
    travelDayConflict(day)
    {
        local reason = inherited(day); if (reason != nil) return reason;
        if (self.studyDay == day)
            foreach (local used in self.studyUsed) if (used > 0) return 'travel-day-study-started';
        return nil;
    }
;

modify RpgExpandedProfile
    validateAttentionStudy(study)
    {
        if (study == nil || !study.ofKind(RpgExpandedStudy) || study.profile != self)
            rpgExpandedReject('attention-study-ownership');
        study.validateOwnership(); return nil;
    }
;
