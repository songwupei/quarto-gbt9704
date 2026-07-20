-- gbt9704-emoji.lua
-- Pandoc Lua filter: 为 GB/T 9704 文档添加 emoji 支持
--
-- 支持的格式: PDF (XeLaTeX)、DOCX、ConTeXt、HTML
--
-- 用法:
--   在文档 YAML 头中设置 emoji: true 启用
--      ---
--      emoji: true
--      format:
--        gbt9704-pdf: default
--      ---
--
-- 功能:
--   - 自动检测 emoji Unicode 字符
--   - 支持 ZWJ 序列（👨‍👩‍👧）、肤色修饰（👍🏽）、国旗对（🇨🇳）
--   - 每个格式以最合适的方式包裹 emoji
--   - 关闭 emoji: false 时不影响已有文档

-- ============================================================
-- 全局开关（从 YAML 元数据读取）
-- ============================================================
local ENABLED = false

-- ============================================================
-- Unicode 范围检测
-- ============================================================

--- 检测是否为 emoji 基字符（独立 emoji 或序列的起始字符）
function is_emoji_base(cp)
  -- 杂项符号与箭头
  if cp == 0x00A9 or cp == 0x00AE then return true end        -- © ®
  if cp == 0x203C or cp == 0x2049 then return true end        -- ⁉ ‼
  if cp == 0x2122 or cp == 0x2139 then return true end        -- ™ ℹ
  if cp >= 0x2194 and cp <= 0x2199 then return true end       -- ↔ ↕↖↗↘↙
  if cp >= 0x21A9 and cp <= 0x21AA then return true end       -- ↩ ↪
  if cp >= 0x231A and cp <= 0x23FF then return true end       -- ⌚⌛⏰⏳⌨
  if cp >= 0x24C2 and cp <= 0x24FF then return true end       -- Ⓜ🅰
  if cp >= 0x25AA and cp <= 0x25FE then return true end       -- ▪▫◾◽⚪
  if cp >= 0x2600 and cp <= 0x27BF then return true end       -- ☀☁❤⭐✅✈⚡
  if cp >= 0x2934 and cp <= 0x2935 then return true end       -- ⤴⤵
  if cp >= 0x2B05 and cp <= 0x2B55 then return true end       -- ⬅⬆⬇⬛⬜⭐
  if cp == 0x3030 or cp == 0x303D then return true end        -- 〰〽
  if cp == 0x3297 or cp == 0x3299 then return true end        -- ㊗㊙
  -- Mahjong, Playing cards, Enclosed
  if cp >= 0x1F000 and cp <= 0x1F02F then return true end
  if cp >= 0x1F0A0 and cp <= 0x1F0FF then return true end
  if cp >= 0x1F100 and cp <= 0x1F2FF then return true end
  -- 主体 emoji 区块（表情、交通、符号）
  if cp >= 0x1F300 and cp <= 0x1F9FF then return true end
  -- 扩展 A（新 emoji）
  if cp >= 0x1FA00 and cp <= 0x1FAFF then return true end
  return false
end

--- 区域指示器（国旗的第一/二个字母）
function is_regional_indicator(cp)
  return cp >= 0x1F1E6 and cp <= 0x1F1FF
end

--- 异体选择器（VS16 → 彩色 emoji 风格）
function is_variation_selector(cp)
  return cp >= 0xFE00 and cp <= 0xFE0F
end

--- 肤色修饰符 🏻🏼🏽🏾🏿
function is_skin_tone(cp)
  return cp >= 0x1F3FB and cp <= 0x1F3FF
end

--- ZWJ（零宽连接符，用于组合序列如 👨‍👩‍👧）
function is_zwj(cp)
  return cp == 0x200D
end

--- 键帽结合符 #️⃣
function is_keycap(cp)
  return cp == 0x20E3
end

--- 键帽基字符（# * 0-9），后跟 VS16 + 键帽结合符时作为 emoji
function is_keycap_base(cp, codepoints, i)
  -- #️⃣  *️⃣  0️⃣-9️⃣
  if cp ~= 0x0023 and cp ~= 0x002A and (cp < 0x0030 or cp > 0x0039) then
    return false
  end
  -- 检查后两个字符是否为 VS16 + 键帽结合符
  if i + 2 <= #codepoints then
    return is_variation_selector(codepoints[i+1]) and is_keycap(codepoints[i+2])
  end
  return false
end

-- ============================================================
-- Emoji 序列解析
-- ============================================================

