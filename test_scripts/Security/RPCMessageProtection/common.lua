---------------------------------------------------------------------------------------------------
-- Common module
---------------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")
local common = require("test_scripts/Security/SSLHandshakeFlow/common")
local utils = require("user_modules/utils")
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local json = require("modules/json")
local test = require("user_modules/dummy_connecttest")

--[[ General configuration parameters ]]
config.SecurityProtocol = "DTLS"

--[[ Variables ]]
local m = actions
local preloadedPT = commonFunctions:read_parameter_from_smart_device_link_ini("PreloadedPT")

m.flags = { true, false, nil }

--[[ Common Functions ]]
function m.ptUpdate(pTbl)
  local filePath = "./files/Security/client_credential.pem"
  local crt = utils.readFile(filePath)
  pTbl.policy_table.module_config.certificate = crt
end

function m.backupPreloadedPT()
  commonPreconditions:BackupFile(preloadedPT)
end

function m.restorePreloadedPT()
  commonPreconditions:RestoreFile(preloadedPT)
end

function m.updatePreloadedPT(pAppPolicy, pFuncGroup)
  local preloadedFile = commonPreconditions:GetPathToSDL() .. preloadedPT
  local pt = utils.jsonFileToTable(preloadedFile)
  pt.policy_table.app_policies["0000001"] = utils.cloneTable(pt.policy_table.app_policies.default)
  pt.policy_table.functional_groupings["Base-4"].encryption_required = pFuncGroup
  pt.policy_table.app_policies["0000001"].encryption_required = pAppPolicy
  pt.policy_table.functional_groupings["DataConsent-2"].rpcs = json.null
  utils.tableToJsonFile(pt, preloadedFile)
end

function m.startServiceProtected(pServiceId)
  m.getMobileSession():StartSecureService(pServiceId)
  m.getMobileSession():ExpectHandshakeMessage()
  m.getMobileSession():ExpectControlMessage(pServiceId, {
    frameInfo = m.frameInfo.START_SERVICE_ACK,
    encryption = true
  })
end

function m.stopService(pServiceId)
  m.getMobileSession():StopService(pServiceId)
end

local preconditionsOrig = m.preconditions
function m.preconditions()
  preconditionsOrig()
  common.initSDLCertificates("./files/Security/client_credential.pem", false)
end

function m.spairs(pTbl)
  local keys = {}
  for k in pairs(pTbl) do
    keys[#keys+1] = k
  end
  local function getStringKey(pKey)
    return tostring(string.format("%03d", pKey))
  end
  table.sort(keys, function(a, b) return getStringKey(a) < getStringKey(b) end)
  local i = 0
  return function()
    i = i + 1
    if keys[i] then
      return keys[i], pTbl[keys[i]]
    end
  end
end

function m.cleanSessions()
  for i = 1, m.getAppsCount() do
    test.mobileSession[i]:StopRPC()
    :Do(function(_, d)
        utils.cprint(35, "Mobile session " .. d.sessionId .. " deleted")
        test.mobileSession[i] = nil
      end)
  end
  utils.wait()
end

return m
