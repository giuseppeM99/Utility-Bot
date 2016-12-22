local function run(msg, matches)
  if msg.to.type == "user" then
    local text = ''
    if matches[1] == 'info' then
      text = "This bot is a fork of @lucentw s-uzzbot [@samus_aran, @samus_aran_bot] created by @giuseppeM99, is based on uzzin's uzzbot, wich is a fork of Yagop telegram-bot. You can find the original bot source at \nhttps://github.com/LucentW/s-uzzbot \nhttps://github.com/uziins/uzzbot \nhttps://github.com/yagop/telegram-bot"
    end
    send_large_msg (get_receiver(msg), text)
 end
end

return{
  run = run,
  patterns = {
    "^!(info)$"
    },
  }