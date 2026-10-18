/* Include after expanded foundation. Source: full-2008 B384-B387.
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

/** Minimum number of hex-side turns between two headings. */
rpgExpandedFacingDistance(from, to)
{
    rpgInteger(from,0,5); rpgInteger(to,0,5);
    local distance = to - from;
    if (distance < 0) distance = -distance;
    return distance > 3 ? 6 - distance : distance;
}

/** B385-B386 movement allowance; the committed attack's two-hex option is
 * retained separately because a hex allowance is not a terrain-point budget. */
rpgExpandedMovementAllowance(move, maneuver)
{
    rpgInteger(move,0,1000);
    if (!holds(['move','move-attack','committed-attack','increased-dodge'],maneuver))
        rpgExpandedReject('tactical-movement-maneuver');
    local value = new RpgExpandedMovementResult();
    value.halfPoints = (maneuver == 'move' || maneuver == 'move-attack')
        ? move * 2 : ((move + 1) / 2) * 2;
    value.alternativeHexes = maneuver == 'committed-attack' ? 2 : 0;
    value.status = 'ready'; return value;
}

/** Movement values use half-points so crouching never loses fractional cost.
 * An allowance and an entry cost share this result type but not their meaning. */
class RpgExpandedMovementResult: RpgExpandedResult
    halfPoints = 0
    alternativeHexes = 0
    heading = nil
    wholeAllowance = nil
;

/** B386-B387 cost and heading for a single adjacent entry. It does not certify
 * occupancy, remaining movement, interrupts, evasion or the whole path. */
class RpgExpandedHexEntry: object
    origin = nil
    target = nil
    facing = 0
    maneuver = 'move'
    travel = 'forward'
    posture = 'standing'
    terrain = nil
    minorObstructions = 0
    severeObstruction = nil
    enemyPresent = nil
    treacherous = nil
    footingExtra = 1
    footingEvidence = nil
    stairs = nil
    water = 'none'
    assess()
    {
        local value = new RpgExpandedMovementResult();
        if (!holds(['move','move-attack','committed-attack','increased-dodge'],self.maneuver))
            rpgExpandedReject('tactical-movement-maneuver');
        if (!holds(['forward','sidestep'],self.travel)) rpgExpandedReject('tactical-travel-mode');
        if (!holds(['standing','crouching','kneeling','crawling','lying','sitting'],self.posture))
            rpgExpandedReject('tactical-posture');
        if (!holds(['none','shallow','deep'],self.water)) rpgExpandedReject('tactical-water');
        rpgInteger(self.minorObstructions,0,1000); rpgInteger(self.footingExtra,1,1000);
        if (self.treacherous && self.footingExtra > 1
            && (self.footingEvidence == nil || self.footingEvidence == ''))
            rpgExpandedReject('tactical-footing-evidence');
        local direction = new RpgExpandedFacingAssessment();
        direction.origin = self.origin; direction.target = self.target; direction.facing = self.facing;
        local facingResult = direction.assess();
        if (facingResult.status != 'ready') { value.reason = facingResult.reason; return value; }
        if (self.terrain == nil || !self.terrain.ofKind(RpgExpandedHexTerrain))
            rpgExpandedReject('tactical-terrain-required');
        local terrainResult = self.terrain.assess();
        if (rpgExpandedHexDistance(self.target,self.terrain.coordinate) != 0)
            rpgExpandedReject('tactical-terrain-target');
        if (terrainResult.status != 'ready') { value.reason = terrainResult.reason; return value; }
        if (self.posture == 'sitting') { value.reason = 'tactical-sitting'; return value; }
        if (self.severeObstruction) { value.reason = 'tactical-jump-required'; return value; }
        if (self.enemyPresent) { value.reason = 'tactical-evasion-required'; return value; }
        if (self.travel == 'forward' && facingResult.side != 'front')
        { value.reason = 'tactical-forward-direction'; return value; }
        if (self.maneuver == 'committed-attack' && facingResult.side != 'front')
        { value.reason = 'tactical-committed-direction'; return value; }
        value.heading = self.travel == 'forward' ? facingResult.heading : self.facing;
        value.halfPoints = self.travel == 'forward' ? 2 : 4;
        if (self.posture == 'crouching') value.halfPoints += 1;
        if (self.posture == 'kneeling' || self.posture == 'crawling') value.halfPoints += 4;
        value.halfPoints += self.minorObstructions * 2;
        if (self.treacherous) value.halfPoints += self.footingExtra * 2;
        if (self.stairs) value.halfPoints += 2;
        if (self.water == 'shallow') value.halfPoints += 2;
        if (self.posture == 'lying' || self.water == 'deep')
        {
            /* Whole-allowance cases are not an additive numeric entry cost. */
            value.wholeAllowance = true; value.halfPoints = 0;
        }
        value.status = 'ready'; return value;
    }
