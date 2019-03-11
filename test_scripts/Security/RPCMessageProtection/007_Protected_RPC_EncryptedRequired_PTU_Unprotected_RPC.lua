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

--[[Local Variables]]
local appPolicy = nil
local funcGroup = nil

--[[Local Function]]
local function ptUpdate(pTbl)
  local appId = config.application1.registerAppInterfaceParams.fullAppID
  -- pTbl.policy_table.functional_groupings["Base-4"].encryption_required = true
  -- pTbl.policy_table.app_policies[appId].encryption_required = true
end

local function rpcInProtectedModeSuccess()
	local params = {
    cmdID = 1,
    menuParams = {
      position = 1,
      menuName = "Command_1"
    }
  }
  local cid = common.getMobileSession():SendEncryptedRPC("AddCommand", params)
  common.getHMIConnection():ExpectRequest("UI.AddCommand", params)
  :Do(function(_, data)
    common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })
    end)
    common.getMobileSession():ExpectEncryptedResponse(cid, { success = true, resultCode = "SUCCESS" })
    common.getMobileSession():ExpectEncryptedNotification("OnHashChange")
end

local function unprotectedRpcInProtectedMode()
	local params = {
    cmdID = 1,
    menuParams = {
      position = 1,
      menuName = "Command_1"
    }
  }
  local cid = common.getMobileSession():SendRPC("AddCommand", params)
  common.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "ENCRYPTION_NEEDED" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Back-up PreloadedPT", common.backupPreloadedPT)
runner.Step("Preloaded update", common.updatePreloadedPT, { appPolicy, funcGroup })
runner.Step("Start SDL, init HMI", common.start)
runner.Step("Register App_1", common.registerApp, { 1 })
runner.Step("Policy Table Update Certificate", common.policyTableUpdate, { common.ptUpdate })
runner.Step("Activate App_1", common.activateApp, { 1 })
runner.Step("Start RPC Service protected", common.startServiceProtected, { 7 })
runner.Step("Protected RPC in protected mode", rpcInProtectedModeSuccess)

runner.Title("Test")
runner.Step("Register App_2", common.registerApp, { 2 })
runner.Step("Policy Table Update Certificate", common.policyTableUpdate, { ptUpdate })
runner.Step("Protected RPC in protected mode", unprotectedRpcInProtectedMode)

runner.Title("Postconditions")
runner.Step("Clean sessions", common.cleanSessions)
runner.Step("Stop SDL, restore SDL settings", common.postconditions)
runner.Step("Restore PreloadedPT", common.restorePreloadedPT)
