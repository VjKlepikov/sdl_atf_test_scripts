---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0240-sdl-js-pwa.md
--
-- Description:
-- Processing of the UpdateAppList request to HMI if Web application is unregistered
--
-- Precondition:
-- 1. SDL and HMI are started
-- 2. Web WebApp_1 is enabled through SetAppProperties
-- 3. Web WebApp_2 is enabled through SetAppProperties
-- 4. Web WebApp_1 is registered and activated

-- Sequence:
-- 1. Web app is unregistered
--  a. SDL sends BC.UpdateAppList with WebApp_1 and WebApp_2 since they are still enabled

--[[ General test configuration ]]
config.defaultMobileAdapterType = "WS"

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/WebEngine/commonWebEngine')

--[[ General configuration parameters ]]
runner.testSettings.isSelfIncluded = false
runner.testSettings.restrictions.sdlBuildOptions = {{ webSocketServerSupport = { "ON" }}}

--[[ Local Variables ]]
local expected = 1

--[[ Local Functions ]]
local function checkUpdateAppList(pAppID, pTimes, pExpNumOfApps)
  if not pTimes then pTimes = 0 end
  if not pExpNumOfApps then pExpNumOfApps = 0 end
  common.getHMIConnection():ExpectRequest("BasicCommunication.UpdateAppList")
  :Times(pTimes)
  :ValidIf(function(_,data)
    if #data.params.applications == pExpNumOfApps then
      if #data.params.applications ~= 0 then
        for i = 1,#data.params.applications do
          local app = data.params.applications[i]
          if app.policyAppID == pAppID then
            if app.isCloudApplication == false  then
              return true
            else
              return false, "Parameter isCloudApplication = " .. tostring(app.isCloudApplication) ..
              ", expected = false"
            end
          end
        end
        return false, "Application was not found in application array"
      else
        return true
      end
    else
      return false, "Application array in BasicCommunication.UpdateAppList contains " ..
        tostring(#data.params.applications)..", expected " .. tostring(pExpNumOfApps)
    end
  end)
  common.wait()
end

local function setAppProperties(pAppId, pEnabled, pTimes, pExpNumOfApps)
  local webAppProperties = {
    nicknames = { "Test Application" },
    policyAppID = "000000" .. pAppId,
    enabled = pEnabled,
    transportType = "WS",
    hybridAppPreference = "CLOUD"
  }
  common.setAppProperties(webAppProperties)
  checkUpdateAppList(webAppProperties.policyAppID, pTimes, pExpNumOfApps)
end

local function unregisterApp(pAppID, pTimes, pExpNumOfApps)
  local cid = common.getMobileSession(1):SendRPC("UnregisterAppInterface", {})
  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered")
  checkUpdateAppList("000000" .. pAppID, pTimes, pExpNumOfApps)
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Update WS Server Certificate parameters in smartDeviceLink.ini file", common.commentAllCertInIniFile)
common.Step("Start SDL, HMI, connect regular mobile, start Session", common.startWOdeviceConnect)

common.Title("Test")
common.Step("UpdateAppList on setAppProperties for policyAppID1: modified enabled from false to true",
  setAppProperties, { 1, true, expected, 1 })
common.Step("UpdateAppList on setAppProperties for policyAppID1: modified enabled from false to true",
  setAppProperties, { 2, true, expected, 2 })
common.Step("Connect WebEngine device", common.connectWebEngine, { 1, config.defaultMobileAdapterType })
common.Step("RAI of web app1", common.registerApp, { 1, 1 })
common.Step("Activate web app1", common.activateApp, { 1 })
common.Step("Unregister App1", unregisterApp, { 2, expected, 2 })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