;

/** Paid turn before/during movement; committed attack needs its separate
 * stationary-turn procedure and cannot borrow this moving-turn rule. */
rpgExpandedMovementTurn(facing, targetFacing, maneuver)
{
    local sides = rpgExpandedFacingDistance(facing,targetFacing);
    local value = new RpgExpandedMovementResult();
    if (!holds(['move','move-attack','committed-attack','increased-dodge'],maneuver))
        rpgExpandedReject('tactical-movement-maneuver');
    if (maneuver == 'committed-attack')
    { value.reason = 'tactical-committed-turn-procedure'; return value; }
    value.halfPoints = sides * 2; value.heading = targetFacing; value.status = 'ready'; return value;
}

/** B387 free final turn; spentHalfPoints includes all paid path costs.
 * Increased dodge retains its explicit exception to the half-budget restriction. */
rpgExpandedFinalFacing(facing, targetFacing, maneuver, allowanceHalfPoints, spentHalfPoints)
{
    local sides = rpgExpandedFacingDistance(facing,targetFacing);
    rpgInteger(allowanceHalfPoints,0,2000); rpgInteger(spentHalfPoints,0,1000000);
    if (!holds(['move','move-attack','committed-attack','increased-dodge'],maneuver))
        rpgExpandedReject('tactical-movement-maneuver');
    local value = new RpgExpandedMovementResult();
    if (maneuver == 'committed-attack' && sides > 0)
    { value.reason = 'tactical-committed-final-facing'; return value; }
    if ((maneuver == 'move' || maneuver == 'move-attack')
        && spentHalfPoints * 2 > allowanceHalfPoints && sides > 1)
    { value.reason = 'tactical-final-facing-limit'; return value; }
    value.heading = targetFacing; value.status = 'ready'; return value;
}

modify RpgExpandedProfile
    tacticalFigure = nil
;

/** Finite authored encounter map. Missing cells are unknown, never open terrain. */
class RpgExpandedTacticalMap: object
    id = nil
    cells = []
    figures = []
    placements = []
    validate()
    {
        if (self.id == nil || self.id == '') rpgExpandedReject('tactical-map-id');
        local seen = [];
        foreach (local cell in self.cells)
        {
            if (cell == nil || !cell.ofKind(RpgExpandedHexTerrain)) rpgExpandedReject('tactical-map-cell');
            cell.assess();
            foreach (local prior in seen)
                if (rpgExpandedHexDistance(prior.coordinate,cell.coordinate) == 0)
                    rpgExpandedReject('tactical-map-duplicate-cell');
            seen = seen + [cell];
        }
        local profiles = []; local ids = [];
        foreach (local figure in self.figures)
        {
            if (figure == nil || !figure.ofKind(RpgExpandedTacticalFigure)
                || figure.map != self || figure.profile == nil
                || !figure.profile.ofKind(RpgExpandedProfile)
                || figure.profile.tacticalFigure != figure || figure.placement == nil
                || !holds(self.placements,figure.placement) || figure.placement.result == nil
                || figure.placement.figure != figure || figure.placement.map != self)
                rpgExpandedReject('tactical-figure-ownership');
            if (holds(ids,figure.id) || holds(profiles,figure.profile))
                rpgExpandedReject('tactical-duplicate-figure');
            ids = ids + [figure.id]; profiles = profiles + [figure.profile];
            if (figure.coordinate == nil || !figure.coordinate.ofKind(RpgExpandedHex))
                rpgExpandedReject('tactical-figure-coordinate');
            local definition = figure.placement.definition();
            for (local index = 1; index <= definition.length(); index += 1)
                if (definition[index] != figure.placement.boundDefinition[index])
                    rpgExpandedReject('tactical-placement-binding');
            figure.coordinate.validate(); rpgInteger(figure.facing,0,5);
        }
        return nil;
    }
    cellAt(coordinate)
    {
        if (coordinate == nil || !coordinate.ofKind(RpgExpandedHex)) rpgExpandedReject('tactical-coordinate');
        coordinate.validate();
        foreach (local cell in self.cells)
            if (rpgExpandedHexDistance(cell.coordinate,coordinate) == 0) return cell;
        return nil;
    }
    occupancy(coordinate)
    {
        self.validate();
        local value = new RpgExpandedOccupancyResult();
        local cell = self.cellAt(coordinate);
        if (cell == nil) { value.reason = 'tactical-unmapped-cell'; return value; }
        local terrainResult = cell.assess();
        if (terrainResult.status != 'ready') { value.reason = terrainResult.reason; return value; }
        foreach (local figure in self.figures)
        {
            /* A changed body/posture can extend beyond its stored origin. Until
             * that footprint is resolved, no apparently empty destination is safe. */
            if (figure.footprintReason() != nil)
            { value.reason = figure.footprintReason(); return value; }
            if (rpgExpandedHexDistance(figure.coordinate,coordinate) == 0)
                value.occupants = value.occupants + [figure];
        }
        value.status = 'ready'; return value;
    }
