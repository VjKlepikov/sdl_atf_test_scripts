---------------------------------------------------------------------------------------------------
-- User story:https://github.com/CustomSDL/Sync3.2v2/issues/775
--
-- Description:
-- [AddCommand] SUCCESS: getting SUCCESS on VR and UI.AddCommand() in 9 seconds
--
-- Steps:
-- 1) HMI and SDL are started
-- 2) App is registered and activated.
--
-- Steps:
-- App requests AddCommand with the both vrCommands and menuParams
-- SDL sends to HMI UI.AddCommad to HMI
-- HMI sends responses for UI.AddCommad to SDL in 9 seconds
--
-- Expected:
-- SDL responds with 'SUCCESS, success:true' to mobile application.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Defects_775/commonDefects')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local timeRunAfter = 9000

local addCommandParam =
  {
    cmdID = 1,
    menuParams = {
      position = 0,
      menuName ="Command1"
    }
  }

--[[ Local Functions ]]
local function addCommand(pParams)
  local cid = common.getMobileSession():SendRPC("AddCommand", pParams)
  common.getHMIConnection():ExpectRequest("UI.AddCommand")
  :Do(function(_,data)
    local function sendResponseUI()
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end
      RUN_AFTER(sendResponseUI, timeRunAfter)
    end)
  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.startWait)
runner.Step("App registration", common.registerApp)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("AddCommand success", addCommand, { addCommandParam })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
