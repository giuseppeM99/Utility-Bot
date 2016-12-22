do local _ = {
  disabled_channels = {},
  disabled_plugin_on_chat = {},
  enabled_plugins = {
    "plugins",
    "sudo",
    "join",
    "mute",
    "delmsg",
    "id",
    "moderation"
  },
  moderation = {
    data = "data/moderation.json"
  },
  sudo_users = {
    123456789,
    123456789
  },
  LOG_ID = "channel#id00000000"-- use chat#id for groups, channel#id for channels/supergroups and user#id for users
}
return _
end