;

/** A figure shares its character's posture and health; only geometry lives here. */
class RpgExpandedTacticalFigure: object
    id = nil
    profile = nil
    map = nil
    coordinate = nil
    facing = 0
    bodyForm = 'upright-human'
    placement = nil
    footprintReason()
    {
        if (self.bodyForm != 'upright-human') return 'tactical-body-form-unimplemented';
        if (!holds(['standing','crouching','kneeling','sitting'],self.profile.posture))
            return 'tactical-footprint-transition-required';
        return nil;
    }
;

/** Pure occupancy result. Sharing a cell requires a separate explicit procedure. */
class RpgExpandedOccupancyResult: RpgExpandedResult
    occupants = []
;

/** Encounter setup placement, not a movement or teleport action. It records the
 * initial authored position once without spending combat time or resources. */
class RpgExpandedTacticalPlacement: object
    id = nil
    map = nil
    figure = nil
    coordinate = nil
    facing = 0
    approved = nil
    evidence = nil
    result = nil
    boundDefinition = nil
    definition()
    {
        return [self.id,self.map,self.figure,self.figure.id,self.figure.profile,
            self.figure.bodyForm,self.coordinate.q,self.coordinate.r,self.facing,self.approved,self.evidence];
    }
    assess()
    {
        if (self.id == nil || self.id == '' || self.map == nil || !self.map.ofKind(RpgExpandedTacticalMap)
            || self.figure == nil || !self.figure.ofKind(RpgExpandedTacticalFigure)
            || self.figure.id == nil || self.figure.id == '' || self.figure.profile == nil
            || !self.figure.profile.ofKind(RpgExpandedProfile)
            || self.coordinate == nil || !self.coordinate.ofKind(RpgExpandedHex))
            rpgExpandedReject('tactical-placement-definition');
        self.coordinate.validate(); rpgInteger(self.facing,0,5);
        local value = new RpgExpandedResult();
        if (self.result != nil)
        {
            local current = self.definition();
            for (local index = 1; index <= current.length(); index += 1)
                if (current[index] != self.boundDefinition[index]) rpgExpandedReject('tactical-placement-binding');
            self.map.validate();
            if (!holds(self.map.placements,self) || !holds(self.map.figures,self.figure)
                || self.figure.placement != self) rpgExpandedReject('tactical-placement-history');
            value.status = 'reused'; return value;
        }
        rpgExpandedValidate(self.figure.profile); self.map.validate();
        if (!self.approved || self.evidence == nil || self.evidence == '')
        { value.reason = 'tactical-placement-evidence'; return value; }
        if (self.figure.map != nil || self.figure.placement != nil || self.figure.profile.tacticalFigure != nil)
        { value.reason = 'tactical-already-placed'; return value; }
        value.reason = self.figure.footprintReason(); if (value.reason != nil) return value;
        foreach (local prior in self.map.placements)
            if (prior.id == self.id) rpgExpandedReject('tactical-placement-duplicate');
        foreach (local prior in self.map.figures)
            if (prior.id == self.figure.id) rpgExpandedReject('tactical-duplicate-figure');
        local occupancy = self.map.occupancy(self.coordinate);
        if (occupancy.status != 'ready') { value.reason = occupancy.reason; return value; }
        if (occupancy.occupants.length() != 0)
        { value.reason = 'tactical-shared-cell-procedure-required'; return value; }
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        self.boundDefinition = self.definition();
        /* Copy coordinates: mutating a setup request cannot move its figure. */
        self.figure.coordinate = rpgExpandedHex(self.coordinate.q,self.coordinate.r);
        self.figure.facing = self.facing; self.figure.map = self.map; self.figure.placement = self;
        self.figure.profile.tacticalFigure = self.figure;
        self.map.figures = self.map.figures + [self.figure]; self.map.placements = self.map.placements + [self];
        value.status = 'resolved'; self.result = value; return value;
    }
;
