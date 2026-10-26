/* Relationships and authored other-world content, without setting taxonomy. */
class RpgMagicRelationship: object
    spirit = nil
    strength = 1
    disposition = nil
    familiarity = 0
    obligations = 0
    identified = nil
    incidents = []
    contactMargin()
    {
        rpgInteger(self.strength,1,5); rpgInteger(self.familiarity,0,2); rpgInteger(self.obligations,-2,2);
        local attitude = self.disposition == nil ? 0 : self.disposition.attitude;
        rpgInteger(attitude,-3,3); local n = 2 * self.strength - attitude - self.familiarity - self.obligations;
        return n < 0 ? 0 : n;
    }
    permits(actor,approach)
    { return self.disposition != nil && self.disposition.permits(actor,approach); }
;

/** Contact is neither arrival nor obedience. Apply social requests separately. */
rpgContactMagicSpirit(relationship,state,margin,visible)
{
    if (!relationship.identified || !visible || rpgMagicSkill(state,rpgMagicSpirits,2) == nil
        || margin < relationship.contactMargin()) return nil;
    relationship.spirit.contacted = true; return true;
}

/** Idempotent relationship change uses the same bounded attitude scale as people. */
rpgMagicSpiritIncident(relationship,id,change)
{
    rpgInteger(change,-6,6);
    if (holds(relationship.incidents,id)) return nil;
    if (relationship.disposition == nil) rpgExpandedReject('magic-relationship-disposition');
    local n = relationship.disposition.attitude + change;
    relationship.disposition.attitude = n < -3 ? -3 : n > 3 ? 3 : n;
    relationship.incidents = relationship.incidents + [id]; return nil;
}

/** Fixed spirit powers pay severe injury instead of accumulating casting strain. */
rpgMagicSpiritPowerCost(spirit,strain)
{
    rpgInteger(strain,0,1000); local injury = 0;
    for (local i = 0; i < strain; i++) injury += rpgRandom.die();
    return rpgMagicWound(spirit,injury,'severe',nil);
}

/** Materialization thresholds are distinct from a caster's boundary contest. */
rpgMagicCanMaterialize(strength,barrier)
{ return strength == 1 ? barrier <= 8 : strength == 2 ? barrier <= 12 : strength >= 3 && barrier < 18; }

/** Effective boundary includes owned timed layers, clamped to the authored scale. */
rpgMagicBarrier(subject)
{
    local n = subject.location.barrier + rpgMagicOverlayValue(subject,'boundary');
    return n < 0 ? 0 : n > 18 ? 18 : n;
}

class RpgMagicFalsePerception: object
    id = nil
    description = ''
    checked = nil
    recognized = nil
    conviction = nil
;
class RpgMagicPerceptionEpisode: object
    owner = nil
    elements = []
    intuition = nil
    active = true
;

/** Each authored false element gets one recognition attempt, never a world mutation. */
rpgRecognizeMagicPerception(episode,element)
{
    if (!episode.active || !holds(episode.elements,element)) rpgExpandedReject('magic-perception-element');
    if (element.checked) return element.recognized;
    element.checked = true;
    local check = rpgCheck(episode.owner.owner.attributeScore(rpgIQ) - (episode.intuition ? 0 : 3),rpgRandom.roll());
    element.recognized = check.rollSucceeded; element.conviction = check.critical == 'failure'; return element.recognized;
}

/** Internal encounters advance their authored narrative; they never restore saves. */
rpgMagicInternalDuration(margin,succeeded)
{
    if (!succeeded || margin <= 0) return 31536000;
    return margin == 1 ? 2592000 : margin == 2 ? 604800 : margin <= 5 ? 86400 : margin == 6 ? 3600 : margin == 7 ? 60 : 1;
}
