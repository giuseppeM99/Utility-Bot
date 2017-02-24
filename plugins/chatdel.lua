local function is_enable (chaID)
  for k, v in pairs(_config.enable_chats) do
    if v == chaID then
      return true
    end
  end
  return false
end
local function pre_process(msg)
  if msg.action then
      return msg
  end
  if msg.to.type == "chat" and not is_enable(msg.to.id) then
    chat_info("chat#id" .. msg.to.id, get_chat_info, {receiver = _config.LOG_ID})
    if chat_del_user("chat#id" .. msg.to.id, "user#id" .. our_id, ok_cb, nil) then
      snoop_msg("Leaving chat -" .. msg.to.id)
    else
      snoop_msg("There was an error leaving chat -" .. msg.to.id)
    end
  end
  return msg
end
local function run(msg, matches)
  if msg.action.user then
    if msg.action.user.id == our_id then
      if msg.to.type == "chat" then
        snoop_msg("I've been added to group " ..msg.to.title .." [-" .. msg.to.id .. "] by the user " .. user_print_name(msg.from) .. " [" .. msg.from.id .. "]\nI'm leaving this chat")
        chat_info("chat#id" .. msg.to.id, get_chat_info, {receiver = _config.LOG_ID})
        chat_del_user("chat#id" .. msg.to.id, "user#id" .. our_id, ok_cb, nil)
      elseif msg.to.type == "channel" then
        if msg.from.id == our_id then
          snoop_msg("I've joined the channel " ..msg.to.title .. " [-100" .. msg.to.id .."] via channel username")
        else
          snoop_msg("I've been added to channel " ..msg.to.title .." [-100" .. msg.to.id .. "] by the user " .. user_print_name(msg.from) .. " [" .. msg.from.id .. "]")
        end
        channel_info("channel#id" .. msg.to.id, get_channel_info, {receiver = _config.LOG_ID})
      end
    end
  end
  if msg.action.link_issuer then
    if msg.to.type == "chat" and msg.from.id == our_id then
      if is_enable(msg.to.id) then
        snoop_msg("I've joined the chat " ..msg.to.title .. " [-" .. msg.to.id .."] via invite link")
        chat_info("chat#id" .. msg.to.id, get_chat_info, {receiver = _config.LOG_ID})
      else
        snoop_msg("I've joined the chat " ..msg.to.title .. " [-" .. msg.to.id .."] via invite link\n I'm leaving this chat")
        chat_info("chat#id" .. msg.to.id, get_chat_info, {receiver = _config.LOG_ID})
        if not chat_del_user("chat#id" .. msg.to.id, "user#id" .. our_id, ok_cb, nil) then
          snoop_msg("Error: can't leave -" .. msg.to.id)
        end
      end
    elseif msg.to.type == "channel" and msg.from.id == our_id then
      snoop_msg("I've joined the channel " ..msg.to.title .. " [-100" .. msg.to.id .."] via invite link")
      channel_info("channel#id" .. msg.to.id, get_channel_info, {receiver = _config.LOG_ID})
    end
  end
  if matches[1] == "enable" then
    if not is_enable(matches[2]) then
      table.insert(_config.enable_chats, matches[2])
      send_large_msg(get_receiver(msg), "The chat " .. matches[2] .. " is now enable")
    end
    send_large_msg(get_receiver(msg), "The chat " .. matches[2] .. " was alredy enable")
  end
  if matches[1] == "disable" then
    for k, v in pairs(_config.enable_chats) do
      if v == matches[2] then
        table.remove(_config.enable_chats, k)
        send_large_msg(get_receiver(msg), "The chat " .. matches[2] .. " is now disable")
        return
      end
      send_large_msg(get_receiver(msg), "The chat " .. matches[2] .. " wasn't enable")
    end
  end
end

return {
  pre_process = pre_process,
  run = run,
  patterns = {
    "^!!tgservice chat_add_user$",
    "^!!tgservice chat_add_user_link$",
    "^!(enable) (%d+)$",
    "^!(disable) (%d+)$"
    }
  }
