---------------------------------------------------------------------------------------------------
-- User story: https://github.com/CustomSDL/Sync3.2v2/issues/499
--
-- Description: App HMI status is not changing to none when exiting via VR
--
-- Steps:
-- 1. Default HMI level of SyncProxyTester is NONE
-- 2. SyncProxyTester app running in HMI Full on the phone and SYNC
-- 3. VR session is activated
-- 4. AUDIO_SOURCE is activated
-- 5. Perform Exit <SyncProxyTester)>
-- 6. AUDIO_SOURCE is deactivated
-- 7. SDL starts resume FULL HMI level after AUDIO_SOURCE deactivation
-- 8. HMI sends BC.OnExitApplication(USER_EXIT) after BC.ActivateApp request
--   and then answer with success result code to BC.ActivateApp
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

  common.getHMIConnection():SendNotification("UI.OnSystemContext",
    { systemContext = "MAIN", appID = common.getHMIAppId()})

  common.getHMIConnection():SendNotification("UI.OnSystemContext",
    { systemContext = "VRSESSION", appID = common.getHMIAppId()})

  common.getHMIConnection():SendNotification("BasicCommunication.OnEventChanged",
    {isActive = false, eventName = "AUDIO_SOURCE"})

  common.getMobileSession():ExpectNotification("OnHMIStatus",
    { hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" },
    { hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN" },
    { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
  :Do(function(exp)
    if exp.occurences == 1 then
      common.getHMIConnection():SendNotification("UI.OnSystemContext",
        { systemContext = "MAIN", appID = common.getHMIAppId()})

      common.getHMIConnection():SendNotification("VR.Stopped",{})
    end
  end)
  :Times(3)

  common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered")
  :Times(0)

  common.getHMIConnection():ExpectRequest("BasicCommunication.ActivateApp")
  :Do(function(_,data)
    common.getHMIConnection():SendNotification("BasicCommunication.OnExitApplication",
        {reason = "USER_EXIT", appID = common.getHMIAppId() })
     local function bcActivateAppresp()
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })
    end
    RUN_AFTER(bcActivateAppresp, 2000)
  end)

  common.wait(5000)
end

local function audioSourceEventStart()
  common.getHMIConnection():SendNotification("BasicCommunication.OnEventChanged",
    {isActive = true, eventName = "AUDIO_SOURCE"})

  common.getMobileSession():ExpectNotification("OnHMIStatus",
    { hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.startWait)
runner.Step("App registration", common.registerApp)
runner.Step("Activate App", common.activateApp)
runner.Step("Audio source event start", audioSourceEventStart)

runner.Title("Test")
runner.Step("USER_EXIT from HMI", sendOnExitApplication)
runner.Step("Activation after exit", common.activateApp)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
