URL = require "socket.url"
http = require "socket.http"
https = require "ssl.https"
ltn12 = require "ltn12"
serpent = require "serpent"
feedparser = require "feedparser"

json = (loadfile "./libs/JSON.lua")()
mimetype = (loadfile "./libs/mimetype.lua")()
redis = (loadfile "./libs/redis.lua")()
JSON = (loadfile "./libs/dkjson.lua")()

http.TIMEOUT = 10


function get_receiver(msg)
  if msg.to.type == 'user' then
    return 'user#id'..msg.from.id
  end
  if msg.to.type == 'chat' then
    return 'chat#id'..msg.to.id
  end
  if msg.to.type == 'channel' then
    return 'channel#id'..msg.to.id
  end
  if msg.to.type == 'encr_chat' then
    return msg.to.print_name
  end
end

function is_chat_msg(msg)
  if msg.to.type == 'chat' then
    return true
  end
  if msg.to.type == 'channel' then
    return true
  end
  return false
end

function is_chan_msg(msg)
  if msg.to.type == 'channel' then
    return true
  end
  return false
end

function string.random(length)
  local str = "";
  for i = 1, length do
    math.random(97, 122)
    str = str..string.char(math.random(97, 122));
  end
  return str;
end

function string:split(sep)
  local sep, fields = sep or ":", {}
  local pattern = string.format("([^%s]+)", sep)
  self:gsub(pattern, function(c) fields[#fields+1] = c end)
  return fields
end


-- Removes spaces
function string:trim()
  return self:gsub("^%s*(.-)%s*$", "%1")
end

function get_http_file_name(url, headers)
  -- Eg: foo.var
  local file_name = url:match("[^%w]+([%.%w]+)$")
  -- Any delimited alphanumeric on the url
  file_name = file_name or url:match("[^%w]+(%w+)[^%w]+$")
  -- Random name, hope content-type works
  file_name = file_name or str:random(5)

  local content_type = headers["content-type"]

  local extension = nil
  if content_type then
    extension = mimetype.get_mime_extension(content_type)
  end
  if extension then
    file_name = file_name.."."..extension
  end

  local disposition = headers["content-disposition"]
  if disposition then
    -- attachment; filename=CodeCogsEqn.png
    file_name = disposition:match('filename=([^;]+)') or file_name
  end

  return file_name
end

-- Saves file to /tmp/. If file_name isn't provided,
-- will get the text after the last "/" for filename
-- and content-type for extension
function download_to_file(url, file_name)
  print("url to download: "..url)

  local respbody = {}
  local options = {
    url = url,
    sink = ltn12.sink.table(respbody),
    redirect = true
  }

  -- nil, code, headers, status
  local response = nil

  if url:starts('https') then
    options.redirect = false
    response = {https.request(options)}
  else
    response = {http.request(options)}
  end

  local code = response[2]
  local headers = response[3]
  local status = response[4]

  if code ~= 200 then return nil end

  file_name = file_name or get_http_file_name(url, headers)

  local file_path = "/tmp/"..file_name
  print("Saved to: "..file_path)

  file = io.open(file_path, "w+")
  file:write(table.concat(respbody))
  file:close()

  return file_path
end

function vardump(value)
  print(serpent.block(value, {comment=false}))
end

-- taken from http://stackoverflow.com/a/11130774/3163199
function scandir(directory)
  local i, t, popen = 0, {}, io.popen
  for filename in popen('ls -a "'..directory..'"'):lines() do
    i = i + 1
    t[i] = filename
  end
  return t
end

-- http://www.lua.org/manual/5.2/manual.html#pdf-io.popen
function run_command(str)
  local cmd = io.popen(str)
  local result = cmd:read('*all')
  cmd:close()
  return result
end

-- User has superuser privileges
function is_sudo(msg)
  local var = false
  -- Check users id in config
  for v,user in pairs(_config.sudo_users) do
    if user == msg.from.id then
      var = true
    end
  end
  return var
end

-- user has admins privileges
function is_admin(msg)
  local var = false
  local data = load_data(_config.moderation.data)
  local user = msg.from.id
  local admins = 'admins'
  if data[tostring(admins)] then
    if data[tostring(admins)][tostring(user)] then
      return true
    end
  end
  for v,user in pairs(_config.sudo_users) do
    if user == msg.from.id then
      return true
    end
  end
  return false
end

function is_adminid(user_id)
  local data = load_data(_config.moderation.data)
  if data['admins'] then
    if data['admins'][tostring(user_id)] then
      return true
    end
  end
  for v,user in pairs(_config.sudo_users) do
    if user == user_id then
      return true
    end
  end
  return false
end

-- user has moderator privileges
function is_momod(msg)
  local data = load_data(_config.moderation.data)
  local user = msg.from.id
  if data[tostring(msg.to.id)] then
    if data[tostring(msg.to.id)]['moderators'] then
      if data[tostring(msg.to.id)]['moderators'][tostring(user)] then
        return true
      end
    end
  end
  if data['admins'] then
    if data['admins'][tostring(user)] then
      return true
    end
  end
  for v,user in pairs(_config.sudo_users) do
    if user == msg.from.id then
      return true
    end
  end
  return false
end

-- check whether user is mod, admin or sudo
function is_mod(user_id, chat_id)
  local data = load_data(_config.moderation.data)
  if data[tostring(chat_id)] then
    if data[tostring(chat_id)]['moderators'] then
      if data[tostring(chat_id)]['moderators'][tostring(user_id)] then
        return true
      end
    end
  end
  if data['admins'] then
    if data['admins'][tostring(user_id)] then
      return true
    end
  end
  for v,user in pairs(_config.sudo_users) do
    if user == user_id then
      return true
    end
  end
  return false
end

-- Returns the name of the sender
function get_name(msg)
  local name = msg.from.first_name
  if name == nil then
    name = msg.from.id
  end
  return name
end

-- Returns at table of lua files inside plugins
function plugins_names( )
  local files = {}
  for k, v in pairs(scandir("plugins")) do
    -- Ends with .lua
    if (v:match(".lua$")) then
      table.insert(files, v)
    end
  end
  return files
end

-- Function name explains what it does.
function file_exists(name)
  local f = io.open(name,"r")
  if f ~= nil then
    io.close(f)
    return true
  else
    return false
  end
end

-- Save into file the data serialized for lua.
-- Set uglify true to minify the file.
function serialize_to_file(data, file, uglify)
  file = io.open(file, 'w+')
  local serialized
  if not uglify then
    serialized = serpent.block(data, {
        comment = false,
        name = '_'
      })
  else
    serialized = serpent.dump(data)
  end
  file:write(serialized)
  file:close()
end

-- Returns true if the string is empty
function string:isempty()
  return self == nil or self == ''
end

-- Returns true if the string is blank
function string:isblank()
  self = self:trim()
  return self:isempty()
end



-- Returns true if String starts with Start
function string:starts(text)
  return text == string.sub(self,1,string.len(text))
end

-- Send image to user and delete it when finished.
-- cb_function and cb_extra are optionals callback
function _send_photo(receiver, file_path, cb_function, cb_extra)
  local cb_extra = {
    file_path = file_path,
    cb_function = cb_function,
    cb_extra = cb_extra
  }
  -- Call to remove with optional callback
  send_photo(receiver, file_path, cb_function, cb_extra)
end

-- Download the image and send to receiver, it will be deleted.
-- cb_function and cb_extra are optionals callback
function send_photo_from_url(receiver, url, cb_function, cb_extra)
  -- If callback not provided
  cb_function = cb_function or ok_cb
  cb_extra = cb_extra or false

  local file_path = download_to_file(url, false)
  if not file_path then -- Error
    local text = 'Error downloading the image'
    send_msg(receiver, text, cb_function, cb_extra)
  else
    print("File path: "..file_path)
    _send_photo(receiver, file_path, cb_function, cb_extra)
  end
end

-- Same as send_photo_from_url but as callback function
function send_photo_from_url_callback(cb_extra, success, result)
  local receiver = cb_extra.receiver
  local url = cb_extra.url

  local file_path = download_to_file(url, false)
  if not file_path then -- Error
    local text = 'Error downloading the image'
    send_msg(receiver, text, ok_cb, false)
  else
    print("File path: "..file_path)
    _send_photo(receiver, file_path, ok_cb, false)
  end
end

-- Send multiple images asynchronous.
-- param urls must be a table.
function send_photos_from_url(receiver, urls)
  local cb_extra = {
    receiver = receiver,
    urls = urls,
    remove_path = nil
  }
  send_photos_from_url_callback(cb_extra)
end

-- Use send_photos_from_url.
-- This function might be difficult to understand.
function send_photos_from_url_callback(cb_extra, success, result)
  -- cb_extra is a table containing receiver, urls and remove_path
  local receiver = cb_extra.receiver
  local urls = cb_extra.urls
  local remove_path = cb_extra.remove_path

  -- The previously image to remove
  if remove_path ~= nil then
    os.remove(remove_path)
    print("Deleted: "..remove_path)
  end

  -- Nil or empty, exit case (no more urls)
  if urls == nil or #urls == 0 then
    return false
  end

  -- Take the head and remove from urls table
  local head = table.remove(urls, 1)

  local file_path = download_to_file(head, false)
  local cb_extra = {
    receiver = receiver,
    urls = urls,
    remove_path = file_path
  }

  -- Send first and postpone the others as callback
  send_photo(receiver, file_path, send_photos_from_url_callback, cb_extra)
end

-- Callback to remove a file
function rmtmp_cb(cb_extra, success, result)
  local file_path = cb_extra.file_path
  local cb_function = cb_extra.cb_function or ok_cb
  local cb_extra = cb_extra.cb_extra

  if file_path ~= nil then
    os.remove(file_path)
    print("Deleted: "..file_path)
  end
  -- Finally call the callback
  cb_function(cb_extra, success, result)
end

-- Send document to user and delete it when finished.
-- cb_function and cb_extra are optionals callback
function _send_document(receiver, file_path, cb_function, cb_extra)
  local cb_extra = {
    file_path = file_path,
    cb_function = cb_function or ok_cb,
    cb_extra = cb_extra or false
  }
  -- Call to remove with optional callback
  send_document(receiver, file_path, rmtmp_cb, cb_extra)
end

-- Download the image and send to receiver, it will be deleted.
-- cb_function and cb_extra are optionals callback
function send_document_from_url(receiver, url, cb_function, cb_extra)
  local file_path = download_to_file(url, false)
  print("File path: "..file_path)
  _send_document(receiver, file_path, cb_function, cb_extra)
end

-- Parameters in ?a=1&b=2 style
function format_http_params(params, is_get)
  local str = ''
  -- If is get add ? to the beginning
  if is_get then str = '?' end
  local first = true -- Frist param
  for k,v in pairs (params) do
    if v then -- nil value
      if first then
        first = false
        str = str..k.. "="..v
      else
        str = str.."&"..k.. "="..v
      end
    end
  end
  return str
end

-- Check if user can use the plugin
function user_allowed(plugin, msg)
  -- Berfungsi utk mengecek user jika plugin moderated = true
  if plugin.moderated and not is_momod(msg) then --Cek apakah user adalah momod
    if plugin.moderated and not is_admin(msg) then -- Cek apakah user adalah admin
      if plugin.moderated and not is_sudo(msg) then -- Cek apakah user adalah sudoers
        return false
      end
    end
  end
  -- Berfungsi mengecek user jika plugin privileged = true
  if plugin.privileged and not is_sudo(msg) then
    return false
  end
  return true
end

function send_order_msg(destination, msgs)
  local cb_extra = {
    destination = destination,
    msgs = msgs
  }
  send_order_msg_callback(cb_extra, true)
end

function send_order_msg_callback(cb_extra, success, result)
  local destination = cb_extra.destination
  local msgs = cb_extra.msgs
  local file_path = cb_extra.file_path
  if file_path ~= nil then
    os.remove(file_path)
    print("Deleted: " .. file_path)
  end
  if type(msgs) == 'string' then
    send_large_msg(destination, msgs)
  elseif type(msgs) ~= 'table' then
    return
  end
  if #msgs < 1 then
    return
  end
  local msg = table.remove(msgs, 1)
  local new_cb_extra = {
    destination = destination,
    msgs = msgs
  }
  if type(msg) == 'string' then
    send_msg(destination, msg, send_order_msg_callback, new_cb_extra)
  elseif type(msg) == 'table' then
    local typ = msg[1]
    local nmsg = msg[2]
    new_cb_extra.file_path = nmsg
    if typ == 'document' then
      send_document(destination, nmsg, send_order_msg_callback, new_cb_extra)
    elseif typ == 'image' or typ == 'photo' then
      send_photo(destination, nmsg, send_order_msg_callback, new_cb_extra)
    elseif typ == 'audio' then
      send_audio(destination, nmsg, send_order_msg_callback, new_cb_extra)
    elseif typ == 'video' then
      send_video(destination, nmsg, send_order_msg_callback, new_cb_extra)
    else
      send_file(destination, nmsg, send_order_msg_callback, new_cb_extra)
    end
  end
end

-- Same as send_large_msg_callback but friendly params
function send_large_msg(destination, text)
  local cb_extra = {
    destination = destination,
    text = text
  }
  send_large_msg_callback(cb_extra, true)
end

-- Log to group
function snoop_msg(text)
  local cb_extra = {
    destination = _config.LOG_ID,
    text = text
  }
  send_large_msg_callback(cb_extra, true)
end

-- If text is longer than 4096 chars, send multiple msg.
-- https://core.telegram.org/method/messages.sendMessage
function send_large_msg_callback(cb_extra, success, result)
  local text_max = 4096

  local destination = cb_extra.destination
  local text = cb_extra.text

  if not text then
    return
  end
  local text_len = #text or 0

  if text_len > 0 then
    local num_msg = math.ceil(text_len / text_max)

    if num_msg <= 1 then
      send_msg(destination, text, ok_cb, false)
    else

      local my_text = string.sub(text, 1, 4096)
      local rest = string.sub(text, 4096, text_len)

      local cb_extra = {
        destination = destination,
        text = rest
      }

      send_msg(destination, my_text, send_large_msg_callback, cb_extra)
    end
  end
end

-- Returns a table with matches or nil
function match_pattern(pattern, text, lower_case)
  if text then
    local matches = {}
    if lower_case then
      matches = { string.match(text:lower(), pattern) }
    else
      matches = { string.match(text, pattern) }
    end
    if next(matches) then
      return matches
    end
  end
  -- nil
end

-- Function to read data from files
function load_from_file(file, default_data)
  local f = io.open(file, "r+")
  -- If file doesn't exists
  if f == nil then
    -- Create a new empty table
    default_data = default_data or {}
    serialize_to_file(default_data, file)
    print ('Created file', file)
  else
    print ('Data loaded from file', file)
    f:close()
  end
  return loadfile (file)()
end

-- See http://stackoverflow.com/a/14899740
function unescape_html(str)
  local map = {
    ["lt"] = "<",
    ["gt"] = ">",
    ["amp"] = "&",
    ["quot"] = '"',
    ["apos"] = "'"
  }
  new = string.gsub(str, '(&(#?x?)([%d%a]+);)', function(orig, n, s)
      var = map[s] or n == "#" and string.char(s)
      var = var or n == "#x" and string.char(tonumber(s,16))
      var = var or orig
      return var
    end)
  return new
end

-- Workarrond to format the message as previously was received
function backward_msg_format (msg)
  if msg.to.type == 'encr_chat' then
    return msg
  end
  for k,name in ipairs({'from', 'to'}) do
    local longid = msg[name].id
    msg[name].id = msg[name].peer_id
    msg[name].peer_id = longid
    msg[name].type = msg[name].peer_type
  end
  if msg.fwd_from then
    local longid = msg.fwd_from.id
    msg.fwd_from.id = msg.fwd_from.peer_id
    msg.fwd_from.peer_id = longid
    msg.fwd_from.type = msg.fwd_from.peer_type
  end
  if msg.action and (msg.action.user or msg.action.link_issuer) then
    local user = msg.action.user or msg.action.link_issuer
    local longid = user.id
    user.id = user.peer_id
    user.peer_id = longid
    user.type = user.peer_type
  end
  return msg
end

function get_chat_info(cb_extra, success, result)
  local chat = {}
  hash = "usermem:" .. result.peer_id
  for k, v in pairs(redis:hgetall(hash)) do
    redis:hdel(hash, v)
  end
  local i = 1
  for k, v in pairs(result.members) do
    redis:hset(hash, v.peer_id, true)
    if v.first_name then
      user = {}
      user.name = v.first_name
      if v.last_name then
        user.last_name = v.last_name
      end
      user.id = v.peer_id
      if v.username then
        user.username = "@" .. v.username
      end
      user.gid = result.peer_id * -1
      chat[i] = {}
      chat[i].user = user
      chat[i].type = "user"
      chat[i].status = "member"
      i = i + 1
    end
  end
  chat[i] = {}
  chat[i].group = {}
  chat[i].group.id ="-" .. result.peer_id
  chat[i].group.title = result.title
  chat[i].group.participants_count = result.members_num
  chat[i].status = "info"
  local res = {
    ["ok"] = true,
    ["result"] = chat
  }
  save_data(chat[i].group.id .. ".json", res)
  _send_document(cb_extra.receiver, chat[i].group.id.. ".json", ok_cb, nil)
end

function get_channel_bots(cb_extra, success, result)
  if success == 0 then
    local channel = {}
    channel.username = cb_extra.info.username
    channel.title = cb_extra.info.title
    channel.about = cb_extra.info.about
    channel.id = "-100" .. cb_extra.info.peer_id
    channel.participants_count = cb_extra.info.participants_count
    channel.type = "broadcast"
    save_info(cb_extra.info)
    print("Saved channel broadcast",  channel.id)
    local text = JSON.encode(channel)
    send_large_msg(cb_extra.receiver, text)
    return
  end
  local channel = {}
  channel.username = cb_extra.info.username
  channel.title = cb_extra.info.title
  channel.about = cb_extra.info.about
  channel.id = "-100" .. cb_extra.info.peer_id
  channel.participants_count = cb_extra.info.participants_count
  channel.type = "supergroup"
  save_info(cb_extra.info)
  bots = {}
  for k, v in pairs(result) do
    redis:hset("peer:" .. v.peer_id, "type", "bot")
    bots[v.peer_id] = true
    print("Saved bot", v.peer_id)
  end
  channel_get_admins("channel#id".. cb_extra.info.peer_id, get_channel_admins, {channel = channel, receiver = cb_extra.receiver, bots = bots})
end

function get_channel_admins(cb_extra, success, result)
  local channel = cb_extra.channel
  local hash = "usermem:"..channel.id:gsub("-100", "") .. ":admins"
  for k, v in pairs(redis:hgetall(hash)) do
    redis:hdel(hash, v)
  end
  local admins = {}
  sure = true
  for k, v in pairs(result) do
    redis:hset(hash, v.peer_id, true)
    admins[v.peer_id] = true
    if v.peer_id == our_id then
      channel.type = "channel"
      sure = false
    end
  end
  if sure and redis:hget("peer:"..channel.id, "type" == "channel") then
    redis:hset("peer:"..channel.id, "type", "supergroup")
  end
  channel_get_users(channel.id:gsub("-100", "channel#id"), get_channel_users, {receiver = cb_extra.receiver, channel = channel, bots = cb_extra.bots, admins = admins})
end

function get_channel_users(cb_extra, success, result)
  local channel = {}
  local i = 1
  local hash = "usermem:" .. cb_extra.channel.id:gsub("-100", "")
  for k, v in pairs(redis:hgetall(hash)) do
    redis:hdel(hash, v)
  end
  for k, v  in pairs(result) do
    redis:hset(hash, v.peer_id, true)
    if v.first_name then
      local user = {}
      if v.username ~= nil then
        user.username = v.username
      end
      user.name = v.first_name
      if v.last_name ~= nil then
        user.last_name = v.last_name
      end
      user.id = v.peer_id
      user.gid = cb_extra.channel.id
      channel[i] = {}
      channel[i].user = user
      if cb_extra.bots[v.peer_id] then
        channel[i].type = "bot"
      else
        channel[i].type = "user"
      end
      if cb_extra.admins[v.peer_id] then
        channel[i].status = "administrator"
      else
        channel[i].status = "member"
      end
      i = i + 1
    end
    channel[i] = {}
    channel[i].group = cb_extra.channel
    channel[i].status = "info"
  end
  res = {
    ["ok"] = true,
    ["result"] = channel
  }
  save_data(channel[i].group.id .. ".json", res)
  _send_document(cb_extra.receiver, channel[i].group.id .. ".json")
end

function get_user_info(cb_extra, success, result)
  if result.first_name then
    local user = {}
    user.id = result.peer_id
    user.name = result.first_name
    user.last_name = result.last_name
    user.type = "user"
    user.username = result.username
    res = {
      ["ok"] = true,
      ["result"] = user
    }
    send_msg(cb_extra.receiver, JSON.encode(res), ok_cb, nil)
  end
end


function get_channel_info(cb_extra, success, result)
  channel_get_bots("channel#id" .. result.peer_id, get_channel_bots, {receiver = cb_extra.receiver, info = result})
end

function get_username_info(cb_extra, success, result)
  if success == 0 then
    res = {
      ["ok"] = false,
      ["query"] = cb_extra.query
    }
    send_large_msg(cb_extra.receiver, JSON.encode(res))
    return
  end
  save_info(result)
  if result.peer_type == "user" then
    local user = {}
    user.username =  result.username
    user.name = result.first_name
    user.last_name = result.last_name
    user.id = result.peer_id
    user.type = "user"
    res = {
      ["ok"] = true,
      ["result"] = user
    }
    send_large_msg(cb_extra.receiver, text)
  else
    channel_get_bots("channel#id" .. result.peer_id, get_channel_bots, {receiver = cb_extra.receiver, info = result})
  end
end

function user_print_name(user)
  local text = ''
  if user.first_name then
    text = user.first_name..' '
  end
  if user.last_name then
    text = text..user.last_name
  end
  if user.title then
    text = user.title
  end
  return text or user.print_name:gsub('_', ' ')
end

--Save Peer to redis
function save_info(info)
  if info.username then
    if info.peer_type == "user" then
      redis:set("username:" .. info.username:lower(), info.peer_id)
    elseif info. peer_type == "channel" then
      redis:set("username:" .. info.username:lower(), tonumber("-100" .. info.peer_id))
    end
  end
  local botid
  if info.peer_type == "user" or info.peer_type == "bot" then
    botid = info.peer_id
  elseif info.peer_type == "chat" then
    botid = "-" .. info.peer_id
  elseif info.peer_type == "channel" or info.peer_type == "broadcast" or info.peer_type == "supergroup" then
    botid = "-100" .. info.peer_id
  end
  botid = tonumber(botid)
  peerhash = "peer:" .. botid
  local oldinfo = redis:hgetall(peerhash)
  if info.first_name then
    if not oldinfo.first_name or info.first_name ~= oldinfo.first_name then
      redis:hset(peerhash, "first_name", info.first_name)
    end
  else
    redis:hdel(peerhash, "first_name")
  end
  if info.last_name then
    if not oldinfo.last_name or info.last_name ~= oldinfo.last_name then
      redis:hset(peerhash, "last_name", info.last_name)
    end
  else
    redis:hdel(peerhash, "last_name")
  end
  local tmptype = oldinfo.type
  if not tmptype then
    redis:hset(peerhash, "type", info.peer_type)
  elseif ((tmptype == "broadcast" or tmptype == "supergroup") and info.peer_type ~= "channel") or ((tmptype == "bot" or tmptype == "user") and info.peer_type ~= "user") then
    redis:hset(peerhash, "type", info.peer_type)
  end
  if not oldinfo.id then
    redis:hset(peerhash, "id", botid)
  end
  if not oldinfo.peer_id then
    redis:hset(peerhash, "peerid", info.peer_id)
  end
  if info.username then
    if info.username ~= oldinfo.username then
      redis:hset(peerhash, "username", info.username)
      if oldinfo.username then
        vardump(oldinfo)
        local exid = redis:get("username:" .. oldinfo.username:lower())
        redis:del("username:"..oldinfo.username:lower())
        if exid then
          redis:hdel("peer:"..exid, "username")
          if tonumber(exid) < 0 then
            channel_info(exid:gsub("-100", "channel#id"), get_channel_info, {receiver = false})
          else
            user_info("user#id" .. exid, get_user_info, {receiver = false})
          end
        end
      end
    end
  else
    local exusr = redis:hget(peerhash, "username")
    if exusr then
      redis:del("username:" .. exusr:lower())
      redis:hdel(peerhash, "username")
    end
  end
  if info.about then
    if not oldinfo.about or info.about ~= oldinfo.about then
      redis:hset(peerhash, "about", info.about)
    end
  else
    redis:hdel(peerhash, "about")
  end
  if info.title then
    if not oldinfo.title or info.title ~= oldinfo.titile then
      redis:hset(peerhash, "title", info.title)
    end
  else
    redis:hdel(peerhash, "title")
  end
  print("Saved", botid)
end
