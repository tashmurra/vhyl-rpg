/* Include after expanded foundation. Source: full-2008, B419.
 * This incremental module does not yet supply detailed injury or medical care. */

modify RpgExpandedRules
    scaledInjuryShock = nil
;

/** Shock from one wound, before trait exceptions; high capacity scales the divisor. */
rpgExpandedInjuryShock(capacity, injury)
{
    rpgInteger(capacity,1,1000); rpgInteger(injury,0,100000);
    local divisor = capacity < 20 ? 1 : capacity / 10;
    local penalty = injury / divisor;
    return penalty > 4 ? 4 : penalty;
}

modify RpgExpandedProfile
    shockFromInjury(amount)
    {
        if (self.rules == nil || !self.rules.ofKind(RpgExpandedRules))
            rpgExpandedReject('expanded-rules-required');
        if (!self.rules.scaledInjuryShock) return inherited(amount);
        if (self.level('low-pain-threshold') > 0)
            rpgExpandedReject('expanded-low-pain-shock-unavailable');
        return rpgExpandedInjuryShock(self.maxHP,amount);
    }
;

/** Pure location knockdown assessment; injury is already adjusted after protection.
 * This is not a damage multiplier or a wound commit. Source: full-2008 B419-B420. */
class RpgExpandedKnockdownAssessment: RpgExpandedResult
    major = nil
    required = nil
    modifier = 0
    shock = 0
;

/** Standard humanoid locations without crippling. B420 governs the strict
 * greater-than-half threshold; the conflicting appendix equality is not used. */
rpgExpandedAssessKnockdown(capacity, injury, location, maleGroin)
{
    rpgInteger(capacity,1,1000); rpgInteger(injury,0,100000);
    if (!holds(['torso','face','skull','vitals','groin'],location))
        rpgExpandedReject('expanded-knockdown-location-unavailable');
    if (maleGroin && location != 'groin') rpgExpandedReject('expanded-knockdown-groin-context');
    local value = new RpgExpandedKnockdownAssessment();
    value.shock = rpgExpandedInjuryShock(capacity,injury);
    value.major = injury * 2 > capacity;
    value.required = value.major || value.shock > 0 && holds(['face','skull','vitals'],location);
    if (value.major)
    {
        if (location == 'skull') value.modifier = -10;
        else if (holds(['face','vitals'],location) || location == 'groin' && maleGroin)
            value.modifier = -5;
    }
    value.status = 'ready'; return value;
}


modify RpgExpandedProfile
    expandedWounds = []
;

/** Preflight and receipt envelope for an explicitly selected expanded wound. */
class RpgExpandedWoundResult: RpgExpandedResult
    assessment = nil
    health = nil
;

/** Owned standard-anatomy wound. Amount is final injury, not raw attack damage.
 * Unsupported anatomy, held-item dropping and low-target checks reject before
 * commit. Run apply() inside the existing action transaction. */
class RpgExpandedWound: object
    id = nil
    profile = nil
    amount = 0
    location = 'torso'
    maleGroin = nil
    anatomy = 'standard-humanoid'
    boundProfile = nil
    boundId = nil
    boundAmount = 0
    boundLocation = nil
    boundMaleGroin = nil
    health = nil
    assess()
    {
        if (self.profile == nil || !self.profile.ofKind(RpgExpandedProfile) || self.id == nil || self.id == '')
            rpgExpandedReject('expanded-wound-owner');
        local value = new RpgExpandedWoundResult();
        if (self.health != nil)
        {
            if (!holds(self.profile.expandedWounds,self)) rpgExpandedReject('expanded-wound-history');
            if (self.profile != self.boundProfile || self.id != self.boundId || self.amount != self.boundAmount
                || self.location != self.boundLocation || self.maleGroin != self.boundMaleGroin
                || self.anatomy != 'standard-humanoid') rpgExpandedReject('expanded-wound-retargeted');
            value.status = 'reused'; value.health = self.health; return value;
        }
        rpgExpandedValidate(self.profile);
        foreach (local wound in self.profile.expandedWounds)
            if (wound.id == self.id) rpgExpandedReject('expanded-wound-duplicate');
        if (!self.profile.rules.scaledInjuryShock)
        { value.reason = 'expanded-wound-shock-rule-required'; return value; }
        if (self.anatomy != 'standard-humanoid')
        { value.reason = 'expanded-wound-anatomy-unavailable'; return value; }
        foreach (local traitId in ['no-brain','no-vitals','homogenous','diffuse','low-pain-threshold'])
            if (self.profile.level(traitId) > 0)
            { value.reason = 'expanded-wound-trait-unavailable'; return value; }
        if (self.profile.dead) { value.reason = 'expanded-wound-dead'; return value; }
        value.assessment = rpgExpandedAssessKnockdown(self.profile.maxHP,self.amount,self.location,self.maleGroin);
        if (value.assessment.required && !self.profile.unconscious)
        {
            foreach (local item in self.profile.equipment)
                if (item.ready && !item.worn)
                { value.reason = 'expanded-wound-drop-unavailable'; return value; }
            local context = new RpgLiteContext(); context.attribute = rpgHT;
            context.kind = 'major-wound'; context.modifier = value.assessment.modifier;
            local score = rpgLiteScore(self.profile,context);
            if (score == nil || score < 3)
            { value.reason = 'expanded-knockdown-score-unavailable'; return value; }
        }
        if (self.profile.ht < 3 && self.profile.hp() - self.amount <= -self.profile.maxHP)
        { value.reason = 'expanded-survival-score-unavailable'; return value; }
        self.profile.shockFromInjury(self.amount);
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        self.health = rpgLiteWoundWithKnockdown(self.profile,self.amount,
            value.assessment.required,value.assessment.modifier);
        self.boundProfile = self.profile; self.boundId = self.id; self.boundAmount = self.amount;
        self.boundLocation = self.location; self.boundMaleGroin = self.maleGroin;
        self.profile.expandedWounds = self.profile.expandedWounds + [self];
        value.health = self.health; value.status = 'resolved'; return value;
    }
;

modify RpgExpandedProfile
    validateFeatures()
    {
        inherited(); local ids = [];
        foreach (local wound in self.expandedWounds)
        {
            if (wound == nil || !wound.ofKind(RpgExpandedWound) || wound.profile != self
                || wound.boundProfile != self || wound.health == nil || wound.id != wound.boundId
                || holds(ids,wound.id)) rpgExpandedReject('expanded-wound-history');
            ids = ids + [wound.id];
        }
        return nil;
    }
;
