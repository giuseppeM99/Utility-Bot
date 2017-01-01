local function run(msg, matches)
  if is_admin(msg) then
    if matches[1] == msg.text then
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
    if matches[1]:match("^-100%d+$") then
      leave_channel("channel#id"..matches[1]:gsub("-100", ""), ok_cb, nil)
      snoop_msg("Leaving channel "..matches[1])
    end
    if matches[1]:match("^-%d+$") then
      chat_del_user("chat#id"..matches[1]:gsub("-", ""), "user#id"..our_id, ok_cb, nil)
      snoop_msg("Leaving chat "..matches[1])
    end
  end
end
return {
  patterns = {
    "^!leave$",
    "^!leave (-100%d+)$",
    "^!leave (-%d+)$",
  },
  run = run
  }
