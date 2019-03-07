---------------------------------------------------------------------------------------------------
-- Common module
---------------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")
local utils = require("user_modules/utils")
local common = require("test_scripts/Security/SSLHandshakeFlow/common")

--[[ General configuration parameters ]]
config.SecurityProtocol = "DTLS"

--[[ Variables ]]
local m = actions

--[[ Common Functions ]]
function m.ptUpdate(pTbl)
  local filePath = "./files/Security/client_credential.pem"
  local crt = utils.readFile(filePath)
  pTbl.policy_table.module_config.certificate = crt
  -- pTbl.policy_table.functional_groupings.encryption_required = true
  pTbl.policy_table.app_policies[config.application1.registerAppInterfaceParams.fullAppID].encryption_required = true
end

function m.startServiceProtected(pServiceId)
  m.getMobileSession():StartSecureService(pServiceId)
  m.getMobileSession():ExpectHandshakeMessage()
  m.getMobileSession():ExpectControlMessage(pServiceId, {
    frameInfo = m.frameInfo.START_SERVICE_ACK,
    encryption = true
  })
end

local preconditionsOrig = m.preconditions
function m.preconditions()
  preconditionsOrig()
  common.initSDLCertificates("./files/Security/client_credential.pem", false)
end

return m
