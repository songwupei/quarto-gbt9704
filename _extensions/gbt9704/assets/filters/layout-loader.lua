-- layout-loader.lua
-- Reads gbt9704-layout.lua and injects LaTeX \def overrides
-- via header-includes (preamble, before \begin{document}).

local function to_camel(s)
  local parts = {}
  for part in s:gmatch("[^_]+") do table.insert(parts, part) end
  local result = parts[1] or ""
  for i = 2, #parts do
    result = result .. parts[i]:sub(1,1):upper() .. parts[i]:sub(2)
  end
  return result
end

local function macro_name(section, key)
  return "gbt@layout@" .. to_camel(section) .. "@" .. to_camel(key)
end

local function generate_defs(layout)
  local defs = {}
  local sections = {
    "header_org", "header_number", "redline", "title",
    "mainreceiver", "body", "signature", "signdate", "page_number"
  }
  for _, sec in ipairs(sections) do
    local spec = layout[sec]
    if spec then
      for key, val in pairs(spec) do
        if key ~= "description" then
          if type(val) == "table" then
            for sub_key, sub_val in pairs(val) do
              local name = macro_name(sec, key) .. "@" .. sub_key
              table.insert(defs, "\\def\\" .. name .. "{" .. tostring(sub_val) .. "}")
            end
          else
            local name = macro_name(sec, key)
            table.insert(defs, "\\def\\" .. name .. "{" .. tostring(val) .. "}")
          end
        end
      end
    end
  end
  local colors = layout["colors"]
  if colors then
    for color_key, color_spec in pairs(colors) do
      if type(color_spec) == "table" then
        local ck = to_camel(color_key)
        table.insert(defs, "\\def\\gbt@layout@color@" .. ck .. "@model{" .. tostring(color_spec["model"]) .. "}")
        local vals = color_spec["value"]
        if type(vals) == "table" then
          table.insert(defs, "\\def\\gbt@layout@color@" .. ck .. "@value{" .. table.concat(vals, ",") .. "}")
        end
      end
    end
  end
  return defs
end

-- Directory of this filter script (as pandoc loaded it).
-- Returns nil if it cannot be determined.
local function filter_script_dir()
  local info = debug.getinfo(1, "S")
  local src = info and info.source or ""
  src = src:gsub("^@", "")          -- strip '@' prefix added by pandoc
  return src:match("^(.*)/[^/]+$")    -- drop the trailing filename
end

-- Candidate paths for gbt9704-layout.lua, tried in order until one loads.
local function layout_candidates()
  local list = {}
  -- 1) Relative to this filter file — works regardless of the extension
  --    directory name (repo: _extensions/gbt9704/, installed via
  --    `quarto add songwupei/quarto-gbt9704`: _extensions/songwupei/gbt9704/)
  local dir = filter_script_dir()
  if dir and dir ~= "" then
    table.insert(list, dir .. "/../../gbt9704-layout.lua")
  end
  -- 2) Repo / direct-install layout
  table.insert(list, "_extensions/gbt9704/gbt9704-layout.lua")
  -- 3) Installed via `quarto add songwupei/quarto-gbt9704`
  table.insert(list, "_extensions/songwupei/gbt9704/gbt9704-layout.lua")
  -- 4) format-resource staged next to the project being rendered
  table.insert(list, "gbt9704-layout.lua")
  return list
end

function Pandoc(doc)
  if FORMAT ~= "latex" and FORMAT ~= "pdf" then return doc end

  local layout = nil
  for _, path in ipairs(layout_candidates()) do
    local ok, res = pcall(dofile, path)
    if ok and type(res) == "table" then
      layout = res
      break
    end
  end
  if not layout then return doc end

  local defs = generate_defs(layout)
  if #defs == 0 then return doc end

  -- Re-definecolor: color was already set during class load with old values.
  -- We must re-define after our \def overrides take effect.
  local ck = to_camel("chinese_red")
  table.insert(defs, "\\definecolor{chinese-red}{\\gbt@layout@color@" .. ck .. "@model}{\\gbt@layout@color@" .. ck .. "@value}")

  local latex_block = "\\makeatletter\n" .. table.concat(defs, "\n") .. "\n\\makeatother\n"

  local hi = doc.meta["header-includes"]
  if not hi then
    hi = pandoc.List()
    doc.meta["header-includes"] = hi
  end
  hi:insert(pandoc.MetaBlocks({pandoc.RawBlock("latex", latex_block)}))

  return doc
end
