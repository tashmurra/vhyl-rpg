/** Owned, parameterized advantage or disadvantage; scope identifies authored subjects or specialties. */
class RpgLiteTrait: RpgTrait
    id = nil
    points = 0
    level = 1
    skills = []
    scope = nil
    controlled = nil
    active = true
    mitigated = nil
    nextCheck = 0
    modifierFor(context) { return 0; }
    /* Expanded cost hook; Lite callers retain their existing cost function. */
    creationCost() { return rpgLiteTraitCost(self); }
;

/** Independent spoken and written comprehension (0–3); native language receives a six-point allowance. */
class RpgLiteLanguage: object
    id = nil
    spoken = 3
    written = 3
    native = nil
    cost() { return self.spoken + self.written - (self.native ? 6 : 0); }
;

/** Catalogue skill with technology level and specialty identity. */
class RpgLiteSkill: RpgSkill
    id = nil
    techLevel = nil
    defaultAttribute = nil
    alternateAttribute = nil
    specialty = nil
    influence = nil
    voice = nil
    interval = 0
;

/** Lite character sheet. Injury and fatigue are deficits, not the legacy energy/body pools. */
class RpgLiteProfile: RpgProfile
    campaignTL = 3
    techLevel = 3
    languages = []
    equipment = []
    familiarSkills = nil
    pointBudget = 100
    disadvantageLimit = 50
    creationComplete = nil
    injury = 0
    fatigue = 0
    shock = 0
    stunned = nil
    mentalStun = nil
    unconscious = nil
    dead = nil
    mortal = nil
    apparentDeath = nil
    posture = 'standing'
    hunger = 0
    thirst = 0
    sleepDebt = 0
    restClock = 0
    healingClock = 0
    unconsciousClock = 0
    mortalClock = 0
    airClock = 0
    playSeconds = 0
    luckReady = 0
    sessionId = 0
    unluckySession = -1
    fearSeconds = 0
    aidUsed = nil
    money = 0
    hp() { return self.maxHP - self.injury; }
    fp() { return self.maxEnergy - self.fatigue; }
    basicSpeedQuarters() { return self.dx + self.ht; }
    basicMove() { return self.basicSpeedQuarters() / 4; }
    basicLiftHundredths()
    {
        local amount = self.st * self.st * 20;
        return amount >= 1000 ? (amount + 50) / 100 * 100 : amount;
    }
    trait(id)
    {
        foreach (local item in self.traits)
            if (item.ofKind(RpgLiteTrait) && item.id == id) return item;
        return nil;
    }
    level(id)
    {
        if (id == 'bad-sight') return self.level('bad-sight-correctable') > 0 ? 1 : self.rawLevel(id);
        if (id == 'resistant-disease') return self.level('resistant-disease-8') > 0 ? 8 : self.level('resistant-disease-3') > 0 ? 3 : 0;
        if (id == 'resistant-poison') return self.level('resistant-poison-3') > 0 ? 3 : 0;
        return self.rawLevel(id);
    }
    rawLevel(id)
    {
        local item = self.trait(id);
        return item == nil || !item.active || item.mitigated ? 0 : item.level;
    }
    language(id, written)
    {
        foreach (local item in self.languages)
            if (item.id == id)
            {
                local amount = written ? item.written : item.spoken;
                if (amount > 0 && amount < 3 && self.level('language-talent') > 0) amount += 1;
                return amount;
            }
        return 0;
    }
    loadHundredths()
    {
        local amount = 0;
        foreach (local item in self.equipment)
            if (item.usableBy(self)) amount += item.weightHundredths();
        return amount;
    }
    encumbrance()
    {
        local weight = self.loadHundredths(); local lift = self.basicLiftHundredths();
        local factors = [1, 2, 3, 6, 10];
        for (local index = 1; index <= 5; index += 1)
            if (weight <= lift * factors[index]) return index - 1;
        return 5;
    }
    move()
    {
        local load = self.encumbrance();
        if (load == 5 || self.unconscious || self.dead) return 0;
        local amount = self.basicMove() * (5 - load) / 5;
        if (amount < 1) amount = 1;
        if (self.hp() * 3 < self.maxHP) amount = (amount + 1) / 2;
        if (self.fp() * 3 < self.maxEnergy) amount = (amount + 1) / 2;
        if (self.posture == 'crouching') amount = amount * 2 / 3;
        if (self.posture == 'kneeling' || self.posture == 'crawling') amount /= 3;
        if (self.posture == 'sitting') amount = 0;
        if (self.posture == 'lying') amount = 1;
        return amount;
    }
    skillScore(skill)
    {
        if (!skill.ofKind(RpgLiteSkill)) return inherited(skill);
        local trained = nil;
        foreach (local training in self.skills)
            if (training.skill == skill && training.points > 0) trained = true;
        if (!trained && (skill.techLevel != nil && skill.techLevel > self.techLevel
            || self.familiarSkills != nil && !holds(self.familiarSkills, skill))) return nil;
        local score = inherited(skill);
        if (!trained && skill.defaultPenalty != nil)
        {
            local attribute = skill.defaultAttribute == nil ? skill.attribute : skill.defaultAttribute;
            local base = self.attributeScore(attribute);
            if (base > 20) base = 20;
            score = base + skill.defaultPenalty;
            if (skill.alternateAttribute != nil)
            {
                base = self.attributeScore(skill.alternateAttribute);
                if (base > 20) base = 20;
                if (base + skill.defaultPenalty > score) score = base + skill.defaultPenalty;
            }
        }
        return score;
    }
