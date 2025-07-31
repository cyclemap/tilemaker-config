
function IsCycleway(highway)
	if highway == "construction" then return false end

	local bicycle = Find("bicycle")

	if bicycle == "no" or bicycle == "private" or bicycle == "permit" then
		return false
	end

	local cycleway = Find("cycleway")
	local cyclewayLeft = Find("cycleway:left")
	local cyclewayRight = Find("cycleway:right")
	local cyclewayBoth = Find("cycleway:both")

	if cycleway == "separate" or cyclewayLeft == "separate" or cyclewayRight == "separate" or cyclewayBoth == "separate" then
		return false
	end

	if highway == "cycleway" then return true end

	local mtb = Find("mtb:scale")
	if mtb ~= "" and mtb ~= "6" or
		Holds("mtb:scale:imba") or Holds("mtb:type") or bicycle == "mtb" or Find("route") == "mtb" then
			return true
	end

	if cycleway == "lane" or cycleway == "opposite_lane" or cycleway == "opposite" or cycleway == "share_busway" or cycleway == "opposite_share_busway" or cycleway == "shared" or cycleway == "track" or cycleway == "opposite_track" or
		cyclewayLeft == "lane" or cyclewayLeft == "opposite_lane" or cyclewayLeft == "opposite" or cyclewayLeft == "share_busway" or cyclewayLeft == "opposite_share_busway" or cyclewayLeft == "shared" or cyclewayLeft == "track" or cyclewayLeft == "opposite_track" or
		cyclewayRight == "lane" or cyclewayRight == "opposite_lane" or cyclewayRight == "opposite" or cyclewayRight == "share_busway" or cyclewayRight == "opposite_share_busway" or cyclewayRight == "shared" or cyclewayRight == "track" or cyclewayRight == "opposite_track" or
		cyclewayBoth == "lane" or cyclewayBoth == "opposite_lane" or cyclewayBoth == "opposite" or cyclewayBoth == "share_busway" or cyclewayBoth == "opposite_share_busway" or cyclewayBoth == "shared" or cyclewayBoth == "track" or cyclewayBoth == "opposite_track" then
		return true
	end

	if Find("oneway") == "yes" and Find("oneway:bicycle") == "no" then return true end

	local unpaved = GetSurface() == "unpaved"
	if unpaved or highway == "pedestrian" or highway == "living_street" or highway == "path" or highway == "footway" or highway == "steps" or highway == "bridleway" or highway == "corridor" or highway == "track" then
		-- special logic for sidewalks:  bicycle=yes is enough for CycleFriendly but not Cycleway
		if bicycle == "yes" and (unpaved or highway ~= "footway" or Find("footway") ~= "sidewalk") then
			return true
		end
		if bicycle == "permissive" or bicycle == "dismount" or bicycle == "customers" or bicycle == "designated" or
			Holds("ramp:bicycle") and Find("ramp:bicycle") ~= "no" or
			GetCycleRouteType() ~= "" then
			return true
		end
	end

	-- todo sport can have multiple values.  match against (;|^)cycling(;|$)
	if Find("sport") == "cycling" then return true end

	return false
end

function IsMaxSpeedLow()
	-- todo
	return false
end

function IsWideOrUnknown()
	-- todo
	return false
end

function IsMaxSpeedVeryLow()
	-- todo
	return false
end

function IsCycleFriendly(highway)
	if highway == "construction" then return false end

	local bicycle = Find("bicycle")
	if bicycle == "no" or bicycle == "private" or bicycle == "permit" then return false end

	if Find("cycleway") == "separate" or
		Find("cycleway:left") == "separate" or
		Find("cycleway:right") == "separate" or
		Find("cycleway:both") == "separate" then return false end

	if bicycle == "customers" or bicycle == "designated" then return true end

	if Find("cycleway") == "shared_lane" or
		Find("cycleway:left") == "shared_lane" or
		Find("cycleway:right") == "shared_lane" or
		Find("cycleway:both") == "shared_lane" then return true end

	if GetCycleRouteType() ~= "" then return true end

	if bicycle == "yes" or bicycle == "permissive" or bicycle == "dismount" then
		if highway == "residential" or highway == "service" or highway == "unclassified" or
			IsMaxSpeedLow() and IsWideOrUnknown() or
			IsMaxSpeedVeryLow() then
			return true
		end
	end

	-- special logic for sidewalks:  bicycle=yes is enough for CycleFriendly but not Cycleway
	if bicycle == "yes" and highway == "footway" and Find("footway") == "sidewalk" then
		return true
	end
	
	return false

end

function GetSurface()
	local surface = split(Find("surface"), ";")
	-- prioritize unpaved
	for _, surfaceEntry in ipairs(surface) do
		if unpavedValues[surfaceEntry] then return "unpaved" end
	end
	for _, surfaceEntry in ipairs(surface) do
		if pavedValues[surfaceEntry] then return "paved" end
	end
	
	local highway = Find("highway")
	local smoothness = Find("smoothness")
	
	if smoothness == "excellent" or smoothness == "good" or Holds("crossing") or Find("footway") == "access_aisle" then return "paved"
	elseif Holds("mtb:scale") or Holds("mtb:scale:imba") or Holds("mtb:type") or Find("bicycle") == "mtb" or Find("route") == "mtb" then return "unpaved"
	
	elseif highway == "motorway" or highway == "trunk" or highway == "primary" or highway == "secondary" or highway == "tertiary" or highway == "unclassified" or highway == "residential" or highway == "living_street" or highway == "road" or highway == "service" or highway == "motorway_link" or highway == "trunk_link" or highway == "primary_link" or highway == "secondary_link" or highway == "tertiary_link" or highway == "raceway" or highway == "steps" or highway == "cycleway" then return "paved"

	elseif highway == "track" or Holds("tracktype") and Find("tracktype") ~= "grade1" then return "unpaved"
	elseif smoothness == "very_bad" or smoothness == "horrible" or smoothness == "very_horrible" or smoothness == "impassible" then return "unpaved"
	elseif Holds("hiking") and Find("hiking") ~= "no" then return "unpaved"
	elseif Holds("sac_scale") and Find("sac_scale") ~= "strolling" then return "unpaved"
	end

	return ""
end

-- scan a route that is type==route and route==bicycle
function ScanCycleRoute()
	-- see tilemaker/docs/RELATIONS.md . . . when Accept() is called, the relation data is added to FindInRelation for the ways
	Accept()
end

-- see ScanCycleRoute() above for how these values are added to the ways
function GetCycleRouteType()
	-- also check the legacy tags?
	-- using a variable here so we can reset the relations
	local routeType = ""
	while true do
		local relationId = NextRelation()
		if not relationId then break end
		if FindInRelation("icn") == "yes" or FindInRelation("icn_ref") ~= "" then routeType="icn"; break end
		if FindInRelation("ncn") == "yes" or FindInRelation("ncn_ref") ~= "" then routeType="ncn"; break end
		if FindInRelation("rcn") == "yes" or FindInRelation("rcn_ref") ~= "" then routeType="rcn"; break end
		if FindInRelation("lcn") == "yes" or FindInRelation("lcn_ref") ~= "" then routeType="lcn"; break end
		if FindInRelation("route") == "bicycle" then routeType="bicycle"; break end
	end
	RestartRelations()
	return routeType
end

function CycleRouteLayer()
	Layer("cycleroute", false)
	Attribute("type", GetCycleRouteType())
	Attribute("class", Find("network"))
	Attribute("ref", Find("ref"))
	Attribute("name", Find("name"))
end

