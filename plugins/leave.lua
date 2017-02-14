local function run(msg, matches)
  if is_admin(msg) then
    if matches[1] == msg.text then
      if is_chat_msg(msg) then
        if not is_chan_msg(msg) then
          chat_info(get_receiver(msg), get_chat_info, {receiver = _config.LOG_ID})
          if chat_del_user(get_receiver(msg), "user#id"..our_id, ok_cb, nil) then
            snoop_msg("Leaving -" .. msg.to.id)
          else
            snoop_msg("There was an error in leaving -" .. msg.to.id)
          end
        else
          if leave_channel(get_receiver(msg), ok_cb, nil) then
            snoop_msg("Leaving -100" .. msg.to.id)
          else
            snoop_msg("There was an error in leaving -100" .. msg.to.id)
          end
        end
      end
    end
    if matches[1]:match("^-100%d+$") then
      if leave_channel(matches[1]:gsub("-100", "channel#id"), ok_cb, nil) then
        snoop_msg("Leaving "..matches[1])
      else
        snoop_msg("There was an error in leaving " .. msg.to.id)
      end
      return
    end
    if matches[1]:match("^-%d+$") then
      chat_info(matches[1]:gsub("-","chat#id"), get_chat_info, {receiver = _config.LOG_ID})
      if chat_del_user(matches[1]:gsub("-", "chat#id"), "user#id"..our_id, ok_cb, nil) then
        snoop_msg("Leaving "..matches[1])
      else
        snoop_msg("There was an error in leaving " .. msg.to.id)
      end
      return
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
