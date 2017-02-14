local function pre_process(msg)
  if msg.action then
      return msg
  end
  if msg.to.type == "chat" then
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
        snoop_msg("I've been added to group " ..msg.to.title .." [" .. msg.to.id .. "] by the user " .. user_print_name(msg.from) .. " [" .. msg.from.id .. "]\nI'm leaving this chat")
        chat_info("chat#id" .. msg.to.id, get_chat_info, {receiver = _config.LOG_ID})
        chat_del_user("chat#id" .. msg.to.id, "user#id" .. our_id, ok_cb, nil)
      elseif msg.to.type == "channel" then
        snoop_msg("I've been added to channel " ..msg.to.title .." [" .. msg.to.id .. "] by the user " .. user_print_name(msg.from) .. "[" .. msg.from.id .. "]")
        channel_info("channel#id" .. msg.to.id, get_channel_info, {receiver = _config.LOG_ID})
      end
    end
  end
  if msg.action.link_issuer then
    if msg.to.type == "chat" then
      snoop_msg("I've joined the chat " ..msg.to.title .. " [" .. msg.to.id .."] via invite link\n I'm leaving this chat")
      chat_info("chat#id" .. msg.to.id, get_chat_info, {receiver = _config.LOG_ID})
      chat_del_user("chat#id" .. msg.to.id, "user#id" .. ourl_id, ok_cb, nil)
    elseif msg.to.type == "channel" then
      snoop_msg("I've joined the chat " ..msg.to.title .. " [" .. msg.to.id .."] via invite link")
      channel_info("channel#id" .. msg.to.id, get_channel_info, {receiver = _config.LOG_ID})
    end
  end
end

return {
  pre_process = pre_process,
  run = run,
  patterns = {
    "^!!tgservice chat_add_user$",
    "^!!tgservice chat_add_user_link$"
    }
  }