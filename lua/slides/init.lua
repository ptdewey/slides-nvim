local parser = require("slides.parser")
local renderer = require("slides.renderer")
local state = {buf = nil, win = nil, slides = nil, current = 0, ["original-buf"] = nil}
local function render_current()
  if (state.slides and state.buf and vim.api.nvim_buf_is_valid(state.buf)) then
    return renderer.render(state.slides[(state.current + 1)], {buf = state.buf, win = state.win, current = state.current, total = #state.slides})
  else
    return nil
  end
end
local function next()
  if state.slides then
    if (state.current < (#state.slides - 1)) then
      state.current = (state.current + 1)
      return render_current()
    else
      return nil
    end
  else
    return nil
  end
end
local function prev()
  if state.slides then
    if (state.current > 0) then
      state.current = (state.current - 1)
      return render_current()
    else
      return nil
    end
  else
    return nil
  end
end
local function stop()
  if (state.win and vim.api.nvim_win_is_valid(state.win)) then
    vim.api.nvim_win_close(state.win, true)
  else
  end
  if (state.buf and vim.api.nvim_buf_is_valid(state.buf)) then
    vim.api.nvim_buf_delete(state.buf, {force = true})
  else
  end
  state.buf = nil
  state.win = nil
  state.slides = nil
  state.current = 0
  state["original-buf"] = nil
  return nil
end
local function start()
  if state.win then
    stop()
  else
  end
  state["original-buf"] = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(state["original-buf"], 0, -1, false)
  local slides = parser.parse(lines)
  state.slides = slides
  if (#slides == 0) then
    vim.notify("slides: no slides found", vim.log.levels.WARN)
    return
  else
  end
  state.buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_option_value("buftype", "nofile", {buf = state.buf})
  vim.api.nvim_set_option_value("filetype", "slides", {buf = state.buf})
  do
    local width = vim.o.columns
    local height = (vim.o.lines - 1)
    state.win = vim.api.nvim_open_win(state.buf, true, {relative = "editor", width = width, height = height, row = 0, col = 0, style = "minimal", border = "none"})
  end
  vim.api.nvim_set_option_value("cursorline", false, {win = state.win})
  vim.api.nvim_set_option_value("number", false, {win = state.win})
  vim.api.nvim_set_option_value("relativenumber", false, {win = state.win})
  vim.api.nvim_set_option_value("signcolumn", "no", {win = state.win})
  vim.api.nvim_set_option_value("wrap", false, {win = state.win})
  do
    local map_opts = {buffer = state.buf, silent = true}
    vim.keymap.set("n", "n", next, map_opts)
    vim.keymap.set("n", "l", next, map_opts)
    vim.keymap.set("n", "<Right>", next, map_opts)
    vim.keymap.set("n", "<Space>", next, map_opts)
    vim.keymap.set("n", "p", prev, map_opts)
    vim.keymap.set("n", "h", prev, map_opts)
    vim.keymap.set("n", "<Left>", prev, map_opts)
    vim.keymap.set("n", "q", stop, map_opts)
    vim.keymap.set("n", "<Esc>", stop, map_opts)
  end
  state.current = 0
  return render_current()
end
local function setup(opts)
end
return {setup = setup, start = start, stop = stop, next = next, prev = prev}
