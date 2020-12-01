---------------------------------------------------------------------------------------------------
-- User story: https://github.com/CustomSDL/Sync3.2v2/issues/499
--
-- Description: App HMI status is not changing to none when exiting via VR
--
-- Steps:
-- 1. Default HMI level of SyncProxyTester is BACKGROUND
-- 2. SyncProxyTester app running in HMI Full on the phone and SYNC
-- 3. VR session is activated
-- 4. Perform Exit <SyncProxyTester)>
--
-- Expected result:
-- 1. OnHMIStatus notification for the SyncProxyTester app should be HMI Level=None and Not_Audible
--   after BC.OnExitApplication(USER_EXIT)
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Defects/commonDefects')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.application1.registerAppInterfaceParams.appHMIType = { "MEDIA" }

--[[ Local Functions ]]
local function sendOnExitApplication()
  common.getHMIConnection():SendNotification("UI.OnSystemContext",
    { systemContext = "VRSESSION", appID = common.getHMIAppId()})
  common.getHMIConnection():SendNotification("VR.Started",{})

  common.getHMIConnection():SendNotification("UI.OnSystemContext",
    { systemContext = "HMI_OBSCURED", appID = common.getHMIAppId()})

  common.getHMIConnection():SendNotification("UI.OnSystemContext",
    { systemContext = "VRSESSION", appID = common.getHMIAppId()})

  common.getMobileSession():ExpectNotification("OnHMIStatus",
    { hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "VRSESSION" },
    { hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "VRSESSION" },
    { hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "HMI_OBSCURED" },
    { hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "VRSESSION" },
    { hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" },
    { hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN" },
    { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
  :Do(function(exp)
    if exp.occurences == 1 then
      common.getHMIConnection():SendNotification("UI.OnSystemContext",
        { systemContext = "MAIN", appID = common.getHMIAppId()})

      common.getHMIConnection():SendNotification("VR.Stopped",{})

      common.getHMIConnection():SendNotification("BasicCommunication.OnExitApplication",
        {reason = "USER_EXIT", appID = common.getHMIAppId() })
    end
  end)
  :Times(7)

  common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered")
  :Times(0)

  common.getHMIConnection():ExpectRequest("BasicCommunication.ActivateApp")
  :Times(0)

  common.wait(5000)
end

local function updateDefaultHMILevelToBackground(tbl)
  tbl.policy_table.app_policies.default.default_hmi = "BACKGROUND"
end

function common.registerAppWOPTU(pAppId)
  if not pAppId then pAppId = 1 end
  common.getMobileSession(pAppId):StartService(7)
  :Do(function()
      local corId = common.getMobileSession(pAppId):SendRPC("RegisterAppInterface", common.getConfigAppParams(pAppId))
      common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppRegistered",
        { application = { appName = common.getConfigAppParams(pAppId).appName } })
      :Do(function(_, d1)
          common.setHMIAppId(d1.params.application.appID, pAppId)
        end)
      common.getMobileSession(pAppId):ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
      :Do(function()
          common.getMobileSession(pAppId):ExpectNotification("OnHMIStatus",
            { hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
          common.getMobileSession(pAppId):ExpectNotification("OnPermissionsChange")
        end)
    end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions, { updateDefaultHMILevelToBackground })
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.startWait)
runner.Step("App registration", common.registerAppWOPTU)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("USER_EXIT from HMI", sendOnExitApplication)
runner.Step("Activation after exit", common.activateApp)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
