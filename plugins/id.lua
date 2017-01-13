local function megagroupcb(extra, success, result)
  local oldresult = extra.result
  local user = {}
  local amisure = true
  user.name = oldresult.title
  user.id = "-100"..oldresult.peer_id
  user.username = "@"..oldresult.username
if success == 0 then
    user.type = "broadcast"
  else
    for k, v in pairs(result) do
      if v.peer_id == our_id then
        amisure = false
        break
      end
    end
    if amisure then
      user.type = "supergroup"
    else user.type = "channel" end
  end
  local text = JSON.encode(user)
  send_large_msg(extra.receiver, text)
  return nil
end

local function botcb(extra, success, result)
  local channel = {}
  channel = extra.channel
  channel.bots = {}
  local i = 0
  for k, v in pairs(result) do
    local user = {}
    if v.username == nil then user.username = " " else user.username = "@" .. v.username end
    user.name = v.first_name
    if v.last_name == nil then user.lastname = " " else user.lastname = v.last_name end
    user.id = v.peer_id
    channel.bots[i] = user
    i = i+1
  end
  save_data(channel.id..".json", channel)
  _send_document(extra.receiver,channel.id ..".json", ok_cb, nil)
end
local function admincb(extra, success, result)
  local channel = {}
  channel = extra.channel
  channel.admins = {}
  local i = 0
  for k, v in pairs(result) do
    local user = {}
    if v.username == nil then user.username = " " else user.username = "@" .. v.username end
    user.name = v.first_name
    if v.last_name == nil then user.lastname = " " else user.lastname = v.last_name end
    user.id = v.peer_id
    channel.admins[i] = user
    i = i+1
  end
  channel_get_bots(channel.id:gsub("-100", "channel#id"), botcb, extra)
end
local function returnids(cb_extra, success, result)
  local chat = {}
  local receiver = cb_extra.receiver
  local chat_id = cb_extra.chat_id
  chat.id = chat_id
  local i = 0
  for k,v in pairs(result.members) do
    local user = {}
    if v.username ~= nil then user.username = "@" .. v.username end
    user.name = v.first_name
    user.lastname = v.last_name
    user.id = v.peer_id
    chat[i] = user
    i = i+1
  end
  save_data(chat_id..".json", chat)
  _send_document(extra.receiver,chat_id..".json", ok_cb, nil)
end

local function returnidschan(cb_extra, success, result)
  if success == 0 then
    local userorid = cb_extra.chat_id
    if cb_extra.username then userorid = cb_extra.username end    
    send_large_msg(cb_extra.receiver, "Error: user is not admin or megagroup is private " .. userorid)
    return nil
  end
  local channel = {}
  channel.name = cb_extra.title or nil
  channel.id = cb_extra.chat_id
  channel.username = cb_extra.username or nil
  local receiver = cb_extra.receiver
  local i = 0
  channel.users = {}
  for k,v in pairs(result) do
    local user = {}
    if v.username ~= nil then user.username = "@" .. v.username end
    user.name = v.first_name
    user.lastname = v.last_name
    user.id = v.peer_id
    channel.users[i] = user
    i = i+1
  end
  channel_get_admins(channel.id:gsub("-100", "channel#id"), admincb, {receiver = receiver, channel = channel})
end

local function channel_username(extra, success, result)
    if success == 1 then
      if result.peer_type == "channel" then
        channel_get_users("channel#id" .. result.peer_id, returnidschan, {chat_id = "-100"..result.peer_id, receiver = extra, name = result.title})
      else
        send_large_msg(extra, "Error: username is not of a channel")
      end
    else
      send_large_msg(extra, "Error: username does not exist || I'm on flood wait")
    end
end

local function username_id(cb_extra, success, result)
  local user = {}
  local receiver = cb_extra.receiver
  local text = "Error: username does not exist"
  if success then
    if result.peer_type == 'channel' then
      return channel_get_admins("channel#id".. result.peer_id, megagroupcb, {result = result, receiver = receiver})
    else
      user.type = "user"
      user.name = result.first_name
      user.id = result.peer_id
      user.lastname = result.last_name
      user.username = "@"..result.username
    end
    text = JSON.encode(user)
  else
    text = "!id "..cb_extra.username
  end
  
  send_large_msg(receiver, text)
end

local function run(msg, matches)
  local receiver = get_receiver(msg)
  if not is_admin(msg) then
    --delete_msg(msg.id, ok_cb, nil)
    return nil
  end
if matches[1] == "chat" then
    if matches[2] then
      local group = matches[2]
      local gtype = nil
      if group:match("^%d+$") then
        return nil
      elseif group:match("^-100%d+$") then
        group = group:gsub("-100", "channel#id")
        gtype = "channel"
      elseif group:match("^-%d+$") then
        group = group:gsub("-", "chat#id")
        gtype = "chat"
      elseif group:match("^@?%a%S*$") then
        group = group:gsub("@", "")
        gtype = "username"
      end
      if gtype == "chat" then
        chat_info(group, returnids, {chat_id=matches[2], receiver=receiver})
        return nil
      end
      if gtype == "channel" then
        channel_get_users(group, returnidschan, {chat_id=matches[2],  receiver=receiver})
        return nil
      end
      if gtype == "username" then
        resolve_username(group, channel_username, receiver)
        return nil
      end
      return nil
    else
      if not is_chat_msg(msg) then
        return nil
      end
      local chat = get_receiver(msg)
      if not is_chan_msg(msg) then
        chat_info(chat, returnids, {chat_id = "-" .. msg.to.id, receiver=chat})
      else
        channel_get_users(chat, returnidschan, {chat_id="-100" .. msg.to.id, receiver=chat})
      end
    end
  else
    local chat = get_receiver(msg)
    resolve_username(matches[1]:gsub("@",""), username_id, {receiver= receiver, username=matches[1]})
  end
  --delete_msg(msg.id, ok_cb, nil) --Decomment to enable autodelete of trigger message
end
return {
  description = "Know your id or the id of a chat members.",
  patterns = {
    "!ids? (chat) (-100%d+)$",
    "!ids? (chat) (-%d+)$",
    "!ids? (chat) (@?%a%S+)$",
    "!id (.*)$"
  },
  run = run
}
