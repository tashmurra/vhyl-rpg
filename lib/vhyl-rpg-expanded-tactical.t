/* Include after expanded foundation. Source: full-2008 B384-B385.
 * Coordinates are a library convention, not an additional movement rule. */

/** Axial grid coordinate, bounded to keep difference arithmetic exact. */
class RpgExpandedHex: object
    q = 0
    r = 0
    validate()
    {
        rpgInteger(self.q,-1000000,1000000);
        rpgInteger(self.r,-1000000,1000000);
        return nil;
    }
;

/** Construct a coordinate without installing a figure or spending time. */
rpgExpandedHex(q, r)
{
    local cell = new RpgExpandedHex(); cell.q = q; cell.r = r;
    cell.validate(); return cell;
}

/** Geometric yard distance on the grid; excludes terrain and movement costs. */
rpgExpandedHexDistance(from, to)
{
    if (from == nil || to == nil || !from.ofKind(RpgExpandedHex) || !to.ofKind(RpgExpandedHex))
        rpgExpandedReject('tactical-coordinate');
    from.validate(); to.validate();
    local dq = to.q - from.q; local dr = to.r - from.r; local ds = dq + dr;
    if (dq < 0) dq = -dq;
    if (dr < 0) dr = -dr;
    if (ds < 0) ds = -ds;
    return dq > dr ? (dq > ds ? dq : ds) : (dr > ds ? dr : ds);
}

/** Clockwise headings 0..5: east, southeast, southwest, west, northwest, northeast. */
rpgExpandedHexNeighbor(from, heading)
{
    if (from == nil || !from.ofKind(RpgExpandedHex)) rpgExpandedReject('tactical-coordinate');
    from.validate(); rpgInteger(heading,0,5);
    local directions = [[1,0],[0,1],[-1,1],[-1,0],[0,-1],[1,-1]];
    local offset = directions[heading + 1];
    return rpgExpandedHex(from.q + offset[1],from.r + offset[2]);
}

/** Relative classification of one adjacent direction, B385. */
rpgExpandedFacingSide(facing, heading)
{
    rpgInteger(facing,0,5); rpgInteger(heading,0,5);
    local relative = heading - facing;
    if (relative < 0) relative += 6;
    if (relative == 0 || relative == 1 || relative == 5) return 'front';
    if (relative == 2) return 'right';
    if (relative == 4) return 'left';
    return 'back';
}

/** Pure adjacent-target assessment. Handedness assigns side labels, not defenses. */
class RpgExpandedFacingAssessment: object
    origin = nil
    target = nil
    facing = 0
    handedness = 'right'
    assess()
    {
        local distance = rpgExpandedHexDistance(self.origin,self.target);
        rpgInteger(self.facing,0,5);
        if (!holds(['left','right'],self.handedness)) rpgExpandedReject('tactical-handedness');
        local value = new RpgExpandedFacingResult();
        if (distance != 1) { value.reason = 'tactical-adjacent-required'; return value; }
        local directions = [[1,0],[0,1],[-1,1],[-1,0],[0,-1],[1,-1]];
        for (local heading = 0; heading < 6; heading += 1)
        {
            local offset = directions[heading + 1];
            if (self.target.q - self.origin.q == offset[1]
                && self.target.r - self.origin.r == offset[2])
            {
                value.heading = heading; value.side = rpgExpandedFacingSide(self.facing,heading);
                value.weaponSide = value.side == self.handedness;
                value.shieldSide = value.side == (self.handedness == 'right' ? 'left' : 'right');
                value.status = 'ready'; return value;
            }
        }
        rpgExpandedReject('tactical-coordinate');
    }
;

/** Geometric assessment only; does not imply sight, attack legality or occupancy. */
class RpgExpandedFacingResult: RpgExpandedResult
    heading = nil
    side = nil
    weaponSide = nil
    shieldSide = nil
;

/** Authored barrier facts for one hex. Partial obstruction is ordinarily usable;
 * a contrary author ruling requires its concrete evidence, B385. */
class RpgExpandedHexTerrain: object
    coordinate = nil
    barrier = 'none'
    partialAllowed = true
    rulingEvidence = nil
    assess()
    {
        if (self.coordinate == nil || !self.coordinate.ofKind(RpgExpandedHex))
            rpgExpandedReject('tactical-coordinate');
        self.coordinate.validate();
        if (!holds(['none','partial','solid'],self.barrier)) rpgExpandedReject('tactical-barrier');
        local value = new RpgExpandedResult();
        if (self.barrier == 'solid') { value.reason = 'tactical-solid-barrier'; return value; }
        if (self.barrier == 'partial' && !self.partialAllowed)
        {
            if (self.rulingEvidence == nil || self.rulingEvidence == '')
                rpgExpandedReject('tactical-partial-ruling-evidence');
            value.reason = 'tactical-partial-barrier-ruling'; return value;
        }
        value.status = 'ready'; return value;
    }
;