--- 从 codepoints[i] 开始解析一个完整的 emoji 序列
--- 返回 (codepoints_table, next_index)；如果不能解析则返回 (nil, i)
function parse_emoji_sequence(codepoints, i)
  if i > #codepoints then return nil, i end

  local cp = codepoints[i]
  -- 必须以 emoji 基字符、区域指示器或键帽基字符开头
  if not is_emoji_base(cp) and not is_regional_indicator(cp) and not is_keycap_base(cp, codepoints, i) then
    return nil, i
  end

  local seq = { cp }
  local j = i + 1

  while j <= #codepoints do
    cp = codepoints[j]

    if is_variation_selector(cp) or is_skin_tone(cp) or is_keycap(cp) then
      table.insert(seq, cp)
      j = j + 1

    elseif is_zwj(cp) then
      table.insert(seq, cp)
      j = j + 1
      -- ZWJ 后必须跟 emoji 基字符
      if j <= #codepoints and (is_emoji_base(codepoints[j]) or is_regional_indicator(codepoints[j])) then
        table.insert(seq, codepoints[j])
        j = j + 1
        -- 吃掉 ZWJ 组件后的修饰符
        while j <= #codepoints do
          local nc = codepoints[j]
          if is_variation_selector(nc) or is_skin_tone(nc) or is_keycap(nc) then
            table.insert(seq, nc)
            j = j + 1
          else
            break
          end
        end
      else
        break
      end

    elseif is_regional_indicator(cp) then
      -- 区域指示器成对出现（国旗）
      if is_regional_indicator(seq[1]) and #seq == 1 then
        table.insert(seq, cp)
        j = j + 1
      else
        break
      end

    else
      break
    end
  end

  return seq, j
end

-- ============================================================
-- 格式特定包裹
-- ============================================================

--- XML 转义（用于 OpenXML）
function escape_xml(s)
  return s:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"):gsub('"', "&quot;")
end

--- 将 emoji 字符串按当前格式包裹为 RawInline
function wrap_emoji(text)
  if FORMAT:match("latex") then
    return pandoc.RawInline("latex", "\\emoji{" .. text .. "}")
  elseif FORMAT:match("context") then
    return pandoc.RawInline("context", "\\emoji{" .. text .. "}")
  elseif FORMAT:match("html") then
    return pandoc.RawInline("html", "<span class=\"emoji\">" .. text .. "</span>")
  elseif FORMAT:match("docx") or FORMAT:match("openxml") then
    return pandoc.RawInline("openxml",
      '<w:r><w:rPr>'
      .. '<w:rFonts w:ascii="Segoe UI Emoji" w:hAnsi="Segoe UI Emoji" w:eastAsia="Segoe UI Emoji"/>'
      .. '<w:sz w:val="32"/><w:szCs w:val="32"/>'
      .. '<w:color w:val="000000"/>'
      .. '</w:rPr>'
      .. '<w:t xml:space="preserve">' .. escape_xml(text) .. '</w:t></w:r>'
    )
  else
    -- 不认识的格式，原样保留
    return pandoc.Str(text)
  end
end

-- ============================================================
-- Pandoc 过滤器钩子
-- ============================================================

--- 读取 YAML 元数据中的 emoji 开关
function Meta(meta)
  if meta["emoji"] then
    local val = pandoc.utils.stringify(meta["emoji"]):lower()
    ENABLED = (val == "true" or val == "yes" or val == "1")
  end
  return meta
end

--- 逐个处理 Str 元素，拆解并包裹 emoji
function Str(elem)
  if not ENABLED then return nil end

  local text = elem.text

  -- 将字符串拆成 codepoint 数组，同时检测是否有 emoji
  local codepoints = {}
  local has_emoji = false
  for _, cp in utf8.codes(text) do
    table.insert(codepoints, cp)
    if not has_emoji then
      if is_emoji_base(cp) or is_regional_indicator(cp) then
        has_emoji = true
      end
    end
  end

  -- 检查键帽基字符（# * 0-9）后跟 VS16+键帽
  if not has_emoji then
    for i, cp in ipairs(codepoints) do
      if is_keycap_base(cp, codepoints, i) then
        has_emoji = true
        break
      end
    end
  end

  if not has_emoji then return nil end

  -- 逐个 codepoint 处理，拆解 emoji 序列
  local result = {}
  local i = 1

  while i <= #codepoints do
    local cp = codepoints[i]

    if is_emoji_base(cp) or is_regional_indicator(cp) or is_keycap_base(cp, codepoints, i) then
      local seq, next_i = parse_emoji_sequence(codepoints, i)
      if seq and #seq > 0 then
        local emoji_str = utf8.char(table.unpack(seq))
        table.insert(result, wrap_emoji(emoji_str))
        i = next_i
      else
        table.insert(result, pandoc.Str(utf8.char(cp)))
        i = i + 1
      end
    else
      table.insert(result, pandoc.Str(utf8.char(cp)))
      i = i + 1
    end
  end

  return result
end

return {
  { Meta = Meta },
  { Str  = Str },
}
