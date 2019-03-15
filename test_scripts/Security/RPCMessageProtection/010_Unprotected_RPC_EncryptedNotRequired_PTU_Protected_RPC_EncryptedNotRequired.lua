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

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[Local Variables]]
local appPolicy = true
local funcGroup = false

--[[ Local Functions ]]
local function ptUpdate(pTbl)
  local appId = config.application1.registerAppInterfaceParams.fullAppID
  -- pTbl.policy_table.functional_groupings.encryption_required = nil
  pTbl.policy_table.app_policies[appId].encryption_required = nil
end

local function protectedRpcInProtectedMode()
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

local function unprotectedRpcInUnprotectedMode()
	local params = {
    cmdID = 1,
    menuParams = {
      position = 1,
      menuName = "Command_1"
    }
  }
  local cid = common.getMobileSession():SendRPC("AddCommand", params)
  common.getHMIConnection():ExpectRequest("UI.AddCommand", params)
  :Do(function(_, data)
    common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })
  end)
  common.getMobileSession():ExpectEncryptedResponse(cid, { success = true, resultCode = "SUCCESS" })
  common.getMobileSession():ExpectEncryptedNotification("OnHashChange")
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Back-up PreloadedPT", common.backupPreloadedPT)
runner.Step("Init SDL certificates", common.initSDLCertificates,
{ "./files/Security/client_credential.pem", true })
runner.Step("Preloaded update", common.updatePreloadedPT, { appPolicy, funcGroup })
runner.Step("Start SDL, init HMI", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("Activate App", common.activateApp)
runner.Step("Unprotected RPC in unprotected mode", unprotectedRpcInUnprotectedMode)
runner.Step("Start RPC Service protected", common.startServiceProtected, { 7 })

runner.Title("Test")

runner.Step("Policy Table Update", common.policyTableUpdate, { ptUpdate })
runner.Step("Protected RPC in protected mode", protectedRpcInProtectedMode)

runner.Title("Postconditions")
runner.Step("Clean sessions", common.cleanSessions)
runner.Step("Stop SDL, restore SDL settings", common.postconditions)
runner.Step("Restore PreloadedPT", common.restorePreloadedPT)
