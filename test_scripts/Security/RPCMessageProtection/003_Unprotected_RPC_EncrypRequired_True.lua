---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0207-rpc-message-protection.md
-- Description:
-- In case:
-- 1)
-- SDL does:
-- 1)
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Security/RPCMessageProtection/common')
local utils = require("user_modules/utils")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function ptUpdate(pTbl)
  local filePath = "./files/Security/client_credential.pem"
  local crt = utils.readFile(filePath)
  pTbl.policy_table.module_config.certificate = crt
  local appId = config.application1.registerAppInterfaceParams.fullAppID
  -- pTbl.policy_table.functional_groupings.encryption_required = true
  pTbl.policy_table.app_policies[appId].encryption_required = true
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("Policy Table Update Certificate", common.policyTableUpdate, { ptUpdate })
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("Start RPC Service protected", common.startServiceProtected, { 7 })
runner.Step("Process RPC in unprotected mode", common.rpcInUnprotectedMode)
runner.Step("Process RPC in protected mode", common.rpcInProtectedModeSuccess)

runner.Title("Postconditions")
runner.Step("Stop SDL, restore SDL settings", common.postconditions)
