local Config = require('config')
local wezterm = require('wezterm')
local resurrect = wezterm.plugin.require('https://github.com/StephenGemin/resurrect.wezterm')

require('utils.backdrops')
   -- :set_images_dir(require('wezterm').home_dir .. '/Pictures/Wallpapers/')
   :scan_images_dir()
   :random()

require('events.left-status').setup()
require('events.right-status').setup({ date_format = '%a %H:%M:%S' })
require('events.tab-title').setup({
   hide_active_tab_unseen = true,
   unseen_icon = 'numbered_box',
   show_progress = true,
})
require('events.new-tab-button').setup()
require('events.gui-startup').setup()

-- 会话保存/恢复:键位在 config.bindings.lua 自定义(插件默认 Alt 键位与现有键位冲突)
local options = Config:init()
   :append(require('config.appearance'))
   :append(require('config.bindings'))
   :append(require('config.domains'))
   :append(require('config.fonts'))
   :append(require('config.general'))
   :append(require('config.launch')).options

resurrect.setup(options, {
   keybindings = false,
   status_bar = true,
   save_on_focus_loss = true,
   periodic_interval = 300, -- 每 5 分钟自动保存
   -- 恢复时自动重启的 TUI 程序白名单(默认仅 vim/htop 等)
   safe_restore_processes = { add = { 'herdr'} },
})

return options
