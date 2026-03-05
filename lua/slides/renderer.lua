local ns = vim.api.nvim_create_namespace("nvim_slides")
local bullet_chars = {"\226\151\143", "\226\151\139", "\226\150\160"}
local highlights_defined = false
local function define_highlights()
  if not highlights_defined then
    highlights_defined = true
    vim.api.nvim_set_hl(0, "SlidesH1", {bold = true, fg = "#e0af68"})
    vim.api.nvim_set_hl(0, "SlidesH2", {bold = true, fg = "#7aa2f7"})
    vim.api.nvim_set_hl(0, "SlidesBold", {bold = true})
    vim.api.nvim_set_hl(0, "SlidesBullet", {fg = "#e0af68"})
    return vim.api.nvim_set_hl(0, "SlidesBody", {})
  else
    return nil
  end
end
local function render_title_slide(slide, win_width, win_height, display_lines, line_meta)
  local content = {}
  local content_meta = {}
  for _, ln in ipairs(slide.lines) do
    if (ln.type == "h1") then
      local pad = math.max(0, math.floor(((win_width - vim.fn.strdisplaywidth(ln.text)) / 2)))
      table.insert(content, (string.rep(" ", pad) .. ln.text))
      table.insert(content_meta, {hl = "SlidesH1", bold = ln.bold, offset = pad})
    elseif (ln.type == "blank") then
      table.insert(content, "")
      table.insert(content_meta, {hl = nil, bold = {}, offset = 0})
    else
      local pad = math.max(0, math.floor(((win_width - vim.fn.strdisplaywidth(ln.text)) / 2)))
      table.insert(content, (string.rep(" ", pad) .. ln.text))
      table.insert(content_meta, {hl = "SlidesBody", bold = ln.bold, offset = pad})
    end
  end
  local top_pad = math.max(0, math.floor(((win_height - #content) / 2)))
  for _ = 1, top_pad do
    table.insert(display_lines, "")
    table.insert(line_meta, {hl = nil, bold = {}, offset = 0})
  end
  for i, ln in ipairs(content) do
    table.insert(display_lines, ln)
    table.insert(line_meta, content_meta[i])
  end
  return nil
end
local function render_content_slide(slide, win_width, left_margin, display_lines, line_meta)
  for _ = 1, 3 do
    table.insert(display_lines, "")
    table.insert(line_meta, {hl = nil, bold = {}, offset = 0})
  end
  for _, ln in ipairs(slide.lines) do
    if (ln.type == "h2") then
      table.insert(display_lines, (string.rep(" ", left_margin) .. ln.text))
      table.insert(line_meta, {hl = "SlidesH2", bold = ln.bold, offset = left_margin})
      table.insert(display_lines, "")
      table.insert(line_meta, {hl = nil, bold = {}, offset = 0})
    elseif (ln.type == "bullet") then
      local char = bullet_chars[math.min((ln.indent + 1), #bullet_chars)]
      local indent_str = string.rep("  ", ln.indent)
      local prefix = (string.rep(" ", left_margin) .. indent_str .. char .. " ")
      table.insert(display_lines, (prefix .. ln.text))
      table.insert(line_meta, {hl = "SlidesBody", bold = ln.bold, offset = #prefix, bullet_col = (left_margin + #indent_str), bullet_len = #char})
    elseif (ln.type == "blank") then
      table.insert(display_lines, "")
      table.insert(line_meta, {hl = nil, bold = {}, offset = 0})
    else
      table.insert(display_lines, (string.rep(" ", left_margin) .. ln.text))
      table.insert(line_meta, {hl = "SlidesBody", bold = ln.bold, offset = left_margin})
    end
  end
  return nil
end
local function apply_extmarks(buf, display_lines, line_meta)
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  for i, meta in ipairs(line_meta) do
    local row = (i - 1)
    local line_text = display_lines[i]
    if ((meta.hl == "SlidesH1") or (meta.hl == "SlidesH2")) then
      vim.api.nvim_buf_add_highlight(buf, ns, meta.hl, row, 0, -1)
    else
    end
    if meta.bullet_col then
      vim.api.nvim_buf_add_highlight(buf, ns, "SlidesBullet", row, meta.bullet_col, (meta.bullet_col + meta.bullet_len))
    else
    end
    for _, b in ipairs((meta.bold or {})) do
      local col_start = ((meta.offset or 0) + b.start)
      local col_end = ((meta.offset or 0) + b["end"])
      if (col_end <= #line_text) then
        vim.api.nvim_buf_add_highlight(buf, ns, "SlidesBold", row, col_start, col_end)
      else
      end
    end
  end
  return nil
end
local function render(slide, state)
  define_highlights()
  local buf = state.buf
  local win = state.win
  local win_width = vim.api.nvim_win_get_width(win)
  local win_height = vim.api.nvim_win_get_height(win)
  local left_margin = math.floor((win_width * 0.12))
  local display_lines = {}
  local line_meta = {}
  if (slide.type == "title") then
    render_title_slide(slide, win_width, win_height, display_lines, line_meta)
  else
    render_content_slide(slide, win_width, left_margin, display_lines, line_meta)
  end
  while (#display_lines < win_height) do
    table.insert(display_lines, "")
    table.insert(line_meta, {hl = nil, bold = {}, offset = 0})
  end
  do
    local counter = string.format(" [%d/%d] ", (state.current + 1), state.total)
    local last_idx = #display_lines
    local counter_pad = math.max(0, (win_width - #counter))
    display_lines[last_idx] = (string.rep(" ", counter_pad) .. counter)
  end
  vim.api.nvim_set_option_value("modifiable", true, {buf = buf})
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, display_lines)
  vim.api.nvim_set_option_value("modifiable", false, {buf = buf})
  return apply_extmarks(buf, display_lines, line_meta)
end
return {render = render}
