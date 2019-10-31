---------------------------------------------------------------------------------------------------
-- User story: https://github.com/CustomSDL/Sync3.2v2/issues/516
-- Precondition:
-- 1. HMI and SDL are started
-- 2. Apps are registered
-- 3. Perform ignition off
-- 4. Perform ignition on
-- 5. Register apps again after ignition on
--
-- Steps:
-- 1. Perform ignition off
-- 2. Perform ignition on
--
-- Expected:
-- SDL saves app with ign_off_count=1 to app_info.data
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Defects/commonDefects')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local utils = require("user_modules/utils")
local test = require("user_modules/dummy_connecttest")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
common.getConfigAppParams(1).isMediaApplication = false
common.getConfigAppParams(2).isMediaApplication = false
common.getConfigAppParams(3).appHMIType = { "DEFAULT" }

--[[ Local Variables ]]
local appsCount = 3
local requestParams = {
  menuID = 1000,
  position = 500,
  menuName ="SubMenupositive"
}

local responseUiParams = {
  menuID = requestParams.menuID,
  menuParams = {
    position = requestParams.position,
    menuName = requestParams.menuName
  }
}

--[[ Local Functions ]]
local function addSubMenu()
  local cid = common.getMobileSession():SendRPC("AddSubMenu", requestParams)

  responseUiParams.appID = common.getHMIAppId()
  EXPECT_HMICALL("UI.AddSubMenu", responseUiParams)
  :Do(function(_,data)
    common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
  end)

  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
  common.getMobileSession():ExpectNotification("OnHashChange")
  :Do(function(_,data)
      common.getConfigAppParams().hashID = data.payload.hashID
    end)
end

local function checkAppInfoDat()
  local appInfoDat = commonPreconditions:GetPathToSDL() .. "app_info.dat"
  if utils.isFileExist(appInfoDat) then
    local tbl = utils.jsonFileToTable(appInfoDat)
    if tbl.resumption.resume_app_list[1].appID == common.getConfigAppParams(1).appID and
      tbl.resumption.resume_app_list[1].ign_off_count == 1 then
        utils.cprint(35, "Actual ign_off_count value is saved for app")
    else
      test:FailTestCase("Wrong resumption data is saved for app. AppID is " ..
        tbl.resumption.resume_app_list[1].appID .. ",\n expected ign_off_count value is 1, \n" ..
        "  actual ign_off_count value is " .. tbl.resumption.resume_app_list[1].ign_off_count )
    end
  else
    test:FailTestCase("app_info.dat file was not found")
  end
end

local function registerApps()
  local corId1 = common.getMobileSession(1):SendRPC("RegisterAppInterface", common.getConfigAppParams(1))
  local corId2 = common.getMobileSession(2):SendRPC("RegisterAppInterface", common.getConfigAppParams(2))
  local corId3 = common.getMobileSession(3):SendRPC("RegisterAppInterface", common.getConfigAppParams(3))

  common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppRegistered")
  :Times(3)

  common.getMobileSession(1):ExpectResponse(corId1, { success = true, resultCode = "SUCCESS" })
  common.getMobileSession(2):ExpectResponse(corId2, { success = true, resultCode = "SUCCESS" })
  common.getMobileSession(3):ExpectResponse(corId3, { success = true, resultCode = "SUCCESS" })
end

local function startMobileSession(pAppId)
  common.getMobileSession(pAppId):StartService(7)
end

local function registerAppWithResumption()
  registerApps()

  common.getHMIConnection():ExpectRequest("BasicCommunication.ActivateApp")
  :Do(function(_,data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)

  common.getHMIConnection():ExpectRequest("UI.AddSubMenu", responseUiParams)
  :Do(function(_,data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)

  common.getMobileSession(3):ExpectNotification("OnHMIStatus",
    { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" },
    { hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN" })
    :Times(2)

  common.getMobileSession(2):ExpectNotification("OnHMIStatus",
    { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" },
    { hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN" })
    :Times(2)

  common.getMobileSession(1):ExpectNotification("OnHMIStatus",
    { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
for i=1, appsCount do
  runner.Step("App" .. tostring(i) .. " registration", common.registerApp, { i })
end

runner.Title("Test")
runner.Step("ignitionOff", common.ignitionOff)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
for i=1, appsCount do
  runner.Step("App" .. tostring(i) .. " reregistration", common.registerApp, { i })
end
for i=1, appsCount do
  runner.Step("Activate App" .. tostring(i), common.activateApp, { i })
end
runner.Step("AddSubMenu", addSubMenu)

runner.Step("ignitionOff", common.ignitionOff)
runner.Step("checkAppInfoDat", checkAppInfoDat)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
for i=1, appsCount do
  runner.Step("Start Session " .. tostring(i), startMobileSession, { i })
end
runner.Step("Data resumption during registration", registerAppWithResumption)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
