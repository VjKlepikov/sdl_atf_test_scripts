---------------------------------------------------------------------------------------------------
-- User story: https://github.com/CustomSDL/Sync3.2v2/issues/489
-- Precondition:
-- 1. On HMI UI language is English, VR and TTS language is German
-- 2. Phone is connected
-- 3. SPT registered on SYNC (Language DE-DE, HMI Language EN-US)
-- 4. DataConsent and Permissions are accepted
--
-- Steps:
-- 1. Select SyncProxyTester (HMI Full)
-- 2. Change HMI UI language to German(HMI sends OnLanguageChange notifications)
-- 3. Reregister App (Language DE-DE, HMI Language EN-US)
-- 4. Restore UI language on HMI (HMI sends OnLanguageChange notifications)
-- 5. Change HMI VR and TTS language to English(HMI sends OnLanguageChange notifications)
-- 6. Restore HMI VR and TTS language (HMI sends OnLanguageChange notifications)
--
-- Expected result:
-- 1. App received OnLanguageChange notifications by each language change
-- 2. SPT is unregistered with reason LANGUAGE_CHANGE during language change
--   when the app language is not equal to the actual one on HMI
-- 3. SPT is reregistered with resultCode WRONG_LANGUAGE after language change
--   when the app language is not equal to the actual one on HMI
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Defects/commonDefects')
local hmi_values = require("user_modules/hmi_values")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.application1.registerAppInterfaceParams.languageDesired = "DE-DE"
config.application1.registerAppInterfaceParams.hmiDisplayLanguageDesired = "EN-US"

--[[ Local Variables ]]
local hmi_table = hmi_values.getDefaultHMITable()
hmi_table.VR.GetLanguage.params = {
  language = "DE-DE"
}
hmi_table.TTS.GetLanguage.params = {
  language = "DE-DE"
}

--[[ Local Functions ]]
local function changeLanguage(pLanguage, pUnregisteMessageNumber, pChangeType)
  common.getHMIConnection():SendNotification("BasicCommunication.OnSystemInfoChanged", { language = pLanguage })
  if pChangeType == "UI" then
    common.getHMIConnection():SendNotification("UI.OnLanguageChange", { language = pLanguage })
    common.getMobileSession():ExpectNotification("OnLanguageChange",
      { language = "DE-DE", hmiDisplayLanguage = pLanguage })
  else
    common.getHMIConnection():SendNotification("VR.OnLanguageChange", { language = pLanguage })
    common.getHMIConnection():SendNotification("TTS.OnLanguageChange", { language = pLanguage })
    common.getMobileSession():ExpectNotification("OnLanguageChange",
      { language = pLanguage, hmiDisplayLanguage = "EN-US" })
    :Times(2)
  end

  common.getMobileSession():ExpectNotification("OnAppInterfaceUnregistered",{ reason = "LANGUAGE_CHANGE" })
  :Times(pUnregisteMessageNumber)

   common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered",
    { appID = common.getHMIAppId(), unexpectedDisconnect = false })
   :Times(pUnregisteMessageNumber)
end

local function registerAppWrongLanguage(pAppId)
  if not pAppId then pAppId = 1 end
  local corId = common.getMobileSession(pAppId):SendRPC("RegisterAppInterface", common.getConfigAppParams(pAppId))
  common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppRegistered",
    { application = { appName = common.getConfigAppParams(pAppId).appName } })
  :Do(function(_, d1)
      common.setHMIAppId(d1.params.application.appID, pAppId)
    end)
  common.getMobileSession(pAppId):ExpectResponse(corId, { success = true, resultCode = "WRONG_LANGUAGE" })
  :Do(function()
      common.getMobileSession(pAppId):ExpectNotification("OnHMIStatus",
        { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
      common.getMobileSession(pAppId):ExpectNotification("OnPermissionsChange")
    end)
end

local function deactivateApp()
  common.getHMIConnection():SendNotification("BasicCommunication.OnAppDeactivated",
    { appID = common.getHMIAppId(), reason = "GENERAL" })

  common.getMobileSession():ExpectNotification("OnHMIStatus",
    { hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { hmi_table })
runner.Step("App registration", common.registerApp)
runner.Step("Activate App", common.activateApp)
runner.Step("Deactivation app", deactivateApp)

runner.Title("Test")
runner.Step("Change Language with unregistration", changeLanguage, { "DE-DE", 1, "UI" })
runner.Step("App registration with WRONG_LANGUAGE", registerAppWrongLanguage)
runner.Step("Activate App after language change", common.activateApp)
runner.Step("Deactivation app", deactivateApp)
runner.Step("Restore language", changeLanguage, { "EN-US", 0, "UI" })
runner.Step("Activate App after language restore", common.activateApp)
runner.Step("Change Language with unregistration", changeLanguage, { "EN-US", 1 })
runner.Step("App registration with WRONG_LANGUAGE", registerAppWrongLanguage)
runner.Step("Activate App after language change", common.activateApp)
runner.Step("Deactivation app", deactivateApp)
runner.Step("Restore language", changeLanguage, { "DE-DE", 0 })
runner.Step("Activate App after language restore", common.activateApp)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
