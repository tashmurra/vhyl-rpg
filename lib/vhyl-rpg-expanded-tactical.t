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
    obstructionReason() { return self.severeObstruction ? 'tactical-jump-required' : nil; }
    extraEntryHalfPoints() { return 0; }
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
        value.reason = self.obstructionReason(); if (value.reason != nil) return value;
        if (self.enemyPresent) { value.reason = 'tactical-evasion-required'; return value; }
        if (self.travel == 'forward' && facingResult.side != 'front')
        { value.reason = 'tactical-forward-direction'; return value; }
        if (self.maneuver == 'committed-attack' && facingResult.side != 'front')
        { value.reason = 'tactical-committed-direction'; return value; }
        value.heading = self.travel == 'forward' ? facingResult.heading : self.facing;
        value.halfPoints = (self.travel == 'forward' ? 2 : 4) + self.extraEntryHalfPoints();
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
            foreach (local occupied in figure.occupiedCells())
                if (rpgExpandedHexDistance(occupied,coordinate) == 0)
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
    upperCoordinate = nil
    footprintChanges = []
    footprintReason()
    {
        if (self.bodyForm != 'upright-human') return 'tactical-body-form-unimplemented';
        if (self.profile.posture == 'lying')
        {
            if (self.upperCoordinate == nil) return 'tactical-footprint-transition-required';
            if (rpgExpandedHexDistance(self.coordinate,self.upperCoordinate) != 1)
                return 'tactical-footprint-adjacency';
            return nil;
        }
        if (!holds(['standing','crouching','kneeling','sitting'],self.profile.posture)
            || self.upperCoordinate != nil) return 'tactical-footprint-transition-required';
        return nil;
    }
    occupiedCells()
    {
        local reason = self.footprintReason();
        if (reason != nil) rpgExpandedReject(reason);
        return self.upperCoordinate == nil ? [self.coordinate] : [self.coordinate,self.upperCoordinate];
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
        if (self.figure.upperCoordinate != nil || self.figure.profile.posture == 'lying')
        { value.reason = 'tactical-footprint-transition-required'; return value; }
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


/** Geometry reconciliation after a separately executed posture change. The
 * caller owns that action's cost and transaction; this operation charges none. */
class RpgExpandedFootprintChange: object
    id = nil
    figure = nil
    selected = nil
    posture = 'lying'
    approved = nil
    evidence = nil
    result = nil
    boundDefinition = nil
    definition()
    {
        return [self.id,self.figure,self.figure.map,self.figure.profile,self.posture,
            self.selected.q,self.selected.r,self.approved,self.evidence];
    }
    assess() { return self.assessForPosture(nil); }
    assessTransition() { return self.assessForPosture(self.posture); }
    assessForPosture(anticipated)
    {
        if (self.id == nil || self.id == '' || self.figure == nil
            || !self.figure.ofKind(RpgExpandedTacticalFigure) || self.figure.map == nil
            || !self.figure.map.ofKind(RpgExpandedTacticalMap) || self.selected == nil
            || !self.selected.ofKind(RpgExpandedHex)) rpgExpandedReject('tactical-footprint-definition');
        self.selected.validate(); self.figure.map.validate();
        if (!holds(self.figure.map.figures,self.figure)) rpgExpandedReject('tactical-figure-ownership');
        local value = new RpgExpandedResult();
        if (self.result != nil)
        {
            local current = self.definition();
            for (local index = 1; index <= current.length(); index += 1)
                if (current[index] != self.boundDefinition[index]) rpgExpandedReject('tactical-footprint-binding');
            if (!holds(self.figure.footprintChanges,self)) rpgExpandedReject('tactical-footprint-history');
            value.status = 'reused'; return value;
        }
        if (!self.approved || self.evidence == nil || self.evidence == '')
        { value.reason = 'tactical-footprint-evidence'; return value; }
        if (self.figure.bodyForm != 'upright-human')
        { value.reason = 'tactical-body-form-unimplemented'; return value; }
        if ((anticipated == nil ? self.figure.profile.posture : anticipated) != self.posture)
        { value.reason = 'tactical-posture-not-committed'; return value; }
        foreach (local prior in self.figure.footprintChanges)
            if (prior.id == self.id) rpgExpandedReject('tactical-footprint-duplicate');
        local targets = [];
        if (self.posture == 'lying')
        {
            if (self.figure.upperCoordinate != nil)
            { value.reason = 'tactical-footprint-already-lying'; return value; }
            if (rpgExpandedHexDistance(self.figure.coordinate,self.selected) != 1)
            { value.reason = 'tactical-footprint-adjacency'; return value; }
            targets = [self.figure.coordinate,self.selected];
        }
        else if (holds(['standing','crouching','kneeling','sitting'],self.posture))
        {
            if (self.figure.upperCoordinate == nil)
            { value.reason = 'tactical-footprint-not-lying'; return value; }
            if (rpgExpandedHexDistance(self.figure.coordinate,self.selected) != 0
                && rpgExpandedHexDistance(self.figure.upperCoordinate,self.selected) != 0)
            { value.reason = 'tactical-rise-outside-footprint'; return value; }
            targets = [self.selected];
        }
        else { value.reason = 'tactical-posture-footprint-unimplemented'; return value; }
        foreach (local target in targets)
        {
            local cell = self.figure.map.cellAt(target);
            if (cell == nil) { value.reason = 'tactical-unmapped-cell'; return value; }
            local terrain = cell.assess();
            if (terrain.status != 'ready') { value.reason = terrain.reason; return value; }
            foreach (local other in self.figure.map.figures)
                if (other != self.figure)
                {
                    value.reason = other.footprintReason(); if (value.reason != nil) return value;
                    foreach (local occupied in other.occupiedCells())
                        if (rpgExpandedHexDistance(target,occupied) == 0)
                        { value.reason = 'tactical-shared-cell-procedure-required'; return value; }
                }
        }
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        self.boundDefinition = self.definition();
        if (self.posture == 'lying') self.figure.upperCoordinate = rpgExpandedHex(self.selected.q,self.selected.r);
        else
        {
            self.figure.coordinate = rpgExpandedHex(self.selected.q,self.selected.r);
            self.figure.upperCoordinate = nil;
        }
        self.figure.footprintChanges = self.figure.footprintChanges + [self];
        value.status = 'resolved'; self.result = value; return value;
    }
;


/** Atomic posture/geometry adapter for the existing battle scheduler. Only
 * Supported footprints compose with an optional expanded health permission adapter. */
class RpgExpandedPostureManeuver: RpgLiteManeuver
    kind = 'posture'
    battle = nil
    figure = nil
    footprint = nil
    healthPermission = nil
    completed = nil
    available(fighter)
    {
        if (self.battle == nil || !self.battle.ofKind(RpgLiteBattle)
            || self.figure == nil || !self.figure.ofKind(RpgExpandedTacticalFigure)
            || self.figure.profile != fighter.profile || self.figure.map == nil)
            rpgExpandedReject('tactical-posture-maneuver');
        if (self.completed) return 'tactical-posture-maneuver-used';
        if (self.battle.current() != fighter) return 'not-your-turn';
        if (self.kind != 'posture' || self.movement != 0) return 'tactical-posture-movement';
        self.figure.map.validate();
        if (!holds(self.figure.map.figures,self.figure)) rpgExpandedReject('tactical-figure-ownership');
        local reason = self.figure.footprintReason(); if (reason != nil) return reason;
        if (!holds(['standing','kneeling','sitting','lying'],self.posture))
            return 'tactical-posture-maneuver-unimplemented';
        if (self.posture == fighter.profile.posture) return 'tactical-posture-unchanged';
        if (fighter.profile.posture == 'lying' && self.posture == 'standing') return 'invalid-posture-change';
        if (self.healthPermission == nil && (fighter.profile.hp() <= 0 || fighter.profile.fp() <= 0))
            return 'tactical-posture-health-permission-required';
        if (self.posture == 'lying' || fighter.profile.posture == 'lying')
        {
            if (self.footprint == nil || !self.footprint.ofKind(RpgExpandedFootprintChange)
                || self.footprint.figure != self.figure || self.footprint.posture != self.posture)
                return 'tactical-posture-footprint-required';
            if (self.footprint.result != nil) return 'tactical-posture-footprint-used';
            local assessment = self.footprint.assessTransition();
            if (assessment.status != 'ready') return assessment.reason;
        }
        else if (self.footprint != nil) return 'tactical-posture-unexpected-footprint';
        return inherited(fighter);
    }
    healthAvailable(fighter)
    {
        if (self.healthPermission == nil)
        {
            if (fighter.profile.hp() <= 0 || fighter.profile.fp() <= 0)
                return 'tactical-posture-health-permission-required';
            return inherited(fighter);
        }
        if (self.healthPermission == self || !self.healthPermission.ofKind(RpgLiteManeuver)
            || !self.healthPermission.expandedHealthPermission || self.healthPermission.kind != 'posture')
            rpgExpandedReject('tactical-posture-health-adapter');
        return self.healthPermission.healthAvailable(fighter);
    }
    canAct(fighter)
    {
        local reason = self.healthAvailable(fighter);
        if (reason != nil) rpgExpandedReject(reason);
        return self.healthPermission == nil ? inherited(fighter) : self.healthPermission.canAct(fighter);
    }
    apply(fighter, result)
    {
        if (result.status != 'resolved' || result.outcome != 'posture'
            || fighter.profile != self.figure.profile || fighter.profile.posture != self.posture)
            rpgExpandedReject('tactical-posture-not-resolved');
        if (self.footprint != nil)
        {
            local value = self.footprint.apply();
            if (value.status != 'resolved') rpgExpandedReject('tactical-posture-footprint-changed');
        }
        self.completed = true; return inherited(fighter,result);
    }
;

modify RpgExpandedHexTerrain
    minorObstructions = 0
    severeObstruction = nil
    treacherous = nil
    footingExtra = 1
    footingEvidence = nil
    stairs = nil
    water = 'none'
;

/** One ordered path instruction: either an in-place turn or an adjacent entry. */
class RpgExpandedPathLeg: object
    kind = 'entry'
    destination = nil
    travel = 'forward'
    heading = 0
;

/** Complete assessed path values; no position or clock has been committed. */
class RpgExpandedPathResult: RpgExpandedMovementResult
    destination = nil
    allowanceHalfPoints = 0
    enteredHexes = 0
    minimumProgress = nil
    stages = []
;

/** Pure single-hex path assessment, B385-B387. Move is the verified allowance
 * before posture costs, not the posture-reduced abridged move() value. */
class RpgExpandedMovementPath: object
    figure = nil
    move = 0
    maneuver = 'move'
    legs = []
    allies = []
    finalFacing = nil
    assess()
    {
        local value = new RpgExpandedPathResult();
        if (self.figure == nil || !self.figure.ofKind(RpgExpandedTacticalFigure)
            || self.figure.map == nil || !self.figure.map.ofKind(RpgExpandedTacticalMap))
            rpgExpandedReject('tactical-path-figure');
        self.figure.map.validate();
        if (!holds(self.figure.map.figures,self.figure)) rpgExpandedReject('tactical-figure-ownership');
        value.reason = self.figure.footprintReason(); if (value.reason != nil) return value;
        if (self.figure.upperCoordinate != nil) { value.reason = 'tactical-multi-hex-path-unimplemented'; return value; }
        if (self.figure.profile.dead || self.figure.profile.unconscious)
        { value.reason = 'tactical-path-incapacity'; return value; }
        if (self.figure.profile.posture == 'sitting') { value.reason = 'tactical-sitting'; return value; }
        local allowance = rpgExpandedMovementAllowance(self.move,self.maneuver);
        if (self.maneuver == 'committed-attack')
        { value.reason = 'tactical-committed-path-unimplemented'; return value; }
        rpgInteger(self.legs.length(),0,1000);
        local seen = [];
        foreach (local ally in self.allies)
        {
            if (ally == self.figure || !holds(self.figure.map.figures,ally) || holds(seen,ally))
                rpgExpandedReject('tactical-path-ally');
            seen = seen + [ally];
        }
        local current = self.figure.coordinate; local heading = self.figure.facing;
        local spent = 0; local paidTurns = 0; local whole = nil; local endOccupied = nil;
        foreach (local leg in self.legs)
        {
            if (leg == nil || !leg.ofKind(RpgExpandedPathLeg)) rpgExpandedReject('tactical-path-leg');
            if (leg.kind == 'turn')
            {
                if (leg.destination != nil) rpgExpandedReject('tactical-turn-destination');
                local turn = rpgExpandedMovementTurn(heading,leg.heading,self.maneuver);
                if (turn.status != 'ready') { value.reason = turn.reason; return value; }
                spent += turn.halfPoints; paidTurns += turn.halfPoints; heading = turn.heading;
            }
            else if (leg.kind == 'entry' || leg.kind == 'small-jump')
            {
                if (whole) { value.reason = 'tactical-whole-allowance-path'; return value; }
                local occupancy = self.figure.map.occupancy(leg.destination);
                if (occupancy.status != 'ready') { value.reason = occupancy.reason; return value; }
                local allyCount = 0;
                foreach (local occupant in occupancy.occupants)
                    if (occupant != self.figure)
                    {
                        if (!holds(self.allies,occupant)) { value.reason = 'tactical-evasion-required'; return value; }
                        allyCount += 1;
                    }
                local cell = self.figure.map.cellAt(leg.destination);
                local entry = leg.kind == 'small-jump' ? new RpgExpandedSmallJumpEntry() : new RpgExpandedHexEntry();
                if (leg.kind == 'small-jump')
                {
                    entry.actorSize = leg.actorSize; entry.obstacleSize = leg.obstacleSize;
                    entry.significant = leg.significant; entry.approved = leg.jumpApproved; entry.evidence = leg.jumpEvidence;
                }
                entry.origin = current; entry.target = leg.destination; entry.facing = heading;
                entry.maneuver = self.maneuver; entry.travel = leg.travel;
                entry.posture = self.figure.profile.posture; entry.terrain = cell;
                entry.minorObstructions = cell.minorObstructions + allyCount;
                entry.severeObstruction = cell.severeObstruction; entry.treacherous = cell.treacherous;
                entry.footingExtra = cell.footingExtra; entry.footingEvidence = cell.footingEvidence;
                entry.stairs = cell.stairs; entry.water = cell.water;
                local cost = entry.assess();
                if (cost.status != 'ready') { value.reason = cost.reason; return value; }
                if (cost.wholeAllowance)
                {
                    if (value.enteredHexes != 0 || paidTurns != 0)
                    { value.reason = 'tactical-whole-allowance-path'; return value; }
                    whole = true; spent = allowance.halfPoints;
                }
                else spent += cost.halfPoints;
                heading = cost.heading; current = leg.destination;
                value.enteredHexes += 1; endOccupied = allyCount != 0;
            }
            else rpgExpandedReject('tactical-path-leg-kind');
            value.stages = value.stages + [[current.q,current.r,heading,spent]];
        }
        if (endOccupied) { value.reason = 'tactical-shared-cell-procedure-required'; return value; }
        if (whole && paidTurns != 0) { value.reason = 'tactical-whole-allowance-path'; return value; }
        if (spent > allowance.halfPoints)
        {
            if (value.enteredHexes != 1 || paidTurns != 0)
            { value.reason = 'tactical-path-budget'; return value; }
            value.minimumProgress = true;
        }
        if (self.finalFacing != nil)
        {
            local final = rpgExpandedFinalFacing(heading,self.finalFacing,self.maneuver,allowance.halfPoints,spent);
            if (final.status != 'ready') { value.reason = final.reason; return value; }
            heading = final.heading;
        }
        value.destination = rpgExpandedHex(current.q,current.r); value.heading = heading;
        value.halfPoints = spent; value.allowanceHalfPoints = allowance.halfPoints;
        value.wholeAllowance = whole; value.status = 'ready'; return value;
    }
;

modify RpgExpandedProfile
    jumpPositionRequired() { return self.tacticalFigure != nil; }
;
modify RpgExpandedTacticalFigure
    jumpPlacements = []
;
/** Authored clear horizontal arc, with separate successful and prone-failure endpoints. */
class RpgExpandedJumpPlacement: RpgExpandedJumpPositionPlan
    figure = nil
    origin = nil
    destination = nil
    failure = nil
    failureUpper = nil
    clearanceApproved = nil
    evidence = nil
    result = nil
    boundDefinition = nil
    boundProfile = nil
    boundOccurrence = nil
    boundSucceeded = nil
    definition()
    {
        local values = [self.figure,self.clearanceApproved,self.evidence];
        foreach (local point in [self.origin,self.destination,self.failure,self.failureUpper])
        {
            if (point == nil || !point.ofKind(RpgExpandedHex)) rpgExpandedReject('jump-placement-coordinate');
            point.validate(); values = values + [point.q,point.r];
        }
        return values;
    }
    validateResult(profile,occurrence,succeeded)
    {
        local current = self.definition();
        if (self.result == nil || profile != self.boundProfile || occurrence != self.boundOccurrence
            || succeeded != self.boundSucceeded || !holds(self.figure.jumpPlacements,self))
            rpgExpandedReject('jump-placement-history');
        for (local index = 1; index <= current.length(); index += 1)
            if (current[index] != self.boundDefinition[index]) rpgExpandedReject('jump-placement-binding');
        return nil;
    }
    assessFor(profile,occurrence,direction,distance)
    {
        local definition = self.definition(); local value = new RpgExpandedResult();
        if (self.figure == nil || !self.figure.ofKind(RpgExpandedTacticalFigure)
            || self.figure.profile != profile || self.figure.map == nil || profile.tacticalFigure != self.figure)
            rpgExpandedReject('jump-placement-figure');
        if (self.result != nil)
        { self.validateResult(profile,occurrence,self.boundSucceeded); value.status = 'reused'; return value; }
        self.figure.map.validate();
        if (direction != 'horizontal') { value.reason = 'jump-placement-elevation-required'; return value; }
        if (!self.clearanceApproved || self.evidence == nil || self.evidence == '')
        { value.reason = 'jump-placement-clearance-required'; return value; }
        if (self.figure.bodyForm != 'upright-human' || self.figure.upperCoordinate != nil)
        { value.reason = 'jump-placement-body-form'; return value; }
        if (rpgExpandedHexDistance(self.figure.coordinate,self.origin) != 0)
        { value.reason = 'jump-placement-origin-changed'; return value; }
        if (rpgExpandedHexDistance(self.origin,self.destination) * 360 != distance)
        { value.reason = 'jump-placement-distance'; return value; }
        if (rpgExpandedHexDistance(self.failure,self.failureUpper) != 1)
            rpgExpandedReject('jump-placement-failure-footprint');
        foreach (local point in [self.destination,self.failure,self.failureUpper])
        {
            local cell = self.figure.map.cellAt(point);
            if (cell == nil) { value.reason = 'tactical-unmapped-cell'; return value; }
            local terrain = cell.assess(); if (terrain.status != 'ready') return terrain;
            foreach (local other in self.figure.map.figures)
                if (other != self.figure)
                {
                    value.reason = other.footprintReason(); if (value.reason != nil) return value;
                    foreach (local occupied in other.occupiedCells())
                        if (rpgExpandedHexDistance(occupied,point) == 0)
                        { value.reason = 'jump-placement-occupied'; return value; }
                }
        }
        value.reason = nil; value.status = 'ready'; return value;
    }
    applyFor(profile,occurrence,direction,distance,succeeded)
    {
        if (self.result != nil)
        { self.validateResult(profile,occurrence,succeeded); return self.result; }
        local value = self.assessFor(profile,occurrence,direction,distance);
        if (value.status != 'ready') rpgExpandedReject('jump-placement-changed');
        local target = succeeded ? self.destination : self.failure;
        self.figure.coordinate = rpgExpandedHex(target.q,target.r);
        self.figure.upperCoordinate = succeeded ? nil : rpgExpandedHex(self.failureUpper.q,self.failureUpper.r);
        self.boundDefinition = self.definition(); self.boundProfile = profile;
        self.boundOccurrence = occurrence; self.boundSucceeded = succeeded;
        self.figure.jumpPlacements = self.figure.jumpPlacements + [self];
        value.status = 'resolved'; self.result = value; return value;
    }
;


/** B352 automatic small-obstacle jump; no accuracy roll or separate turn. */
class RpgExpandedSmallJumpEntry: RpgExpandedHexEntry
    actorSize = 0
    obstacleSize = 0
    significant = nil
    approved = nil
    evidence = nil
    obstructionReason()
    {
        rpgInteger(self.actorSize,-20,20); rpgInteger(self.obstacleSize,-20,20);
        if (!self.approved || self.evidence == nil || self.evidence == '') return 'small-jump-author-facts';
        if (self.maneuver != 'move') return 'small-jump-move-required';
        if (!holds(['standing','crouching'],self.posture) || self.water == 'deep')
            return 'small-jump-posture-or-water';
        if (!rpgExpandedCanJumpAutomatically(self.actorSize,self.obstacleSize,self.significant))
            return 'small-jump-full-procedure-required';
        return nil;
    }
    extraEntryHalfPoints() { return 2; }
;
modify RpgExpandedPathLeg
    actorSize = 0
    obstacleSize = 0
    significant = nil
    jumpApproved = nil
    jumpEvidence = nil
;

class RpgExpandedPathMoveResult: RpgExpandedResult
    operation = nil
    definition = []
    pathResult = nil
    originQ = 0
    originR = 0
    originFacing = 0
;
modify RpgExpandedProfile
    pathMoves = []
;
/** One uninterrupted Move turn; the battle remains owner of time. */
class RpgExpandedPathMove: RpgExpandedPathMoveReceipt
    id = nil
    fighter = nil
    battle = nil
    path = nil
    uninterrupted = nil
    evidence = nil
    result = nil
    boundDefinition = nil
    definition()
    {
        local values = [self.id,self.fighter,self.battle,self.path,self.path.figure,self.path.move,
            self.path.maneuver,self.path.finalFacing,self.uninterrupted,self.evidence,self.path.legs.length(),self.path.allies.length()];
        foreach (local ally in self.path.allies) values = values + [ally];
        foreach (local leg in self.path.legs)
            values = values + [leg,leg.kind,leg.destination == nil ? nil : leg.destination.q,
                leg.destination == nil ? nil : leg.destination.r,leg.travel,leg.heading,
                leg.actorSize,leg.obstacleSize,leg.significant,leg.jumpApproved,leg.jumpEvidence];
        return values;
    }
    interruptionReason()
    { return !self.uninterrupted || self.evidence == nil || self.evidence == '' ? 'path-move-interruption-facts' : nil; }
    assess()
    {
        if (self.id == nil || self.id == '' || self.fighter == nil || !self.fighter.ofKind(RpgLiteFighter)
            || self.battle == nil || !self.battle.ofKind(RpgLiteBattle) || self.path == nil
            || !self.path.ofKind(RpgExpandedMovementPath) || self.path.figure == nil
            || self.path.figure.profile != self.fighter.profile) rpgExpandedReject('path-move-definition');
        local value = new RpgExpandedPathMoveResult(); value.operation = self; value.definition = self.definition();
        if (self.result != nil)
        {
            if (value.definition.length() != self.boundDefinition.length()) rpgExpandedReject('path-move-binding');
            for (local index = 1; index <= value.definition.length(); index += 1)
                if (value.definition[index] != self.boundDefinition[index]) rpgExpandedReject('path-move-binding');
            if (!holds(self.fighter.profile.pathMoves,self)) rpgExpandedReject('path-move-history');
            value.status = 'reused'; return value;
        }
        foreach (local prior in self.fighter.profile.pathMoves)
            if (prior.id == self.id) rpgExpandedReject('path-move-duplicate');
        if (!self.battle.active || self.battle.current() != self.fighter)
        { value.reason = 'path-move-turn'; return value; }
        if (self.path.maneuver != 'move') { value.reason = 'path-move-maneuver'; return value; }
        value.reason = self.interruptionReason(); if (value.reason != nil) return value;
        if (self.fighter.profile.moveBeforePosture() <= 0)
        { value.reason = 'path-move-unavailable'; return value; }
        if (self.path.move != self.fighter.profile.moveBeforePosture())
        { value.reason = 'path-move-allowance'; return value; }
        value.pathResult = self.path.assess();
        if (value.pathResult.status != 'ready') { value.reason = value.pathResult.reason; return value; }
        value.originQ = self.path.figure.coordinate.q; value.originR = self.path.figure.coordinate.r;
        value.originFacing = self.path.figure.facing; value.status = 'ready'; return value;
    }
    commit(value)
    {
        if (self.result != nil || value == nil || !value.ofKind(RpgExpandedPathMoveResult)
            || value.operation != self || value.status != 'ready' || self.fighter.maneuver != 'move')
            rpgExpandedReject('path-move-commit');
        local current = self.assess();
        if (current.status != 'ready' || current.definition.length() != value.definition.length())
            rpgExpandedReject('path-move-changed');
        for (local index = 1; index <= current.definition.length(); index += 1)
            if (current.definition[index] != value.definition[index]) rpgExpandedReject('path-move-changed');
        if (current.originQ != value.originQ || current.originR != value.originR || current.originFacing != value.originFacing
            || current.pathResult.halfPoints != value.pathResult.halfPoints
            || current.pathResult.heading != value.pathResult.heading
            || rpgExpandedHexDistance(current.pathResult.destination,value.pathResult.destination) != 0)
            rpgExpandedReject('path-move-changed');
        self.path.figure.coordinate = rpgExpandedHex(value.pathResult.destination.q,value.pathResult.destination.r);
        self.path.figure.facing = value.pathResult.heading;
        self.boundDefinition = value.definition; self.result = value;
        self.fighter.profile.pathMoves = self.fighter.profile.pathMoves + [self];
        value.status = 'resolved'; return value;
    }
;

class RpgExpandedClamberResult: RpgExpandedResult
    definition = []
    completes = nil
;
modify RpgExpandedProfile
    clambers = []
;
/** B352 authored reachable upper surface, two consecutive Move turns. */
class RpgExpandedClamber: RpgExpandedPathMoveReceipt
    id = nil
    fighter = nil
    battle = nil
    figure = nil
    origin = nil
    destination = nil
    reachable = nil
    stableSurface = nil
    evidence = nil
    turns = 0
    lastBattleSecond = nil
    lastLedgerSecond = nil
    boundDefinition = nil
    result = nil
    definition()
    { return [self.id,self.fighter,self.battle,self.figure,self.origin.q,self.origin.r,
        self.destination.q,self.destination.r,self.reachable,self.stableSurface,self.evidence]; }
    assess()
    {
        if (self.id == nil || self.id == '' || self.fighter == nil || !self.fighter.ofKind(RpgLiteFighter)
            || self.battle == nil || !self.battle.ofKind(RpgLiteBattle) || self.figure == nil
            || !self.figure.ofKind(RpgExpandedTacticalFigure) || self.figure.profile != self.fighter.profile
            || self.origin == nil || !self.origin.ofKind(RpgExpandedHex)
            || self.destination == nil || !self.destination.ofKind(RpgExpandedHex)) rpgExpandedReject('clamber-definition');
        self.origin.validate(); self.destination.validate();
        local value = new RpgExpandedClamberResult(); value.definition = self.definition();
        if (self.turns > 0)
        {
            for (local index = 1; index <= value.definition.length(); index += 1)
                if (value.definition[index] != self.boundDefinition[index]) rpgExpandedReject('clamber-binding');
            if (!holds(self.fighter.profile.clambers,self)) rpgExpandedReject('clamber-history');
        }
        if (self.result != nil) { value.status = 'reused'; return value; }
        if (!self.battle.active || self.battle.current() != self.fighter)
        { value.reason = 'clamber-turn'; return value; }
        if (self.lastBattleSecond == self.battle.seconds) { value.reason = 'clamber-duplicate-turn'; return value; }
        foreach (local prior in self.fighter.profile.clambers)
            if (prior != self && prior.id == self.id) rpgExpandedReject('clamber-duplicate');
        if (!self.reachable || !self.stableSurface || self.evidence == nil || self.evidence == '')
        { value.reason = 'clamber-surface-facts'; return value; }
        if (self.figure.map == nil || self.figure.profile.tacticalFigure != self.figure)
            rpgExpandedReject('clamber-map');
        self.figure.map.validate();
        if (self.figure.bodyForm != 'upright-human' || self.figure.upperCoordinate != nil
            || !holds(['standing','crouching'],self.figure.profile.posture))
        { value.reason = 'clamber-body-support'; return value; }
        if (rpgExpandedHexDistance(self.figure.coordinate,self.origin) != 0)
        { value.reason = 'clamber-origin-changed'; return value; }
        if (rpgExpandedHexDistance(self.origin,self.destination) != 1)
        { value.reason = 'clamber-adjacent-surface-required'; return value; }
        local occupancy = self.figure.map.occupancy(self.destination);
        if (occupancy.status != 'ready') { value.reason = occupancy.reason; return value; }
        if (occupancy.occupants.length() != 0) { value.reason = 'clamber-surface-occupied'; return value; }
        value.completes = self.turns == 1 && self.battle.seconds == self.lastBattleSecond + 1
            && rpgLedger.seconds == self.lastLedgerSecond + 1;
        value.status = 'ready'; return value;
    }
    commit(value)
    {
        if (self.result != nil || value == nil || !value.ofKind(RpgExpandedClamberResult)
            || value.status != 'ready' || self.fighter.maneuver != 'move') rpgExpandedReject('clamber-commit');
        local current = self.assess();
        if (current.status != 'ready' || current.completes != value.completes) rpgExpandedReject('clamber-changed');
        for (local index = 1; index <= current.definition.length(); index += 1)
            if (current.definition[index] != value.definition[index]) rpgExpandedReject('clamber-changed');
        if (self.turns == 0) self.fighter.profile.clambers = self.fighter.profile.clambers + [self];
        self.boundDefinition = value.definition; self.turns = value.completes ? 2 : 1;
        self.lastBattleSecond = self.battle.seconds; self.lastLedgerSecond = rpgLedger.seconds;
        if (value.completes)
        {
            self.figure.coordinate = rpgExpandedHex(self.destination.q,self.destination.r);
            self.result = value;
        }
        value.status = 'resolved'; return value;
    }
;

/** Narrative room relocation must never leave an installed tactical figure behind. */
modify RpgExpandedProfile
    panicRelocationReason()
    {
        if (self.tacticalFigure != nil) return 'panic-flight-tactical-route-required';
        return inherited();
    }
;

/** One authored panic Move turn uses the existing path, health gate and battle scheduler. */
class RpgExpandedPanicPathOperation: RpgExpandedPanicOperation
    ownsTime = true
    reaction = nil
    move = nil
    maneuver = nil
    result = nil
    boundFacts = nil
    boundOutcome = nil
    battleSecond = nil
    ledgerSecond = nil
    facts(owner)
    {
        if (self.reaction != owner || self.move == nil || !self.move.ofKind(RpgExpandedPathMove)
            || self.maneuver == nil || !self.maneuver.ofKind(RpgExpandedPanicPathManeuver)
            || self.maneuver.operation != self.move || self.maneuver.panicReaction != owner
            || self.maneuver.healthGate == nil || !self.maneuver.healthGate.ofKind(RpgExpandedPanicActionGate)
            || self.maneuver.healthGate.panicReaction != owner || self.move.fighter.profile != self.profile)
            rpgExpandedReject('panic-path-definition');
        return [self,self.profile,owner,self.move,self.maneuver,self.maneuver.healthGate,self.ownsTime]
            + self.move.definition();
    }
    outcomeFacts()
    { return [self.result,self.result.status,self.result.outcome,self.battleSecond,self.ledgerSecond]; }
    permitsAuthorization(request)
    { return self.result == nil && (request == self.maneuver || request == self.maneuver.healthGate); }
    clockSeconds(owner)
    {
        self.facts(owner);
        return self.move.battle.index == self.move.battle.order.length() ? 1 : 0;
    }
    permitsBattleClock(battle)
    {
        return self.result != nil && battle == self.move.battle && battle.active
            && battle.seconds == self.battleSecond+1 && rpgLedger.seconds == self.ledgerSecond;
    }
    validateReceipt(owner)
    {
        local facts = self.facts(owner);
        if (self.result == nil || self.boundFacts == nil || facts.length() != self.boundFacts.length()
            || self.battleSecond == nil || self.ledgerSecond == nil) rpgExpandedReject('panic-path-receipt');
        for (local i = 1; i <= facts.length(); i += 1)
            if (facts[i] != self.boundFacts[i]) rpgExpandedReject('panic-path-binding');
        facts = self.outcomeFacts();
        if (self.boundOutcome == nil || facts.length() != self.boundOutcome.length()) rpgExpandedReject('panic-path-outcome');
        for (local i = 1; i <= facts.length(); i += 1)
            if (facts[i] != self.boundOutcome[i]) rpgExpandedReject('panic-path-outcome');
        if (self.maneuver.healthGate.assess().status != 'reused') rpgExpandedReject('panic-path-permission-receipt');
        if (self.result.outcome == 'incapacitated')
        {
            if (self.move.result != nil || self.maneuver.healthGate.result.allowed) rpgExpandedReject('panic-path-incapacity-receipt');
        }
        else if (self.move.assess().status != 'reused') rpgExpandedReject('panic-path-movement-receipt');
        return nil;
    }
    assess(owner)
    {
        local facts = self.facts(owner); local value = new RpgExpandedResult();
        if (self.result != nil) { self.validateReceipt(owner); value.status = 'reused'; return value; }
        if (self.boundFacts != nil || self.boundOutcome != nil || self.battleSecond != nil || self.ledgerSecond != nil) rpgExpandedReject('panic-path-uncommitted');
        if (!self.ownsTime || owner.operation != self) rpgExpandedReject('panic-path-time-owner');
        if (owner.seconds != 1) { value.reason = 'panic-path-one-turn'; return value; }
        value.reason = self.maneuver.available(self.move.fighter); if (value.reason != nil) return value;
        value.reason = self.maneuver.healthAvailable(self.move.fighter); if (value.reason != nil) return value;
        value.status = 'ready'; return value;
    }
    apply(owner)
    {
        local value = self.assess(owner); if (value.status != 'ready') return value;
        self.boundFacts = self.facts(owner); self.battleSecond = self.move.battle.seconds; self.ledgerSecond = rpgLedger.seconds;
        value = self.move.battle.step(self.move.fighter,self.maneuver);
        if (value.status != 'resolved') rpgExpandedReject('panic-path-turn-changed');
        self.result = value; self.boundOutcome = self.outcomeFacts(); return value;
    }
;

/** A concrete predeclared injury interruption at a completed path leg.
 * Attack/Wait resolution is separate; wound amount is already adjudicated. */
class RpgExpandedPathInjuryInterruption: object
    move = nil
    afterLeg = nil
    wound = nil
    fallUpper = nil
    approved = nil
    triggerEvidence = nil
    injuryEvidence = nil
    result = nil
    boundFacts = nil
    uniqueEffect() { return self.wound; }
    facts()
    {
        if (self.move == nil || !self.move.ofKind(RpgExpandedInterruptedPathMove)
            || self.wound == nil || !self.wound.ofKind(RpgExpandedWound)
            || self.wound.profile != self.move.fighter.profile || self.fallUpper == nil
            || !self.fallUpper.ofKind(RpgExpandedHex)) rpgExpandedReject('path-interruption-definition');
        rpgInteger(self.afterLeg,1,self.move.path.legs.length()); self.fallUpper.validate();
        return [self,self.move,self.afterLeg,self.wound,self.wound.id,self.wound.profile,self.wound.amount,
            self.wound.location,self.wound.maleGroin,self.wound.dropDestination,self.wound.anatomy,
            self.wound.bodyPart,self.wound.severing,self.wound.criticalHit,self.wound.forceMajorWound,
            self.fallUpper.q,self.fallUpper.r,self.approved,self.triggerEvidence,self.injuryEvidence];
    }
    validateReceipt()
    {
        local facts = self.facts();
        if (self.result == nil || self.boundFacts == nil || facts.length() != self.boundFacts.length()
            || !holds(self.move.interruptions,self) || self.move.result == nil
            || self.move.result.completedLegs < self.afterLeg) rpgExpandedReject('path-interruption-receipt');
        for (local i = 1; i <= facts.length(); i += 1)
            if (facts[i] != self.boundFacts[i]) rpgExpandedReject('path-interruption-binding');
        if (self.wound.assess().status != 'reused' || self.result.health != self.wound.health)
            rpgExpandedReject('path-interruption-wound-history');
        return nil;
    }
    assess(stage)
    {
        self.facts(); local value = new RpgExpandedResult();
        if (self.result != nil) { self.validateReceipt(); value.status = 'reused'; return value; }
        if (self.boundFacts != nil) rpgExpandedReject('path-interruption-uncommitted');
        if (!self.approved || self.triggerEvidence == nil || self.triggerEvidence == ''
            || self.injuryEvidence == nil || self.injuryEvidence == '')
        { value.reason = 'path-interruption-author-facts'; return value; }
        if (self.wound.bodyPart != nil)
        { value.reason = 'path-interruption-body-part-adapter-required'; return value; }
        local geometry = self.assessGeometry(stage); if (geometry.status != 'ready') return geometry;
        local injury = self.wound.assess();
        if (injury.status == 'reused') rpgExpandedReject('path-interruption-used-wound');
        return injury;
    }
    assessGeometry(stage)
    {
        local value = new RpgExpandedResult();
        local landing = rpgExpandedHex(stage[1],stage[2]);
        if (rpgExpandedHexDistance(landing,self.fallUpper) != 1)
            rpgExpandedReject('path-interruption-fall-footprint');
        local landingOccupancy = self.move.path.figure.map.occupancy(landing);
        if (landingOccupancy.status != 'ready') return landingOccupancy;
        foreach (local figure in landingOccupancy.occupants)
            if (figure != self.move.path.figure) { value.reason = 'path-interruption-shared-stop'; return value; }
        local occupancy = self.move.path.figure.map.occupancy(self.fallUpper);
        if (occupancy.status != 'ready') return occupancy;
        foreach (local figure in occupancy.occupants)
            if (figure != self.move.path.figure) { value.reason = 'path-interruption-fall-occupied'; return value; }
        value.status = 'ready'; return value;
    }
    apply(stage)
    {
        if (!self.move.executing || self.move.result != nil
            || self.move.executingLeg != self.afterLeg) rpgExpandedReject('path-interruption-execution-owner');
        local value = self.assess(stage); if (value.status != 'ready') rpgExpandedReject('path-interruption-changed');
        self.boundFacts = self.facts(); self.result = self.wound.apply();
        if (self.result.status != 'resolved') rpgExpandedReject('path-interruption-injury-changed');
        if (self.move.fighter.profile.posture == 'lying')
            self.move.path.figure.upperCoordinate = rpgExpandedHex(self.fallUpper.q,self.fallUpper.r);
        return self.result;
    }
;
modify RpgExpandedPathMoveResult
    completedLegs = 0
    stoppedReason = nil
    finalQ = nil
    finalR = nil
    finalFacing = nil
    spentHalfPoints = 0
;

/** Staged Move execution; health can stop the route before its planned endpoint. */
class RpgExpandedInterruptedPathMove: RpgExpandedPathMove
    interruptions = []
    reducedMovePolicy = nil
    executing = nil
    executingLeg = nil
    boundOutcome = nil
    interruptionReason()
    {
        if (self.uninterrupted || self.interruptions.length() == 0 || self.evidence == nil || self.evidence == '')
            return 'interrupted-path-author-facts';
        /* No unprinted rule is inferred for a mid-turn change to the allowance. */
        if (self.reducedMovePolicy != 'stop') return 'interrupted-path-allowance-policy';
        return nil;
    }
    definition()
    {
        local facts = inherited() + [self.reducedMovePolicy,self.interruptions.length()];
        foreach (local interruption in self.interruptions)
        {
            if (interruption == nil || !interruption.ofKind(RpgExpandedPathInjuryInterruption)
                || interruption.move != self) rpgExpandedReject('interrupted-path-owner');
            facts = facts + interruption.facts();
        }
        return facts;
    }
    outcomeFacts()
    {
        local value = self.result;
        return [value,value.status,value.completedLegs,value.stoppedReason,value.finalQ,value.finalR,
            value.finalFacing,value.spentHalfPoints,value.originQ,value.originR,value.originFacing];
    }
    assess()
    {
        local value = inherited();
        if (value.status == 'reused')
        {
            if (self.executing || self.executingLeg != nil || self.boundOutcome == nil) rpgExpandedReject('interrupted-path-history');
            local facts = self.outcomeFacts();
            if (facts.length() != self.boundOutcome.length()) rpgExpandedReject('interrupted-path-outcome');
            for (local i = 1; i <= facts.length(); i += 1)
                if (facts[i] != self.boundOutcome[i]) rpgExpandedReject('interrupted-path-outcome');
            foreach (local interruption in self.interruptions)
                if (interruption.afterLeg <= self.result.completedLegs) interruption.validateReceipt();
                else if (interruption.result != nil || interruption.boundFacts != nil) rpgExpandedReject('interrupted-path-unreached-consequence');
            return value;
        }
        if (value.status != 'ready') return value;
        if (self.boundOutcome != nil) rpgExpandedReject('interrupted-path-uncommitted');
        local last = 0; local wounds = [];
        foreach (local interruption in self.interruptions)
        {
            if (interruption.afterLeg <= last || holds(wounds,interruption.uniqueEffect()))
                rpgExpandedReject('interrupted-path-order');
            last = interruption.afterLeg; wounds = wounds + [interruption.uniqueEffect()];
            local consequence = interruption.assess(value.pathResult.stages[last]);
            if (consequence.status != 'ready') { value.status = 'blocked'; value.reason = consequence.reason; return value; }
        }
        return value;
    }
    commit(value)
    {
        if (self.result != nil || self.executing || value == nil || !value.ofKind(RpgExpandedPathMoveResult)
            || value.operation != self || value.status != 'ready' || self.fighter.maneuver != 'move')
            rpgExpandedReject('interrupted-path-commit');
        local current = self.assess();
        if (current.status != 'ready' || current.definition.length() != value.definition.length()
            || current.originQ != value.originQ || current.originR != value.originR || current.originFacing != value.originFacing
            || current.pathResult.heading != value.pathResult.heading
            || current.pathResult.stages.length() != value.pathResult.stages.length()) rpgExpandedReject('interrupted-path-changed');
        for (local i = 1; i <= current.definition.length(); i += 1)
            if (current.definition[i] != value.definition[i]) rpgExpandedReject('interrupted-path-changed');
        for (local i = 1; i <= current.pathResult.stages.length(); i += 1)
            for (local j = 1; j <= 4; j += 1)
                if (current.pathResult.stages[i][j] != value.pathResult.stages[i][j]) rpgExpandedReject('interrupted-path-changed');
        local startTime = rpgLedger.seconds; local startBattle = self.battle.seconds;
        local figure = self.path.figure; local profile = self.fighter.profile; local posture = profile.posture;
        self.executing = true;
        for (local i = 1; i <= value.pathResult.stages.length(); i += 1)
        {
            local stage = value.pathResult.stages[i]; self.executingLeg = i;
            figure.coordinate = rpgExpandedHex(stage[1],stage[2]); figure.facing = stage[3];
            value.completedLegs = i; value.spentHalfPoints = stage[4];
            foreach (local interruption in self.interruptions)
                if (interruption.afterLeg == i) interruption.apply(stage);
            if (profile.dead) value.stoppedReason = 'dead';
            else if (profile.unconscious || profile.mortal || profile.stunned || profile.mentalStun)
                value.stoppedReason = 'incapacitated';
            else if (profile.posture != posture) value.stoppedReason = 'posture-changed';
            else if (profile.moveBeforePosture() < self.path.move) value.stoppedReason = 'authored-reduced-move-stop';
            if (value.stoppedReason != nil) break;
        }
        if (value.stoppedReason == nil) figure.facing = value.pathResult.heading;
        if (rpgLedger.seconds != startTime || self.battle.seconds != startBattle) rpgExpandedReject('interrupted-path-extra-time');
        self.executing = nil; self.executingLeg = nil;
        value.finalQ = figure.coordinate.q; value.finalR = figure.coordinate.r; value.finalFacing = figure.facing;
        self.boundDefinition = value.definition; self.result = value; value.status = 'resolved';
        self.fighter.profile.pathMoves = self.fighter.profile.pathMoves + [self]; self.boundOutcome = self.outcomeFacts();
        return value;
    }
;

/** B366/B385: a declared stationary attack interrupts a path at its trigger hex. */
class RpgExpandedPathWaitInterruption: RpgExpandedPathInjuryInterruption
    declaration = nil
    strike = nil
    executingStrike = nil
    uniqueEffect() { return self.strike; }
    facts()
    {
        if (self.move == nil || !self.move.ofKind(RpgExpandedInterruptedPathMove)
            || self.declaration == nil || !self.declaration.ofKind(RpgExpandedWaitDeclaration)
            || self.strike == nil || !self.strike.ofKind(RpgExpandedAdjudicatedStrike)
            || self.strike.attacker != self.declaration.fighter || self.strike.defender != self.move.fighter
            || self.strike.weapon != self.declaration.weapon || self.strike.mode != self.declaration.mode
            || self.declaration.battle != self.move.battle || self.declaration.targetProfile != self.move.fighter.profile
            || self.fallUpper == nil || !self.fallUpper.ofKind(RpgExpandedHex) || self.wound != nil)
            rpgExpandedReject('path-wait-definition');
        rpgInteger(self.afterLeg,1,self.move.path.legs.length()); self.fallUpper.validate();
        return [self,self.move,self.afterLeg,self.declaration,self.strike,self.fallUpper.q,self.fallUpper.r,
            self.approved,self.triggerEvidence] + self.declaration.facts() + self.strike.facts();
    }
    validateReceipt()
    {
        local facts = self.facts();
        if (self.result == nil || self.boundFacts == nil || facts.length() != self.boundFacts.length()
            || self.executingStrike || self.declaration.triggeredBy != self || self.strike.result != self.result
            || self.move.result == nil || self.move.result.completedLegs < self.afterLeg)
            rpgExpandedReject('path-wait-receipt');
        for (local i = 1; i <= facts.length(); i += 1)
            if (facts[i] != self.boundFacts[i]) rpgExpandedReject('path-wait-binding');
        self.declaration.validateReceipt(); self.strike.validateReceipt(); return nil;
    }
    assess(stage)
    {
        self.facts(); local value = new RpgExpandedResult();
        if (self.result != nil) { self.validateReceipt(); value.status = 'reused'; return value; }
        if (self.boundFacts != nil) rpgExpandedReject('path-wait-uncommitted');
        if (!self.approved || self.triggerEvidence == nil || self.triggerEvidence == '')
        { value.reason = 'path-wait-trigger-evidence'; return value; }
        if (self.declaration.declaredAt == nil) { value.reason = 'path-wait-not-declared'; return value; }
        value.reason = self.declaration.responseReason(); if (value.reason != nil) return value;
        if (stage[1] != self.declaration.triggerHex.q || stage[2] != self.declaration.triggerHex.r)
        { value.reason = 'path-wait-trigger-position'; return value; }
        if (self.strike.wound != nil && self.strike.wound.bodyPart != nil)
        { value.reason = 'path-wait-body-part-adapter-required'; return value; }
        local geometry = self.assessGeometry(stage); if (geometry.status != 'ready') return geometry;
        value = self.strike.assess();
        if (value.status == 'reused') rpgExpandedReject('path-wait-used-strike');
        return value;
    }
    permitsStrike(strike)
    {
        return strike == self.strike && self.executingStrike && self.move.executing
            && self.move.executingLeg == self.afterLeg && self.move.result == nil
            && self.declaration.triggeredBy == nil && self.declaration.responseReason() == nil;
    }
    apply(stage)
    {
        if (!self.move.executing || self.move.result != nil || self.move.executingLeg != self.afterLeg)
            rpgExpandedReject('path-wait-execution-owner');
        local value = self.assess(stage); if (value.status != 'ready') rpgExpandedReject('path-wait-changed');
        self.boundFacts = self.facts(); self.executingStrike = true;
        self.result = self.strike.apply(self);
        if (self.result.status != 'resolved') rpgExpandedReject('path-wait-strike-changed');
        self.executingStrike = nil; self.declaration.triggeredBy = self; self.declaration.boundTrigger = self;
        self.declaration.fighter.maneuver = 'attack';
        if (self.move.fighter.profile.posture == 'lying')
            self.move.path.figure.upperCoordinate = rpgExpandedHex(self.fallUpper.q,self.fallUpper.r);
        return self.result;
    }
;