;

/** Check circumstances and optional immediate Luck decision; score queries do not roll. */
class RpgLiteContext: object
    kind = 'skill'
    skill = nil
    attribute = rpgIQ
    modifier = 0
    darkness = 0
    someLight = true
    offHand = nil
    closeQuarters = 0
    unnecessaryRisk = nil
    understandsSpeech = nil
    deceptive = nil
    phobiaPresent = nil
    language = nil
    written = nil
    resistedTrait = nil
    scoreFor(profile)
    {
        return self.skill == nil ? profile.attributeScore(self.attribute)
            : profile.skillScore(self.skill);
    }
    controllingAttribute() { return self.skill == nil ? self.attribute : self.skill.attribute; }
    skillUseModifier(profile) { return 0; }
    equipmentUseModifier(profile) { return 0; }
    unavailableReason(profile) { return 'training-required'; }
    reroll(profile, result) { return nil; }
;

/** Calculate effective skill or attribute without consuming randomness; nil means no legal default. */
rpgLiteScore(profile, context)
{
    local score = context.scoreFor(profile);
    if (score == nil) return nil;
    local attribute = context.controllingAttribute();
    local skillId = context.skill != nil && context.skill.ofKind(RpgLiteSkill) ? context.skill.id : nil;
    local useModifier = context.skillUseModifier(profile);
    if (useModifier == nil) return nil;
    local equipmentModifier = context.equipmentUseModifier(profile);
    if (equipmentModifier == nil) return nil;
    local adjustment = context.modifier + useModifier + equipmentModifier;
    if (context.offHand && profile.level('ambidexterity') == 0 && skillId != 'karate') adjustment -= 4;
    local darkness = context.darkness;
    if (context.someLight) darkness -= profile.level('night-vision');
    if (darkness > 0) adjustment -= darkness;
    if (profile.level('high-pain-threshold') == 0 && context.kind != 'defense' && (attribute == rpgDX || attribute == rpgIQ))
        adjustment -= profile.shock;
    if (profile.sleepPenalty && (attribute == rpgDX || attribute == rpgIQ)) adjustment -= 2;
    if (attribute == rpgDX && context.kind != 'extinguish') adjustment -= profile.burningPenalty;
    if (context.phobiaPresent && (attribute == rpgIQ || attribute == rpgDX || context.skill != nil))
        adjustment -= 2;
    if (context.language != nil)
    {
        local comprehension = profile.language(context.language, context.written);
        if (comprehension == 0) return nil;
        adjustment += comprehension == 1 ? -3 : comprehension == 2 ? -1 : 0;
    }
    if (context.kind == 'vision') adjustment += profile.level('acute-vision') - (profile.level('bad-sight') > 0 ? 6 : 0);
    if (context.kind == 'hearing' || context.understandsSpeech)
        adjustment += (context.kind == 'hearing' ? profile.level('acute-hearing') : 0)
            - (profile.level('hard-of-hearing') > 0 ? 4 : 0);
    if (context.kind == 'taste-smell') adjustment += profile.level('acute-taste-smell');
    if (context.kind == 'touch') adjustment += profile.level('acute-touch');
    if (context.kind == 'fright') adjustment += profile.level('fearlessness') + 2 * profile.level('combat-reflexes');
    if (context.kind == 'intimidation-resistance') adjustment += profile.level('fearlessness');
    if (context.kind == 'death' || context.kind == 'mortal-wound') adjustment += profile.level('hard-to-kill');
    if (context.kind == 'major-wound' || context.kind == 'torture') adjustment += 3 * profile.level('high-pain-threshold');
    if (context.kind == 'wake' || context.kind == 'mental-stun') adjustment += 6 * profile.level('combat-reflexes');
    if (context.kind == 'disease') adjustment += profile.level('resistant-disease');
    if (context.kind == 'poison') adjustment += profile.level('resistant-poison');
    if (context.kind == 'balance') adjustment += 6 * profile.level('perfect-balance');
    if (context.kind == 'keep-feet') adjustment += 4 * profile.level('perfect-balance');
    if (context.kind == 'attack' && profile.level('bad-sight') > 0) adjustment -= 2;
    if (context.skill != nil)
    {
        if (context.unnecessaryRisk && profile.level('daredevil') > 0) adjustment += 1;
        foreach (local trait in profile.traits)
            if (trait.ofKind(RpgLiteTrait) && trait.active && !trait.mitigated && holds(trait.skills, context.skill))
                adjustment += trait.level;
        if (holds(['armoury','electronics-repair','engineer','mechanic'], skillId)) adjustment += profile.level('artificer');
        if (holds(['camouflage','naturalist','navigation','survival','tracking'], skillId)) adjustment += profile.level('outdoorsman');
        if (context.skill.ofKind(RpgLiteSkill) && (context.skill.influence
            || holds(['acting','carousing','leadership','public-speaking'], skillId))) adjustment += profile.level('smooth-operator');
        if (skillId == 'climbing' || skillId == 'escape')
            adjustment += profile.level('double-jointed') > 0 ? 5 : profile.level('flexibility') > 0 ? 3 : 0;
        if (skillId == 'climbing' || skillId == 'acrobatics') adjustment += profile.level('perfect-balance');
        if (skillId == 'climbing' || skillId == 'stealth') adjustment -= profile.encumbrance();
        if (skillId == 'swimming') adjustment -= 2 * profile.encumbrance();
        if (profile.level('truthfulness') > 0 && (skillId == 'fast-talk' || skillId == 'acting' && context.deceptive)) adjustment -= 5;
        if (context.skill.ofKind(RpgLiteSkill))
        {
            if (context.skill.influence || skillId == 'leadership' || skillId == 'public-speaking') adjustment += profile.level('charisma');
            if (context.skill.voice) adjustment += 2 * profile.level('voice');
        }
    }
    local cramped = context.closeQuarters;
    cramped -= profile.level('double-jointed') > 0 ? 5 : profile.level('flexibility') > 0 ? 3 : 0;
    if (cramped > 0) adjustment -= cramped;
    return score + adjustment;
}

