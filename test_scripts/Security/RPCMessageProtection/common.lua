---------------------------------------------------------------------------------------------------
-- Common module
---------------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")
local common = require("test_scripts/Security/SSLHandshakeFlow/common")

--[[ General configuration parameters ]]
config.SecurityProtocol = "DTLS"

--[[ Variables ]]
local m = actions

m.flags = { true, false, nil }

--[[ Common Functions ]]
function m.startServiceProtected(pServiceId)
  m.getMobileSession():StartSecureService(pServiceId)
  m.getMobileSession():ExpectHandshakeMessage()
  m.getMobileSession():ExpectControlMessage(pServiceId, {
    frameInfo = m.frameInfo.START_SERVICE_ACK,
    encryption = true
  })
end

function m.rpcInProtectedModeSuccess()
	local params = {
    cmdID = 1,
    menuParams = {
      position = 1,
      menuName = "Command_1"
    }
  }
  local cid = m.getMobileSession():SendEncryptedRPC("AddCommand", params)
  m.getHMIConnection():ExpectRequest("UI.AddCommand", params)
  :Do(function(_, data)
      m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })
    end)
  m.getMobileSession():ExpectEncryptedResponse(cid, { success = true, resultCode = "SUCCESS" })
  m.getMobileSession():ExpectEncryptedNotification("OnHashChange")
end

function m.rpcInUnprotectedMode()
	local params = {
    cmdID = 1,
    menuParams = {
      position = 1,
      menuName = "Command_1"
    }
  }
  local cid = m.getMobileSession():SendRPC("AddCommand", params)
  m.getHMIConnection():ExpectRequest("UI.AddCommand", params)
  m.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "ENCRYPTION_NEEDED" })
end

local preconditionsOrig = m.preconditions
function m.preconditions()
  preconditionsOrig()
  common.initSDLCertificates("./files/Security/client_credential.pem", false)
end

return m
