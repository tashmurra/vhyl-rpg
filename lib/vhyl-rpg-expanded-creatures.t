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
