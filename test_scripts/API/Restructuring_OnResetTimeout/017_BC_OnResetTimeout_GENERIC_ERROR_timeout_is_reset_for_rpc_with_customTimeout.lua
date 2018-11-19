---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0189-Restructuring-OnResetTimeout.md
--
-- Description:
-- In case:
-- 1) RPC is requested
-- 2) Time of the default timeout 10 sec after receiving RPC request on HMI is passed
-- 3) HMI sends BC.OnResetTimeout(resetPeriod = 7000) to SDL
-- 4) HMI does not send response
-- SDL does:
-- 1) Respond with GENERIC_ERROR resultCode to mobile app after 17 seconds
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/Restructuring_OnResetTimeout/common_OnResetTimeout')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local paramsForRespFunction = {
  notificationTime = 10500,
  resetPeriod = 7000
}

local rpcResponse = { success = false, resultCode = "GENERIC_ERROR" }

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App_1 registration", common.registerAppWOPTU)
runner.Step("App_2 registration", common.registerAppWOPTU, { 2 })
runner.Step("App_1 activation", common.activateApp)
runner.Step("Create InteractionChoiceSet", common.createInteractionChoiceSet)

runner.Title("Test")
runner.Step("Send PerformInteraction" , common.rpcs.PerformInteraction,
  { 18000, 7000, common.withoutResponseWithOnResetTimeout, paramsForRespFunction, rpcResponse })
runner.Step("Send ScrollableMessage" , common.rpcs.ScrollableMessage,
  { 18000, 7000, common.withoutResponseWithOnResetTimeout, paramsForRespFunction, rpcResponse })
runner.Step("Send Alert" , common.rpcs.Alert,
  { 18000, 7000, common.withoutResponseWithOnResetTimeout, paramsForRespFunction, rpcResponse })
runner.Step("Send Slider" , common.rpcs.Slider,
  { 18000, 7000, common.withoutResponseWithOnResetTimeout, paramsForRespFunction, rpcResponse })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
