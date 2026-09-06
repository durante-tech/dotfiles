local messages, jobs, prompts = {}, 0, 0
vim.notify = function(message) messages[#messages + 1] = message end
vim.fn.executable = function() return 0 end
vim.fn.jobstart = function() jobs = jobs + 1; return -1 end
vim.fn.input = function() prompts = prompts + 1; return '' end
local spec = dofile(vim.env.DOTFILES_TEST_REPO .. '/nvim/.config/nvim/lua/sethy/plugins/obs-control.lua')
for _, binding in ipairs(spec.keys) do binding[2]() end
assert(jobs == 0 and prompts == 0, 'missing OBS must not start a job or ask for a marker')
assert(#messages == #spec.keys, 'every unavailable action should diagnose the missing dependency')
vim.fn.executable = function() return 1 end
spec.keys[1][2]()
assert(jobs == 1 and messages[#messages]:find('unable to start'), 'failed jobstart must be visible')
print('OBS dependency and failed launch fixtures passed')
