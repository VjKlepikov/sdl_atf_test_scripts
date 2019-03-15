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
local funcGroup = true

--[[Local Function]]
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
runner.Step("Init SDL certificates", common.initSDLCertificates,
    { "./files/Security/client_credential.pem" })
runner.Step("Preloaded update", common.updatePreloadedPT, { appPolicy, funcGroup })
runner.Step("Start SDL, init HMI", common.start)
runner.Step("Register App", common.registerAppWOPTU)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("Start RPC Service protected", common.startServiceProtected, { 7 })
runner.Step("Unprotected RPC in protected mode", unprotectedRpcInProtectedMode)

runner.Title("Postconditions")
runner.Step("Clean sessions", common.cleanSessions)
runner.Step("Stop SDL, restore SDL settings", common.postconditions)
runner.Step("Restore PreloadedPT", common.restorePreloadedPT)
