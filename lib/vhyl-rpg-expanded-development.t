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
    permitted = nil
    employment = 'none'
    teacher = nil
    teachingScore = 0
    lavishMaterials = nil
    credit = 0
    awarded = 0
    creditOwner = nil
    creditTraining = nil
    creditSkill = nil
    assess(seconds)
    {
        rpgInteger(seconds, 1, 57600);
        local value = new RpgExpandedResult();
        if (profile == nil || !profile.ofKind(RpgExpandedProfile)
            || training == nil || !holds(profile.skills, training))
            rpgExpandedReject('study-ownership');
        if (self.creditOwner != nil && (self.creditOwner != self.profile
            || self.creditTraining != self.training || self.creditSkill != self.training.skill))
            rpgExpandedReject('study-retargeted');
        if (!holds(['job','self','education','intensive'], self.mode)
            || !holds(['none','part','full'], self.employment)) rpgExpandedReject('study-mode');
        rpgInteger(self.credit, 0, 2879999); rpgInteger(self.awarded, 0, 1000000);
        if (!self.permitted || !profile.developmentOpen)
        { value.reason = 'study-unavailable'; return value; }
        value.reason = profile.skillLearningWithTeacherReason(training.skill,
            self.mode == 'education' || self.mode == 'intensive' ? self.teacher : nil);
        if (value.reason != nil) return value;
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
        value.points = (self.credit + seconds * self.factor()) / 2880000;
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
            self.employment,self.teacher,self.teachingScore,self.lavishMaterials,self.credit,self.awarded,
            self.creditOwner,self.creditTraining,self.creditSkill,self.profile.studyDay]
            + self.profile.studyUsed;
    }
    advance(seconds)
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
        self.credit = (self.credit + seconds * self.factor()) % 2880000;
        self.training.points += value.points; self.awarded += value.points;
        value.status = 'resolved'; return value;
    }
;
