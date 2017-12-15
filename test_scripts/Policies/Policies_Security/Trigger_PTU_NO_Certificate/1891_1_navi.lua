---------------------------------------------------------------------------------------------------
-- TBA
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Policies/Policies_Security/Trigger_PTU_NO_Certificate/common')
local runner = require('user_modules/script_runner')

--[[ Local Variables ]]
local serviceId = 7
local appHMIType = "NAVIGATION"

--[[ General configuration parameters ]]
config.application1.registerAppInterfaceParams.appHMIType = { appHMIType }

--[[ Local Functions ]]
local function ptUpdate(pTbl)
  pTbl.policy_table.app_policies[common.getAppID()].AppHMIType = { appHMIType }
	pTbl.policy_table.module_config.seconds_between_retries = nil
end

local function startServiceSecured()
  common.getMobileSession():StartSecureService(serviceId)
  common.getMobileSession():ExpectControlMessage(serviceId, {
    frameInfo = common.frameInfo.START_SERVICE_NACK,
    encryption = false
  })
  common.getMobileSession():ExpectHandshakeMessage()
  :Times(0)
  common.delayedExp()
end

local function expNotificationFunc()
  common.getHMIConnection():ExpectNotification("SDL.OnStatusUpdate",
    { status = "UPDATE_NEEDED" }, { status = "UPDATING" },
    { status = "UPDATE_NEEDED" }, { status = "UPDATING" })
  :Times(4)
end

--[[ Scenario ]]
runner.SetParameters({ isSelfIncluded = false })
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Set ForceProtectedService OFF", common.setForceProtectedServiceParam, { "Non" })
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)

runner.Title("Test")
runner.Step("Register App", common.registerApp)
runner.Step("PolicyTableUpdate fails", common.PolicyTableUpdate, { ptUpdate, expNotificationFunc })
runner.Step("StartService Secured NACK, no Handshake", startServiceSecured)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
