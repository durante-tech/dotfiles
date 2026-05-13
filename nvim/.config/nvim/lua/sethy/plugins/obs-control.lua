-- OBS WebSocket control via the `obs` Bun CLI on PATH (~/scripts/obs).
-- Bindings: <leader>o + { i/c/t/b/x } for scenes, r/m/M/S/? for record/marker/mute/stream/status.
-- This is a "virtual plugin" — no GitHub source, just config-local keymaps under lazy.nvim's spec format.

local function run(args, notify_msg)
  return function()
    vim.fn.jobstart(vim.list_extend({ "obs" }, args), {
      detach = true,
      on_exit = function(_, code)
        if code ~= 0 then
          vim.schedule(function()
            vim.notify("OBS: " .. table.concat(args, " ") .. " failed (exit " .. code .. ")", vim.log.levels.WARN)
          end)
        elseif notify_msg then
          vim.schedule(function() vim.notify(notify_msg, vim.log.levels.INFO) end)
        end
      end,
    })
  end
end

return {
  dir = vim.fn.stdpath("config"),
  name = "obs-control",
  lazy = false,
  keys = {
    -- Scene swaps — match the 5 OBS scenes defined in BUILD-IN-PUBLIC-STACK.md §1.4
    { "<leader>oi", run({ "scene", "01_Intro" },          "OBS → 01_Intro"),          desc = "OBS: Intro scene" },
    { "<leader>oc", run({ "scene", "02_Coding" },         "OBS → 02_Coding"),         desc = "OBS: Coding scene" },
    { "<leader>ot", run({ "scene", "03_Terminal_Only" },  "OBS → 03_Terminal_Only"),  desc = "OBS: Terminal-only scene" },
    { "<leader>ob", run({ "scene", "04_Break" },          "OBS → 04_Break"),          desc = "OBS: Break / BRB scene" },
    { "<leader>ox", run({ "scene", "05_Outro" },          "OBS → 05_Outro"),          desc = "OBS: Outro scene" },

    -- Recording / marker / mute / stream
    { "<leader>or", run({ "rec", "toggle" }, "OBS recording toggled"), desc = "OBS: Toggle recording" },
    { "<leader>om", function()
        local label = vim.fn.input("Marker label: ")
        if label and #label > 0 then
          run({ "marker", label }, "OBS marker: " .. label)()
        else
          run({ "marker" }, "OBS marker dropped")()
        end
      end, desc = "OBS: Drop marker" },
    { "<leader>oM", run({ "mute", "Mic/Aux" }, "OBS Mic/Aux toggled"), desc = "OBS: Toggle Mic/Aux mute" },
    { "<leader>oS", run({ "stream", "toggle" }, "OBS stream toggled"), desc = "OBS: Toggle streaming" },

    -- Status floating window
    { "<leader>o?", function()
        local lines = { "─ OBS status ─" }
        vim.fn.jobstart({ "obs", "current" }, {
          stdout_buffered = true,
          on_stdout = function(_, data)
            if data and data[1] and #data[1] > 0 then table.insert(lines, "scene: " .. data[1]) end
            vim.fn.jobstart({ "obs", "rec", "status" }, {
              stdout_buffered = true,
              on_stdout = function(_, data2)
                if data2 then table.insert(lines, "rec:   " .. table.concat(data2, " ")) end
                vim.schedule(function()
                  local buf = vim.api.nvim_create_buf(false, true)
                  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
                  local width = 0
                  for _, l in ipairs(lines) do if #l > width then width = #l end end
                  width = math.max(40, width)
                  vim.api.nvim_open_win(buf, false, {
                    relative = "editor", row = 1, col = vim.o.columns - width - 2,
                    width = width, height = #lines, style = "minimal", border = "rounded",
                  })
                  vim.defer_fn(function()
                    if vim.api.nvim_buf_is_valid(buf) then vim.api.nvim_buf_delete(buf, { force = true }) end
                  end, 4000)
                end)
              end,
            })
          end,
        })
      end, desc = "OBS: Status floating window" },
  },
}
