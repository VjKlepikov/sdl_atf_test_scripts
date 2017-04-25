-- This script contains common consants for test scripts
--------------------------------------------------------------------------------
local common_functions = require('user_modules/common_functions')

local Consts = {

  color = {
    black = 30,
    red = 31,
    green = 32,
    yellow = 33,
    blue = 34,
    magenta = 35,
    cyan = 36,
    white = 37
  },

  image_icon_png = "icon.png",

  sdl_to_mobile_default_timeout = 5000,

  default_app_name = config.application1.registerAppInterfaceParams.appName,

  default_app = config.application1.registerAppInterfaceParams,

  endpoints_rpc_url = common_functions:GetParameterValueInJsonFile(
    config.pathToSDL .. "sdl_preloaded_pt.json",
    {"policy_table", "module_config", "endpoints", "0x07", "default", 1}),

  precondition = {
    START_SDL = 1,
    INIT_HMI = 2,
    INIT_HMI_ONREADY = 3,
    CONNECT_MOBILE = 4,
    ADD_MOBILE_SESSION = 5,
    REGISTER_APP = 6,
    ACTIVATE_APP = 7
  }

}
-----------------------------------------------------------------------------
return Consts
