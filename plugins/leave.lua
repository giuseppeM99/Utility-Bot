local function run(msg, matches)
  if is_admin(msg) then
    if matches[1] == msg.text or not matches[2] then
      if is_chat_msg(msg) then
        if not is_chan_msg(msg) then
          chat_del_user(get_receiver(msg), "user#id"..our_id, ok_cb, nil)
          snoop_msg("Leaving chat " .. msg.to.id)
        else
          leave_channel(get_receiver(msg), ok_cb, nil)
          snoop_msg("Leaving channel " .. msg.to.id)
        end
      end
    end
    if matches[1] == "channel" then
      leave_channel("channel#id"..matches[2], ok_cb, nil)
      snoop_msg("Leaving channel "..matches[2])
    end
    if matches[1] == "chat" then
      chat_del_user("chat#id"..matches[2], "user#id"..our_id, ok_cb, nil)
      snoop_msg("Leaving channel "..matches[2])
    end
  end
end
return {
  patterns = {
    "^!leave$",
    "^!leave (channel) (%d+)$",
    "^!leave (chat) (%d+)$",
  },
  run = run
  }
