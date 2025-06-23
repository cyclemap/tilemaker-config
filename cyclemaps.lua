
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

	if GetSurface() == "unpaved" or highway == "pedestrian" or highway == "living_street" or highway == "path" or highway == "footway" or highway == "steps" or highway == "bridleway" or highway == "corridor" or highway == "track" then
		if bicycle == "yes" or bicycle == "permissive" or bicycle == "dismount" or bicycle == "customers" or bicycle == "designated" or
			Holds("ramp:bicycle") and Find("ramp:bicycle") ~= "no" or
			Find("icn") == "yes" or Holds("icn_ref") or
			Find("ncn") == "yes" or Holds("ncn_ref") or
			Find("rcn") == "yes" or Holds("rcn_ref") or
			Find("lcn") == "yes" or Holds("lcn_ref") or
			Find("route") == "bicycle" then
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

	if Find("icn") == "yes" or Holds("icn_ref") or
		Find("ncn") == "yes" or Holds("ncn_ref") or
		Find("rcn") == "yes" or Holds("rcn_ref") or
		Find("lcn") == "yes" or Holds("lcn_ref") or
		Find("route") == "bicycle" then
			return true
	end

	if bicycle == "yes" or bicycle == "permissive" or bicycle == "dismount" then
		if highway == "residential" or highway == "service" or highway == "unclassified" or
			IsMaxSpeedLow() and IsWideOrUnknown() or
			IsMaxSpeedVeryLow() then
			return true
		end
	end
	
	return false

end