/** Resolve a contextual success check, including applicable traits and immediate Luck. */
rpgLiteCheck(profile, context)
{
    local score = rpgLiteScore(profile, context);
    if (score == nil) { local result = new RpgResult(); result.reason = context.unavailableReason(profile); return result; }
    if (score < 3) return rpgCheck(score, 3);
    local result = rpgCheck(score, rpgRandom.roll());
    if (context.reroll(profile, result)) result = rpgCheck(score, rpgLiteReroll(profile, result.roll, 3, nil));
    if (result.critical == 'failure' && context.unnecessaryRisk && profile.level('daredevil') > 0)
        result = rpgCheck(score, rpgRandom.roll());
    profile.lastCheck = result; profile.lastCheckDraw = rpgRandom.draws;
    return result;
}

/** Resolve an attribute check with a named situation and integer modifier. */
rpgLiteAttributeCheck(profile, attribute, kind, modifier)
{
    local context = new RpgLiteContext(); context.attribute = attribute;
    context.kind = kind; context.modifier = modifier;
    return rpgLiteCheck(profile, context);
}

/** Resolve written comprehension; semi-literacy needs an IQ roll and fluent reading is automatic. */
rpgLiteRead(profile, languageId)
{
    local comprehension = profile.language(languageId, true);
    if (comprehension == 1) return rpgLiteAttributeCheck(profile, rpgIQ, 'reading', 0);
    local result = new RpgResult();
    if (comprehension == 0) { result.reason = 'illiterate'; return result; }
    result.status = 'resolved'; result.achieved = true; result.outcome = 'automatic'; return result;
}

/** Resolve a controlled disadvantage against 12, or voluntarily yield without rolling. */
rpgLiteSelfControl(profile, trait, modifier, giveIn)
{
    if (!holds(profile.traits, trait) || !trait.controlled || !trait.active) throw new RpgError();
    local result = giveIn ? new RpgResult() : rpgCheck(12 + modifier - (profile.sleepPenalty ? 2 : 0), rpgRandom.roll());
    if (giveIn) { result.status = 'resolved'; result.achieved = nil; result.outcome = 'yielded'; }
    else { profile.lastCheck = result; profile.lastCheckDraw = rpgRandom.draws; }
    return result;
}

