
--Register LAM with LibStub
local LIBRARY_NAME = "LibLoadedAddons"
local MAJOR, MINOR = LIBRARY_NAME, 2
local lla, oldminor = LibStub:NewLibrary(MAJOR, MINOR)
if not lla then return end	--the same or newer version of this lib is already loaded into memory 

local loadedAddons = {}
local doneLoading = false

------------------------------------------------------------------------
-- 	General Functions  --
------------------------------------------------------------------------

function lla:RegisterAddon(addonName, versionNumber, apiObject)
	if type(versionNumber) ~= "number" then 
		return false, "Version number must be a number."
	end
	
	local addon = loadedAddons[addonName]
	if addon then
    local version = addon.version
		if version == 0 then
			loadedAddons[addonName] = {
        version = versionNumber,
        apis = {["_"]=apiObject},
      }
			return true
		else
			return false, "Version number already set for this addon"
		end
	end
	return false, "Addon "..addonName.." is not loaded."
end

function lla:RegisterApi(addonName, apiName, apiObject)
  assert(apiName ~= "_")
  local addon = loadedAddons[addonName]
  if addon then
    if not apiName then
      apiName = "_"
    end
    addon.apis[apiName] = apiObject
  end
  return false, "Addon "..addonName.." is not loaded."
end

function lla:UnregisterAddon(addonName)
	if loadedAddons[addonName] then
		loadedAddons[addonName] = nil
		return true
	end
  return false, "Addon "..addonName.." was not registered."
end

-- Returns nil if loading is not finished yet and status unknown.
-- Wait for true or false result.
function lla:IsAddonLoaded(addonName)
  if not doneLoading then
    return nil
  end
	local addon = loadedAddons[addonName]
	if addon then
		return true, addon.version
	end
  return false
end

function lla:GetAddon(addonName, apiName)
	local addon = loadedAddons[addonName]
	if addon then
    if not apiName then
      apiName = "_"
    end
		return addon.apis[apiName]
	end
	return nil
end

local function OnPlayerActivated()
  EVENT_MANAGER:UnregisterForEvent(LIBRARY_NAME, EVENT_ADD_ON_LOADED)
  EVENT_MANAGER:UnregisterForEvent(LIBRARY_NAME, EVENT_PLAYER_ACTIVATED)
  doneLoading = true
end

local function OnAddOnLoaded(_, addonName)
	loadedAddons[addonName] = {version=0, object=nil}
end

---------------------------------------------------------------------------------
--  Register Events --
---------------------------------------------------------------------------------

EVENT_MANAGER:UnregisterForEvent(LIBRARY_NAME, EVENT_ADD_ON_LOADED)
EVENT_MANAGER:UnregisterForEvent(LIBRARY_NAME, EVENT_PLAYER_ACTIVATED)

EVENT_MANAGER:RegisterForEvent(LIBRARY_NAME, EVENT_ADD_ON_LOADED, OnAddOnLoaded)
EVENT_MANAGER:RegisterForEvent(LIBRARY_NAME, EVENT_PLAYER_ACTIVATED, OnPlayerActivated)

