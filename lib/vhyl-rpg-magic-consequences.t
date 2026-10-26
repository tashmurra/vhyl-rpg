/* Authored narrative consequences have concrete persistent mechanical records. */
class RpgMagicComplication: object
    id = nil
    severity = 1
    kind = 'complication'
    description = ''
    active = nil
    owner = nil
    resolution = nil
;
class RpgMagicExposure: object
    target = nil
    yards = 1
    cover = 0
    armor = nil
    dodge = 0
    eligible = nil
    stepYards = 1
    stepCover = 0
;
class RpgMagicConsequenceBatch: RpgMagicConsequence
    consequences = []
    exposures = []
    protection = 0
    extraLasting = 0
    available(state,backlash)
    {
        if (state.subject == nil || state.subject.profile == nil) return 'magic-health-profile';
        local count = self.consequences.length();
        if (self.band != 5 && self.extraLasting != 0 || self.band == 5 && !holds([0,2],self.extraLasting)) return 'magic-lasting-choice';
        if (self.band == 1 && (count != 1 || self.consequences[1].severity != 1)
            || self.band == 2 && self.branch != 'physical' && (count != 1 || self.consequences[1].severity != 2)
            || self.band == 3 && self.branch != 'physical' && (count != 1 || self.consequences[1].severity != 3)
            || self.band == 4 && self.branch == 'paired' && count != 2
            || self.band == 5 && !(self.extraLasting == 2 && count == 0 || self.extraLasting == 0 && count == 1))
            return 'magic-incomplete-consequence';
        local ids = [];
        foreach (local c in self.consequences)
        {
            if (c.id == nil || c.active || holds(ids,c.id) || c.description == ''
                || !holds(['complication','encounter','perception','confinement'],c.kind)
                || self.band >= 4 && c.severity < self.band
                || self.band <= 2 && c.kind != 'complication')
                return 'magic-consequence-content';
            ids = ids + [c.id];
        }
        rpgInteger(self.protection,0,1000000);
        local targets = [];
        foreach (local x in self.exposures)
        {
            if (x.target == state.subject || x.target.profile == nil || holds(targets,x.target)) return 'magic-blast-target';
            targets = targets + [x.target]; rpgInteger(x.yards,0,1000000);
            if (x.eligible && (x.stepYards < 0 || x.stepYards > x.yards + 1 || x.stepYards < x.yards - 1)) return 'magic-blast-step';
        }
        return nil;
    }
    apply(state,backlash,injury,lasting)
    {
        state.lasting += self.extraLasting; rpgMagicAddStrain(state,0);
        if (injury > 0)
        {
            local n = injury - self.protection; if (n < 0) n = 0;
            rpgMagicWound(state.subject,n,'backlash',nil);
            if (backlash.strength >= 10)
                foreach (local x in self.exposures)
                {
                    local yards = x.yards; local cover = x.cover;
                    if (x.eligible && rpgLiteDefenseCheck(x.dodge + 3).rollSucceeded)
                    { yards = x.stepYards; cover = x.stepCover; }
                    rpgMagicWound(x.target,rpgMagicBlastInjury(injury,yards,cover,x.armor == nil ? rpgLiteArmor(x.target.profile) : x.armor),'backlash',nil);
                }
        }
        foreach (local c in self.consequences)
        { c.active = true; c.owner = state; state.complications = state.complications + [c]; }
        return nil;
    }
;
modify RpgMagicState
    complications = []
    complicationBatches = []
;

/** One atomic voluntary batch at a frozen pre-spend total. */
rpgAcceptMagicComplications(state,id,choices)
{
    local r = new RpgExpandedResult();
    if (holds(state.complicationBatches,id)) { r.status = 'reused'; return r; }
    local total = state.totalStrain(); local cost = 0; local seen = [];
    foreach (local c in choices)
    {
        if (c.active || c.id == nil || holds(seen,c.id) || c.description == '') rpgExpandedReject('magic-complication');
        rpgInteger(c.severity,1,5);
        if (total > 8 && c.severity != 5) { r.reason = 'magic-complication-severity'; return r; }
        cost += c.severity; seen = seen + [c.id];
    }
    if (cost < (total + 1) / 2 || cost > state.strain || cost == 0)
    { r.reason = 'magic-complication-budget'; return r; }
    state.strain -= cost; state.revision += 1; state.complicationBatches = state.complicationBatches + [id];
    foreach (local c in choices) { c.active = true; c.owner = state; state.complications = state.complications + [c]; }
    r.points = cost; r.status = 'resolved'; return r;
}