/** Return the signed point cost of an owned trait. */
rpgLiteTraitCost(trait)
{
    if (trait.id == nil || trait.level < 1) throw new RpgError();
    return trait.points * trait.level;
}

/** Return total creation cost, or only negative components when negativeOnly is true. */
rpgLiteCharacterCost(profile, negativeOnly)
{
    local amounts = [(profile.st - 10) * 10, (profile.dx - 10) * 20,
        (profile.iq - 10) * 20, (profile.ht - 10) * 10, (profile.techLevel - profile.campaignTL) * 5];
    foreach (local trait in profile.traits) amounts = amounts + [rpgLiteTraitCost(trait)];
    foreach (local language in profile.languages) amounts = amounts + [language.cost()];
    foreach (local training in profile.skills) amounts = amounts + [training.points];
    local total = 0;
    foreach (local amount in amounts) if (!negativeOnly || amount < 0) total += amount;
    return total;
}

/** Character validation failure with an author-readable reason. */
class RpgLiteCharacterError: RpgError reason = 'invalid-character';

/** Reject an invalid character declaration with a specific diagnostic. */
rpgLiteInvalidCharacter(reason)
{
    local error = new RpgLiteCharacterError(); error.reason = reason; throw error;
}

/** Validate Lite trait identities and mutually exclusive catalogue choices. */
rpgLiteValidateTraits(profile)
{
    local ids = []; local quirks = 0;
    foreach (local trait in profile.traits)
    {
        if (!trait.ofKind(RpgLiteTrait) || trait.id == nil || holds(ids, trait.id) && trait.id != 'quirk') rpgLiteInvalidCharacter('duplicate-or-invalid-trait');
        ids = ids + [trait.id];
        if (trait.id == 'quirk' || trait.scope == 'quirk') quirks += 1;
        if (trait.id == 'night-vision' && trait.level > 9
            || trait.skills.length() > 0 && trait.level > 4) rpgLiteInvalidCharacter('trait-level');
    }
    if (quirks > 5 || profile.level('acute-hearing') > 0 && profile.level('hard-of-hearing') > 0
        || profile.level('luck') > 0 && profile.level('unluckiness') > 0) rpgLiteInvalidCharacter('incompatible-traits');
    foreach (local group in [['hideous','ugly','unattractive','attractive','handsome','very-handsome'],
        ['dead-broke','poor','struggling','comfortable','wealthy','very-wealthy','filthy-rich'],
        ['luck','extraordinary-luck','ridiculous-luck','unluckiness'], ['flexibility','double-jointed'],
        ['bad-sight','bad-sight-correctable'], ['status','low-status'],
        ['resistant-disease-3','resistant-disease-8']])
    {
        local count = 0;
        foreach (local id in group) if (holds(ids, id)) count += 1;
        if (count > 1) rpgLiteInvalidCharacter('exclusive-traits');
    }
    return true;
}

/** Validate the point budget, disadvantage limit, trait combinations, languages and technology. */
rpgLiteValidateCharacter(profile)
{
    rpgInteger(profile.st, 1, 20); rpgInteger(profile.dx, 1, 100);
    rpgInteger(profile.iq, 1, 100); rpgInteger(profile.ht, 1, 100);
    rpgInteger(profile.techLevel, 0, 12); rpgInteger(profile.campaignTL, 0, 12);
    rpgLiteValidateTraits(profile);
    local ids = []; local natives = 0;
    foreach (local language in profile.languages)
    {
        if (language.id == nil || holds(ids, language.id)) rpgLiteInvalidCharacter('duplicate-language');
        ids = ids + [language.id]; rpgInteger(language.spoken, 0, 3); rpgInteger(language.written, 0, 3);
        if (language.native) { natives += 1; if (language.spoken != 3) rpgLiteInvalidCharacter('native-language'); }
    }
    if (natives > 1) rpgLiteInvalidCharacter('multiple-native-languages');
    foreach (local training in profile.skills)
        if (training.points > 0 && training.skill.ofKind(RpgLiteSkill)
            && training.skill.techLevel != nil && training.skill.techLevel > profile.techLevel)
            rpgLiteInvalidCharacter('skill-technology');
    if (rpgLiteCharacterCost(profile, nil) > profile.pointBudget
        || -rpgLiteCharacterCost(profile, true) > profile.disadvantageLimit) rpgLiteInvalidCharacter('point-budget');
    return true;
}

