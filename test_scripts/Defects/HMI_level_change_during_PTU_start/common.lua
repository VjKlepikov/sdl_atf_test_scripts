---------------------------------------------------------------------------------------------------
-- Common module
---------------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2
config.checkAllValidations = true

--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")
local utils = require('user_modules/utils')

--[[ Local Variables ]]
local commonDefect = actions
commonDefect.timeToSendNotif = {
  0, 1, 2, 3, 4, 5, 7, 10, 13, 15, 17, 20, 25, 30, 35, 50, 70, 85, 100, 110, 120, 150, 175, 200, 250, 300, 350, 400
}

--[[ App configuration parameters ]]
-- Navigation app
config.application2.registerAppInterfaceParams.appHMIType = { "NAVIGATION" }
config.application1.registerAppInterfaceParams.isMediaApplication = false
-- Non-media app
config.application2.registerAppInterfaceParams.appHMIType = { "DEFAULT" }
config.application2.registerAppInterfaceParams.isMediaApplication = false
-- Media app
config.application3.registerAppInterfaceParams.appHMIType = { "DEFAULT" }
config.application3.registerAppInterfaceParams.isMediaApplication = true
-- Communication app
config.application4.registerAppInterfaceParams.appHMIType = { "COMMUNICATION" }
config.application4.registerAppInterfaceParams.isMediaApplication = false

--[[ Common Functions ]]
function utils.getDeviceName()
  return config.mobileHost
end

function commonDefect.onEventChangeAvailableFalse()
  commonDefect.getHMIConnection():SendNotification("BasicCommunication.OnEventChanged",
    { isActive = false, eventName = "PHONE_CALL" })
  commonDefect.getMobileSession(1):ExpectNotification("OnHMIStatus",
    { hmiLevel = "LIMITED", systemContext = "MAIN" })
  commonDefect.getMobileSession(2):ExpectNotification("OnHMIStatus")
  :Times(0)
  commonDefect.getMobileSession(3):ExpectNotification("OnHMIStatus",
    { hmiLevel = "LIMITED", systemContext = "MAIN" })
  commonDefect.getMobileSession(4):ExpectNotification("OnHMIStatus",
    { hmiLevel = "FULL", systemContext = "MAIN" })
end

return commonDefect
