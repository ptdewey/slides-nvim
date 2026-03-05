local function parse_bold(text)
  local ranges = {}
  local result = {}
  local pos = 1
  local byte_offset = 0
  while (pos <= #text) do
    local s, e = text:find("%*%*(.-)%*%*", pos)
    if not s then
      table.insert(result, text:sub(pos))
      break
    else
      do
        local before = text:sub(pos, (s - 1))
        table.insert(result, before)
        byte_offset = (byte_offset + #before)
      end
      do
        local content = text:sub((s + 2), (e - 2))
        table.insert(ranges, {start = byte_offset, ["end"] = (byte_offset + #content)})
        table.insert(result, content)
        byte_offset = (byte_offset + #content)
      end
      pos = (e + 1)
    end
  end
  return table.concat(result), ranges
end
local function flush(current_lines, slides)
  if (#current_lines > 0) then
    local slide_type = "content"
    local parsed = {}
    for _, raw in ipairs(current_lines) do
      if raw:match("^#%s+") then
        local text = raw:gsub("^#%s+", "")
        local clean, bolds = parse_bold(text)
        slide_type = "title"
        table.insert(parsed, {type = "h1", text = clean, indent = 0, bold = bolds})
      elseif raw:match("^##%s+") then
        local text = raw:gsub("^##%s+", "")
        local clean, bolds = parse_bold(text)
        table.insert(parsed, {type = "h2", text = clean, indent = 0, bold = bolds})
      elseif raw:match("^%s*[%-%*]%s+") then
        local spaces, marker_and_text = raw:match("^(%s*)[%-%*]%s+(.*)")
        local indent = math.floor((#spaces / 2))
        local clean, bolds = parse_bold(marker_and_text)
        table.insert(parsed, {type = "bullet", text = clean, indent = indent, bold = bolds})
      elseif raw:match("^%s*$") then
        table.insert(parsed, {type = "blank", text = "", indent = 0, bold = {}})
      else
        local clean, bolds = parse_bold(raw)
        table.insert(parsed, {type = "text", text = clean, indent = 0, bold = bolds})
      end
    end
    return table.insert(slides, {type = slide_type, lines = parsed})
  else
    return nil
  end
end
local function parse(lines)
  local slides = {}
  local current_lines = {}
  local start = 1
  for i, line in ipairs(lines) do
    if (start ~= 1) then break end
    if line:match("^#%s+") then
      start = i
    else
    end
  end
  for i = start, #lines do
    local line = lines[i]
    if line:match("^%-%-%-+%s*$") then
      flush(current_lines, slides)
      for j = #current_lines, 1, -1 do
        table.remove(current_lines, j)
      end
    else
      table.insert(current_lines, line)
    end
  end
  flush(current_lines, slides)
  return slides
end
return {parse = parse}
