local function user_print_name(user)
  local text = ''
  if user.first_name then
    text = user.first_name
  end
  if user.last_name then
    text = text .." <=£=> "..user.last_name:gsub("_", " ")
  end
  return text
end

local function returnids(cb_extra, success, result)
  local receiver = cb_extra.receiver
  local chat_id = cb_extra.chat_id
  local text = '#users '.. chat_id ..'\n'
  i = 0
  local username
  local printname
  for k,v in pairs(result.members) do
    i = i+1
    printname = user_print_name(v)
    if v.username == nil then username = " " else username="@"..v.username end
    newtext = v.peer_id .. ' <=£=> '.. printname .. " <=£=> " .. username .. "\n"
    if string.len(text) + string.len(newtext) < 4096 then
      text = text ..newtext
    else
      send_large_msg(receiver, text)
      text = "#users " .. chat_id .."\n".. newtext
    end
  end
  send_large_msg(receiver, text)
end

local function returnidschan(cb_extra, success, result)
  local receiver = cb_extra.receiver
  local chat_id = cb_extra.chat_id
  local text = "#users " ..chat_id ..'\n'
  i = 0
  local printname
  local username
  for k,v in pairs(result) do
    i = i+1
    printname = user_print_name(v)
    if v.username == nil then username = " " else username = "@" .. v.username end
    newtext = v.peer_id .. ' <=£=> '.. printname .. " <=£=> " .. username .. "\n"
    if string.len(text) + string.len(newtext) < 4096 then
      text = text ..newtext
    else
      send_large_msg(receiver, text)
      text = "#users " .. chat_id .."\n".. newtext
    end
  end
  send_large_msg(receiver, text)
end

local function username_id(cb_extra, success, result)
  local receiver = cb_extra.receiver
  local is_chan = cb_extra.is_chan
  local text = "Error: username does not exist"
  if success then
    if result.peer_type == 'channel' then
      text = "#idc -100" .. result.peer_id .. " <=£=> " .."@" .. result.username .. " <=£=> " .. result.title
    else
      text = "#id " .. result.peer_id .. " <=£=> @" .. result.username .. " <=£=> " .. user_print_name(result)
    end
  end
  send_large_msg(receiver, text)
end

local function run(msg, matches)
  local receiver = get_receiver(msg)
  if not is_admin(msg) then
    delete_msg(msg.id, ok_cb, nil)
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
      end
      if gtype == "chat" then
        chat_info(group, returnids, {chat_id=matches[2], receiver=receiver})
        return nil
      end
      if gtype == "channel" then
        channel_get_users(group, returnidschan, {chat_id=matches[2],  receiver=receiver})
        return nil
      end
      return nil
    else
      if not is_chat_msg(msg) then
        return nil
      end
      local chat = get_receiver(msg)
      if not is_chan_msg(msg) then
        chat_info(chat, returnids, {chat_id = msg.to.id, receiver=receiver})
      else
        channel_get_users(chat, returnidschan, {chat_id=msg.to.id, print_name=string.gsub(user_print_name(msg.to), '_', ' '), receiver=receiver})
      end
    end
  else
    local chat = get_receiver(msg)
    resolve_username(matches[1]:gsub("@",""), username_id, {receiver=receiver,  is_chan=is_chan_msg(msg)})
  end
  --delete_msg(msg.id, ok_cb, nil) --Decomment to enable autodelete of trigger message
end
return {
  description = "Know your id or the id of a chat members.",
  patterns = {
    "!ids? (chat) (-100%d+)$",
    "!ids? (chat) (-%d+)$",
    "!ids? (chat) (%d+)$",
    "!ids? (chat)$",
    "!id (.*)$"
  },
  run = run
}
