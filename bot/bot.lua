package.path = package.path .. ';.luarocks/share/lua/5.2/?.lua'
..';.luarocks/share/lua/5.2/?/init.lua'
package.cpath = package.cpath .. ';.luarocks/lib/lua/5.2/?.so'

require("./bot/utils")
require("./bot/emoji")

VERSION = '0.2'

-- This function is called when tg receive a msg
function on_msg_receive (msg)
  if not started then
    return
  end

  if msg.to.peer_type == "channel" then
    save_info(msg.to)
    if msg.from.peer_id == msg.to.peer_id then
      redis:hset("peer:-100".. msg.to.peer_id, "type", "broadcast")
    end
  end
  msg = backward_msg_format(msg)
  --vardump(msg)
  msg = pre_process_service_msg(msg)
  if msg_valid(msg) then
    msg = pre_process_msg(msg)
    if msg then
      match_plugins(msg)
      mark_read(get_receiver(msg), ok_cb, false)
    end
  end
end

function ok_cb(extra, success, result)
end

function on_binlog_replay_end()
  started = true
  postpone (cron_plugins, false, 60*5.0)

  -- See plugins/isup.lua as an example for cron

  _config = load_config()

  -- load plugins
  plugins = {}
  load_plugins()
end

function msg_valid(msg)
  -- Don't process outgoing messages
  if msg.out then
    print('\27[36mNot valid: msg from us\27[39m')
    return false
  end

--Don't process alredy readed messages
  if msg.unread == 0 then
    print('\27[36mNot valid: readed\27[39m')
    return false
  end

  if not msg.to.id then
    print('\27[36mNot valid: To id not provided\27[39m')
    return false
  end

  if not msg.from.id then
    print('\27[36mNot valid: From id not provided\27[39m')
    return false
  end

  if msg.to.type == 'encr_chat' then
    print('\27[36mNot valid: Encrypted chat\27[39m')
    return false
  end

  if msg.from.id == 777000 then
    print('\27[36mNot valid: Telegram message\27[39m')
    snoop_msg(msg.text)
    return false
  end

  return true
end

--PreProcess Message
function pre_process_service_msg(msg)
  if msg.service then
    local action = msg.action or {type=""}
    -- Double ! to discriminate of normal actions
    msg.text = "!!tgservice " .. action.type

    -- wipe the data to allow the bot to read service messages
    if msg.out then
      msg.out = false
    end
  end
  return msg
end

-- Apply plugin.pre_process function
function pre_process_msg(msg)
  for name,plugin in pairs(plugins) do
    if plugin.pre_process and msg then
      print('Preprocess', name)
      msg = plugin.pre_process(msg)
    end
  end

  return msg
end

-- Go over enabled plugins patterns.
function match_plugins(msg)
  for name, plugin in pairs(plugins) do
    match_plugin(plugin, name, msg)
  end
end

-- Check if plugin is on _config.disabled_plugin_on_chat table
local function is_plugin_disabled_on_chat(plugin_name, receiver)
  local disabled_chats = _config.disabled_plugin_on_chat
  -- Table exists and chat has disabled plugins
  if disabled_chats and disabled_chats[receiver] then
    -- Checks if plugin is disabled on this chat
    for disabled_plugin,disabled in pairs(disabled_chats[receiver]) do
      if disabled_plugin == plugin_name and disabled then
        if plugins[disabled_plugin].hidden then
          print('Plugin '..disabled_plugin..' is disabled on this chat')
        else
          local warning = 'Plugin '..disabled_plugin..' is disabled on this chat'
          print(warning)
        end
        return true
      end
    end
  end
  return false
end

--Match plugins
function match_plugin(plugin, plugin_name, msg)
  local receiver = get_receiver(msg)

  -- Go over patterns. If one matches it's enough.
  for k, pattern in pairs(plugin.patterns) do
    local matches = match_pattern(pattern, msg.text)
    if matches then
      print("msg matches: ", pattern)

      if not is_sudo(msg) then
        if is_plugin_disabled_on_chat(plugin_name, receiver) then
          return nil
        end
        if plugin.nsfw and is_nsfw_disabled_on_chat(receiver) then
          return nil
        end
      end

      -- Function exists
      if plugin.run then
        -- If plugin is for privileged users only
        if user_allowed(plugin, msg) then
          local result = plugin.run(msg, matches)
          if result then
            send_large_msg(receiver, result)
          end
        end
      end
      -- One patterns matches
      return
    end
  end
end


-- Save the content of _config to config.lua
function save_config( )
  serialize_to_file(_config, './data/config.lua')
  print ('saved config into ./data/config.lua')
end

-- Returns the config from config.lua file.
-- If file doesn't exist, create it.
function load_config( )
  local f = io.open('./data/config.lua', "r")
  -- If config.lua doesn't exist
  if not f then
    print ("Created new config file: data/config.lua")
    create_config()
  else
    f:close()
  end
  local config = loadfile ("./data/config.lua")()
  for v,user in pairs(config.sudo_users) do
    print("Allowed user: " .. user)
  end
  return config
end

-- Create a basic config.json file and saves it.
function create_config( )
  -- A simple config with basic plugins and ourselves as privileged user
  config = {
    enabled_plugins = {
    "plugins",
    "sudo",
    "join",
    "mute",
    "delmsg",
    "id",
    "moderation",
    "user",
    "leave",
  },
  moderation = {
    data = "data/moderation.json"
  },
  sudo_users = {our_id},
  LOG_ID = "channel#id00000000"
  }
  serialize_to_file(config, './data/config.lua')
  print ('saved config into ./data/config.lua')
end

function on_our_id (id)
  our_id = id
end

function on_user_update (user, what)
  --vardump (user)
  save_info(user)
end

function on_chat_update (chat, what)
  --vardump (chat)
  save_info(chat)
end

function on_secret_chat_update (schat, what)
  --vardump (schat)
end

function on_get_difference_end ()
end

-- Enable plugins in config.lua
function load_plugins()
  for k, v in pairs(_config.enabled_plugins) do
    print("Loading plugin", v)

    local ok, err = pcall(function()
        local t = loadfile("plugins/"..v..'.lua')()
        plugins[v] = t
      end)

    if not ok then
      print('\27[31mError loading plugin '..v..'\27[39m')
      print('\27[31m'..err..'\27[39m')
    end

  end
end

-- custom add
function load_data(filename)

  local f = io.open(filename)
  if not f then
    return {}
  end
  local s = f:read('*all')
  f:close()
  local data = JSON.decode(s)

  return data

end

function save_data(filename, data)
  local s = JSON.encode(data)
  local f = io.open(filename, 'w')
  f:write(s)
  f:close()
end

-- Call and postpone execution for cron plugins
function cron_plugins()

  for name, plugin in pairs(plugins) do
    -- Only plugins with cron function
    if plugin.cron ~= nil then
      plugin.cron()
    end
  end

  -- Called again in 5 mins
  postpone (cron_plugins, false, 5*60.0)
end

-- Start and load values
our_id = 0
now = os.time()
math.randomseed(now)
started = false
