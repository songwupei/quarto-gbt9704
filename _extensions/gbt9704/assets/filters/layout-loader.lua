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

function Pandoc(doc)
  if FORMAT ~= "latex" and FORMAT ~= "pdf" then return doc end

  local ok, layout = pcall(function()
    return dofile("_extensions/gbt9704/gbt9704-layout.lua")
  end)
  if not ok then return doc end

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
