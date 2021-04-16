---------------------------------------------------------------------------------------------------
-- Common module
---------------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2
config.checkAllValidations = true

--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")
local utils = require('user_modules/utils')
local test = require("user_modules/dummy_connecttest")
local events = require('events')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local json = require("modules/json")
local atf_logger = require("atf_logger")

--[[ Local Variables ]]
local commonDefect = actions
commonDefect.wait = utils.wait
commonDefect.cloneTable = utils.cloneTable
commonDefect.getDeviceMAC = utils.getDeviceMAC
local preloadedPT = commonFunctions:read_parameter_from_smart_device_link_ini("PreloadedPT")

--[[ @unexpectedDisconnect: closing connection
--! @parameters: none
--! @return: none
--]]
function commonDefect.unexpectedDisconnect(pFunction)
  commonDefect.log("start unexpectedDisconnect")
  test.mobileConnection:Close()
  commonDefect.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered", { unexpectedDisconnect = true })
  :Do(function()
    commonDefect.log("SDL->HMI: N BC.OnAppUnregistered")
      if pFunction then
        pFunction()
      end
      for i = 1, commonDefect.getAppsCount() do
        test.mobileSession[i] = nil
      end
    end)
end

--[[ @connectMobile: create connection
--! @parameters: none
--! @return: none
--]]
function commonDefect.connectMobile()
  test.mobileConnection:Connect()
  EXPECT_EVENT(events.connectedEvent, "Connected")
  :Do(function()
      utils.cprint(35, "Mobile connected")
    end)
end

--[[ @preconditions: delete logs, backup preloaded file, update preloaded
--! @parameters: none
--! updateFunction - update preloadedPT
--! @return: none
--]]
local preconditionsOrig = commonDefect.preconditions
function commonDefect.preconditions(pUpdateFunction)
  preconditionsOrig()
  commonPreconditions:BackupFile(preloadedPT)
  if pUpdateFunction then
    commonDefect.updatePreloadedPT(pUpdateFunction)
  end
end

--[[ @updatePreloadedPT: update preloaded file with custom permissions
--! @parameters:
--! updateFunction - update preloadedPT
--! @return: none
--]]
function commonDefect.updatePreloadedPT()
  local preloadedFile = commonPreconditions:GetPathToSDL() .. preloadedPT
  local pt = utils.jsonFileToTable(preloadedFile)
  pt.policy_table.functional_groupings["DataConsent-2"].rpcs = json.null

  local appID = actions.getConfigAppParams(1).appID
  pt.policy_table.app_policies[appID] = utils.cloneTable(pt.policy_table.app_policies.default)
  pt.policy_table.app_policies[appID].groups = { "Base-4" }
  pt.policy_table.app_policies[appID].keep_context = true
  pt.policy_table.app_policies[appID].steal_focus = true

  utils.tableToJsonFile(pt, preloadedFile)
end

--[[ @postconditions: stop SDL if it's not stopped, restore preloaded file
--! @parameters: none
--! @return: none
--]]
local postconditionsOrig = commonDefect.postconditions
function commonDefect.postconditions()
  postconditionsOrig()
  commonPreconditions:RestoreFile(preloadedPT)
end

function commonDefect.expectOnHMIStatusWithAudioStateChanged(pAppId, request, level)
  if pAppId == nil then pAppId = 1 end
  if request == nil then request = "BOTH" end
  if level == nil then level = "FULL" end

  local mobSession = commonDefect.getMobileSession(pAppId)
  local appParams = config["application" .. pAppId].registerAppInterfaceParams

  if appParams.isMediaApplication == true then
    if request == "BOTH" then
      mobSession:ExpectNotification("OnHMIStatus",
        { systemContext = "ALERT", hmiLevel = level, audioStreamingState = "AUDIBLE" },
        { systemContext = "ALERT", hmiLevel = level, audioStreamingState = "ATTENUATED" },
        { systemContext = "ALERT", hmiLevel = level, audioStreamingState = "AUDIBLE" },
        { systemContext = "MAIN", hmiLevel = level, audioStreamingState = "AUDIBLE" })
      --:Times(4)
      :Times(AnyNumber())
    elseif request == "speak" then
      mobSession:ExpectNotification("OnHMIStatus",
        { systemContext = "MAIN", hmiLevel = level, audioStreamingState = "ATTENUATED" },
        { systemContext = "MAIN", hmiLevel = level, audioStreamingState = "AUDIBLE" })
      --:Times(2)
      :Times(AnyNumber())
    elseif request == "alert" then
      mobSession:ExpectNotification("OnHMIStatus",
        { systemContext = "ALERT", hmiLevel = level, audioStreamingState = "AUDIBLE" },
        { systemContext = "MAIN", hmiLevel = level, audioStreamingState = "AUDIBLE" })
      --:Times(2)
      :Times(AnyNumber())
    end
  elseif appParams.isMediaApplication == false then
    if request == "BOTH" then
      mobSession:ExpectNotification("OnHMIStatus",
        { systemContext = "ALERT", hmiLevel = level, audioStreamingState = "NOT_AUDIBLE" },
        { systemContext = "MAIN", hmiLevel = level, audioStreamingState = "NOT_AUDIBLE" })
      --:Times(2)
      :Times(AnyNumber())
    elseif request == "speak" then
      mobSession:ExpectNotification("OnHMIStatus")
      :Times(0)
    elseif request == "alert" then
      mobSession:ExpectNotification("OnHMIStatus",
        { systemContext = "ALERT", hmiLevel = level, audioStreamingState = "NOT_AUDIBLE" },
        { systemContext = "MAIN", hmiLevel = level, audioStreamingState = "NOT_AUDIBLE" })
      --:Times(2)
      :Times(AnyNumber())
    end
  end
end

function commonDefect.putFile(params, pAppId, self)
  if not pAppId then pAppId = 1 end
  local mobileSession = commonDefect.getMobileSession(pAppId, self);
  local cid = mobileSession:SendRPC("PutFile", params.requestParams, params.filePath)

  mobileSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
end

function commonDefect.log(...)
  local str = "[" .. atf_logger.formated_time(true) .. "]"
  for i, p in pairs({...}) do
    local delimiter = "\t"
    if i == 1 then delimiter = " " end
    str = str .. delimiter .. p
  end
  utils.cprint(35, str)
end

return commonDefect
