---------------------------------------------------------------------------------------------------
	--  Precondition: 
	--  1) Application 1 with <appID> is registered on SDL.
	--  2) Application 2 with <appID2> is registered on SDL.
	--  3) Specific permissions are assigned for <appID> with PublishAppService
	--  4) Specific permissions are assigned for <appID2> with GetAppServiceData
	--
	--  Steps:
	--  1) Application 1 sends a PublishAppService RPC request with serviceType MEDIA
	--  2) Application 2 sends a GetAppServiceData RPC request with serviceType MEDIA
	--
	--  Expected:
	--  1) SDL forwards the GetAppServiceData request to Application 1
	--  2) Application 1 sends a GetAppServiceData response (SUCCESS) to Core with its own serviceData
	--  3) SDL forwards the response to Application 2
	---------------------------------------------------------------------------------------------------
	
	--[[ Required Shared libraries ]]
	local runner = require('user_modules/script_runner')
	local common = require('test_scripts/AppServices/commonAppServices')
	
	--[[ Test Configuration ]]
	runner.testSettings.isSelfIncluded = false
	
	--[[ Local Variables ]]
	local manifest = {
	  serviceName = config.application1.registerAppInterfaceParams.appName,
	  serviceType = "MEDIA",
	  allowAppConsumers = true,
	  rpcSpecVersion = config.application1.registerAppInterfaceParams.syncMsgVersion,
	  mediaServiceManifest = {}
	}
	
	local rpc = {
	  name = "OnAppServiceData"
	}
	
	local expectedNotification = {
	  serviceData = {
	    serviceType = manifest.serviceType,
	    mediaServiceData = {
	      mediaType = "MUSIC",
	      mediaTitle = "Song name",
	      mediaArtist = "Band name",
	      mediaAlbum = "Album name",
	      playlistName = "Good music",
	      isExplicit = false,
	      trackPlaybackProgress = 200,
	      trackPlaybackDuration = 300,
	      queuePlaybackProgress = 2200,
	      queuePlaybackDuration = 4000,
	      queueCurrentTrackNumber = 12,
        queueTotalTrackCount = 20,
        futureMediaData = "Future media data"
      },
      futureNotificationStruct = {
        futureStructItem = "Future struct item"
      }
	  }
	}
	
	local function PTUfunc(tbl)
	  tbl.policy_table.app_policies[common.getConfigAppParams(1).fullAppID] = common.getAppServiceProducerConfig(1);
	  tbl.policy_table.app_policies[common.getConfigAppParams(2).fullAppID] = common.getAppServiceConsumerConfig(2);
	end
	
	--[[ Local Functions ]]
	local function processRPCSuccess(self)
	  local mobileSession = common.getMobileSession(1)
	  local mobileSession2 = common.getMobileSession(2)
	  local service_id = common.getAppServiceID()
	  local notificationParams = expectedNotification
	  notificationParams.serviceData.serviceID = service_id
	
	  mobileSession:SendNotification(rpc.name, notificationParams)
	  mobileSession2:ExpectNotification(rpc.name, notificationParams)
	end
	
	--[[ Scenario ]]
	runner.Title("Preconditions")
	runner.Step("Clean environment", common.preconditions)
	runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
	runner.Step("RAI", common.registerApp)
	runner.Step("PTU", common.policyTableUpdate, { PTUfunc })
	runner.Step("RAI w/o PTU", common.registerAppWOPTU, { 2 })
	runner.Step("Activate App", common.activateApp)
	runner.Step("Publish App Service", common.publishMobileAppService, { manifest })
  runner.Step("Subscribe App Service Data", common.mobileSubscribeAppServiceData, { 1, 2 })
  runner.Step("Set config.ValidateSchema = false", common.setValidateSchema, {false})
	
	runner.Title("Test")
	runner.Step("RPC " .. rpc.name .. "_resultCode_SUCCESS", processRPCSuccess)
	
	runner.Title("Postconditions")
	runner.Step("Stop SDL", common.postconditions)