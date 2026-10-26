/* Authored mental information and links preserve objective world state. */
class RpgMagicLink: object
    owner = nil
    members = []
    categories = []
    layer = nil
;
modify RpgMagicSubject
    links = []
    memories = []
    projectionRecovery = 0
;
modify RpgMagicOngoing
    content = []
;
modify RpgMagicOperation
    content = []
    categories = []
;

/** Disclosure requires current membership and an explicitly permitted category. */
rpgReadMagicLink(link,member,category)
{
    if (link.layer == nil || !link.layer.active || !holds(link.members,member) || !holds(link.categories,category)) return [];
    local facts = [];
    foreach (local subject in link.members)
        foreach (local entry in subject.observations) if (entry[1] == category) facts = facts + [[subject.id,entry]];
    return facts;
}

/** Memory overlays suppress or add accessible beliefs; underlying records remain. */
rpgMagicRemember(subject)
{
    local additions = []; local suppressed = [];
    foreach (local e in subject.world.effects)
        if (e.active && e.target == subject && e.key == 'memory')
            foreach (local entry in e.content)
            { if (entry[1] == 'suppress') suppressed = suppressed + [entry[2]];
              else if (entry[1] == 'add') additions = additions + [[entry[2],entry[3]]]; }
    local memories = [];
    foreach (local entry in subject.memories) if (!holds(suppressed,entry[1])) memories = memories + [entry];
    return memories + additions;
}

/** Reversal contests the original casting skill; no deletion of original memories. */
rpgReverseMagicMemory(layer,score)
{
    if (!layer.active || layer.key != 'memory' || layer.result == nil) return nil;
    local a = rpgCheck(score,rpgRandom.roll());
    local d = rpgCheck(layer.result.score,rpgRandom.roll());
    if (!a.rollSucceeded || d.rollSucceeded && d.margin >= a.margin) return nil;
    rpgMagicEndEffect(layer); return true;
}

/** Projection uses a mental body; ordinary physical senses are not provided. */
rpgMagicProjectedAttribute(subject,attribute)
{
    if (subject.projected == nil || !subject.projected.active) rpgExpandedReject('magic-not-projected');
    return attribute == rpgST || attribute == rpgDX ? subject.profile.attributeScore(rpgIQ)
        : attribute == rpgHT ? subject.profile.attributeScore(rpgWill) : subject.profile.attributeScore(attribute);
}
rpgMagicProjectionInjury(subject,amount)
{
    rpgInteger(amount,0,10000);
    if (subject.projected == nil) rpgExpandedReject('magic-not-projected');
    subject.spiritHealth -= amount;
    if (subject.spiritHealth <= 0) { subject.spiritHealth = 0; subject.bodyLink = nil; }
    return subject.spiritHealth;
}
rpgMagicShowProjection(subject)
{
    if (subject.projected == nil) return nil;
    if (!rpgCheck(subject.profile.attributeScore(rpgWill),rpgRandom.roll()).rollSucceeded) return nil;
    rpgMagicLayer(subject.magic,subject,'projection-visible',1,60,nil); return true;
}
modify RpgMagicSubject
    bodyLink = true
;

modify RpgMagicState
    permanentBenefits = []
    amounts(profile)
    {
        local prices = inherited(profile);
        foreach (local benefit in self.permanentBenefits) prices = prices + [benefit[2]];
        return prices;
    }
;

/** Lasting selected mental benefits retain a paid point contribution. */
rpgMagicPurchaseBenefit(state,property,amount)
{
    if (!property.mental || !property.permanent || property.points <= 0
        || holds(['will','empathy','psychic'],property.id) || state.owner.unspentPoints < property.points)
        rpgExpandedReject('magic-permanent-benefit');
    state.owner.unspentPoints -= property.points;
    state.permanentBenefits = state.permanentBenefits + [[property.id,property.points]];
    return rpgMagicLayer(state,state.subject,property.id,amount,-1,nil);
}
