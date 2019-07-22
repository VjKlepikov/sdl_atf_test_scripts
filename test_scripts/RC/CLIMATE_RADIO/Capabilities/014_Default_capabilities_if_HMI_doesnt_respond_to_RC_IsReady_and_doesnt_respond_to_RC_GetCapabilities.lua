---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0213-rc-radio-climate-parameter-update.md
-- Description:
-- Preconditions:
-- 1) Prepare testing HMI_capabilities.json file where parameter (climateEnableAvailable": false )
-- SDL did not received remoteControlCapability from HMI
-- In case:
-- 1) Mobile app sends GetSystemCapability (REMOTE_CONTROL) request to SDL
-- SDL must:
-- 1) use default capabiltites stored in the HMI_capabilities.json file and
-- 2) sends GetSystemCapability response with ( "climateControlCapabilities": { "climateEnableAvailable": false },
--    "resultCode": SUCCESS ) to Mobile
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/commonRC')
local hmi_values = require('user_modules/hmi_values')
local utils = require("user_modules/utils")
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local defaultHMIcapabilitiesRC

--[[ Local Functions ]]
local function getHMIParams()
  local params = hmi_values.getDefaultHMITable()
  params.RC.IsReady.params.available = true
  params.RC.GetCapabilities = nil
  return params
end

local function updateDefaultHMIcapabilities()
  local hmiCapabilitiesFile = commonPreconditions:GetPathToSDL()
    .. commonFunctions:read_parameter_from_smart_device_link_ini("HMICapabilities")
  local defaultHMIcapabilities = utils.jsonFileToTable(hmiCapabilitiesFile)
  defaultHMIcapabilitiesRC = defaultHMIcapabilities.UI.systemCapabilities.remoteControlCapability
  defaultHMIcapabilitiesRC.climateControlCapabilities[1].climateEnableAvailable = false
  defaultHMIcapabilitiesRC.radioControlCapabilities[1].availableHdChannelsAvailable = false
  utils.tableToJsonFile(defaultHMIcapabilities, hmiCapabilitiesFile)

end

local function rpcSuccess()
  local cid = commonRC.getMobileSession():SendRPC("GetSystemCapability", { systemCapabilityType = "REMOTE_CONTROL" })
  commonRC.getMobileSession():ExpectResponse(cid, {
    success = true,
    resultCode = "SUCCESS",
    systemCapability = {
      remoteControlCapability = {
        climateControlCapabilities = defaultHMIcapabilitiesRC.climateControlCapabilities,
        radioControlCapabilities = defaultHMIcapabilitiesRC.radioControlCapabilities
      }
    }
  })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Backup HMI capabilities file", commonRC.backupHMICapabilities)
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Update default hmi capabilities", updateDefaultHMIcapabilities)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start, { getHMIParams() })
runner.Step("RAI", commonRC.registerAppWOPTU)
runner.Step("Activate App", commonRC.activateApp)

runner.Title("Test")
runner.Step("GetSystemCapability_SUCCESS", rpcSuccess)

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
runner.Step("Restore HMI capabilities file", commonRC.restoreHMICapabilities)