/** Map an already-modified reaction total to its named category. */
rpgLiteReaction(total)
{
    if (total <= 0) return 'disastrous';
    if (total <= 3) return 'very-bad';
    if (total <= 6) return 'bad';
    if (total <= 9) return 'poor';
    if (total <= 12) return 'neutral';
    if (total <= 15) return 'good';
    if (total <= 18) return 'very-good';
    return 'excellent';
}

/** Authored visibility, recognition, culture and attraction facts for reaction modifiers. */
class RpgLiteSocialContext: object
    attracted = nil
    sees = true
    hears = true
    interaction = true
    recognizes = true
    sameCulture = true
    noticesHabits = true
    naive = nil
    experienced = nil
    modifier = 0
    reroll(profile, roll) { return nil; }
;

/** Calculate visible and applicable personal reaction modifiers. */
rpgLiteReactionModifier(profile, context)
{
    local amount = context.modifier;
    if (context.interaction) amount += profile.level('charisma');
    if (context.hears) amount += 2 * profile.level('voice');
    if (context.recognizes)
    {
        local reputation = profile.trait('reputation');
        if (reputation != nil) amount += reputation.points < 0 ? -reputation.level : reputation.level;
        amount -= profile.level('bad-reputation');
    }
    if (context.sameCulture)
    {
        local status = profile.trait('status');
        if (status != nil) amount += status.points < 0 ? -status.level : status.level;
        amount -= profile.level('low-status');
    }
    if (context.noticesHabits) amount -= profile.level('odious-habits') + profile.level('delusions');
    if (context.sees)
    {
        amount -= 4 * profile.level('hideous') + 2 * profile.level('ugly') + profile.level('unattractive');
        amount += profile.level('attractive');
        if (profile.level('handsome') > 0) amount += context.attracted ? 4 : 2;
        if (profile.level('very-handsome') > 0) amount += context.attracted ? 6 : 2;
    }
    if (profile.level('overconfidence') > 0) amount += context.naive ? 2 : context.experienced ? -2 : 0;
    return amount;
}

/** Opposed influence outcome, reaction category and optional ordinary reaction roll. */
class RpgLiteInfluenceResult: object
    contest = nil
    reaction = nil
    reactionRoll = nil
;

/** Resolve influence against Will, including Intimidation, Sex Appeal and Diplomacy exceptions. */
rpgLiteInfluence(profile, target, context, social)
{
    if (context.skill == nil || !context.skill.influence) throw new RpgError();
    local value = new RpgLiteInfluenceResult();
    local score = rpgLiteScore(profile, context);
    if (score == nil || score < 3) return value;
    local resistance = target.will;
    if (context.skill.id == 'intimidation')
    { resistance += target.level('fearlessness'); score -= target.level('fearlessness'); }
    local ownRoll = rpgRandom.roll();
    if (context.reroll(profile, rpgCheck(score, ownRoll))) ownRoll = rpgLiteReroll(profile, ownRoll, 3, nil);
    local otherRoll = rpgRandom.roll();
    value.contest = rpgEvaluate(score, ownRoll, resistance, otherRoll, 0);
    value.reaction = value.contest.achieved ? (context.skill.id == 'sex-appeal' ? 'very-good' : 'good')
        : context.skill.id == 'intimidation' ? 'very-bad' : 'bad';
    if (context.skill.id == 'diplomacy')
    {
        local reactionRoll = rpgRandom.roll();
        if (social.reroll(profile, reactionRoll)) reactionRoll = rpgLiteReroll(profile, reactionRoll, 3, true);
        value.reactionRoll = reactionRoll + rpgLiteReactionModifier(profile, social);
        local floor = value.contest.achieved ? 13 : 4;
        if (value.reactionRoll >= floor) value.reaction = rpgLiteReaction(value.reactionRoll);
    }
    return value;
}

/** Persistent repeated success-versus-failure contest, with author-selected seconds per round. */
class RpgLiteRegularContest: object
    finished = nil
    winner = nil
    rounds = 0
    seconds = 1
    step(firstScore, secondScore)
    {
        if (self.finished) return self.winner;
        if (firstScore < 3 || secondScore < 3) throw new RpgError();
        local first = rpgCheck(firstScore, rpgRandom.roll());
        local second = rpgCheck(secondScore, rpgRandom.roll());
        self.rounds += 1; rpgSpendTime(self.seconds);
        if (first.achieved != second.achieved)
        { self.finished = true; self.winner = first.achieved ? 1 : 2; }
        return self.winner;
    }
;
