-- ============================================================================
-- pre-clean-markitdown.lua — 清除 markitdown (PDF→MD) 转换产生的格式问题
-- ============================================================================
-- 受 YAML 元数据 `pre-clean: markitdown` 控制。
--
-- 清理规则：
--   1. 删除页码标记段落（"— N —"）
--   2. 删除破损表格碎片（孤立的 |...| 行）
--   3. 分割被 markitdown 合并的段落（在 第X章/节/条 前断开）
--   4. 合并被页码切断的相邻段落
--
-- 支持所有输出格式（HTML、DOCX、PDF/LaTeX、ConTeXt）。
-- 设计为 filter 链的第一道，确保后续 filter 拿到干净 AST。
-- ============================================================================

local pre_clean = nil

-- ============================================================================
-- 工具函数
-- ============================================================================

-- Lua 5.3 的字符类 [abc] 按字节匹配，不支持多字节 UTF-8 字符
-- 因此使用逐字 literal gsub 替代字符类

-- 检测段落是否为页码标记：— 1 —、— 12 — 等
-- 支持 em-dash (U+2014)、en-dash (U+2013)、以及普通 ASCII dash
local function is_page_number(text)
  -- 逐字去掉前后破折号
  text = text:gsub("^—", ""):gsub("—$", "")
  text = text:gsub("^–", ""):gsub("–$", "")
  text = text:gsub("^%-", ""):gsub("%-$", "")
  -- 去掉残留空白
  text = text:gsub("^%s+", ""):gsub("%s+$", "")
  return text:match("^%d+$") ~= nil
end

-- 检测文本是否包含中文标点（逐字 literal 匹配，避免 UTF-8 字符类问题）
local function has_chinese_punctuation(text)
  local puncts = {"。", "，", "！", "？", "；", "：", "、",
                  "）", "】", "》", "」", "』", "」", "》"}
  for _, p in ipairs(puncts) do
    if text:find(p, 1, true) then  -- plain text find, no pattern
      return true
    end
  end
  return false
end

-- 检测段落是否为破损表格碎片
-- 特征：整段为 |...| 格式，不含中文标点（说明不是正文段落）
local function is_broken_table_fragment(text)
  -- 纯分隔行：| --- | :--- | 等
  if text:match("^|%s*[-:]+%s*|") then
    return true
  end
  -- 数据行：以 | 开头结尾，且不包含中文标点
  if text:match("^|.+|$") and not has_chinese_punctuation(text) then
    return true
  end
  return false
end

-- ============================================================================
-- 段落分割：markitdown 丢失了段落边界，需在 第X章/节/条 前断开
-- ============================================================================

-- 检测文本是否以文档结构标记开头
-- 第X章/节/条（X=中文或阿拉伯数字）、（一）（二）等中文数字子项
local function starts_with_structure(text)
  -- 第X章、第X节、第X条
  if text:match("^第[%w一二三四五六七八九十百千]+[章节条]") then
    return true
  end
  -- （一）（二）...中文数字加全角括号的子项
  if text:match("^（[一二三四五六七八九十百千]+）") then
    return true
  end
  return false
end

-- 判断 inline 列表是否为空或仅含空白（Space、SoftBreak、LineBreak）
local function is_blank_inlines(inlines)
  for _, il in ipairs(inlines) do
    if il.t ~= "Space" and il.t ~= "SoftBreak" and il.t ~= "LineBreak" then
      return false
    end
  end
  return true
end

-- 去除 inline 列表首尾的空白节点
local function trim_inlines(inlines)
  while #inlines > 0 do
    local t = inlines[1].t
    if t == "Space" or t == "SoftBreak" or t == "LineBreak" then
      table.remove(inlines, 1)
    else
      break
    end
  end
  while #inlines > 0 do
    local t = inlines[#inlines].t
    if t == "Space" or t == "SoftBreak" or t == "LineBreak" then
      table.remove(inlines, #inlines)
    else
      break
    end
  end
  return inlines
end

-- 分割 Para/Plain 块：在 SoftBreak/LineBreak + 第X章/节/条 处断开
-- 返回 block 列表（可能只有原 block 一个元素）
local function split_at_structure(blk)
  if blk.t ~= "Para" and blk.t ~= "Plain" then
    return {blk}
  end

  local inlines = blk.content
  if #inlines == 0 then
    return {blk}
  end

  -- 先检查是否需要分割（避免对不需要分割的段落做无用功）
  local needs_split = false
  for i = 1, #inlines - 1 do
    if inlines[i].t == "SoftBreak" or inlines[i].t == "LineBreak" then
      local next_idx = i + 1
      while next_idx <= #inlines and inlines[next_idx].t == "Space" do
        next_idx = next_idx + 1
      end
      if next_idx <= #inlines and inlines[next_idx].t == "Str" then
        if starts_with_structure(inlines[next_idx].text) then
          needs_split = true
          break
        end
      end
    end
  end

  if not needs_split then
    return {blk}
  end

  -- 执行分割
  local segments = {}  -- {start_idx, end_idx} 对
  local seg_start = 1

  for i = 1, #inlines - 1 do
    if inlines[i].t == "SoftBreak" or inlines[i].t == "LineBreak" then
      local next_idx = i + 1
      while next_idx <= #inlines and inlines[next_idx].t == "Space" do
        next_idx = next_idx + 1
      end
      if next_idx <= #inlines and inlines[next_idx].t == "Str" then
        if starts_with_structure(inlines[next_idx].text) then
          -- 当前段：seg_start 到 i-1（不包含这个 SoftBreak）
          table.insert(segments, {start = seg_start, end_ = i - 1})
          -- 新段从 "第X章/条" 开始（跳过 SoftBreak 和中间空格）
          seg_start = next_idx
        end
      end
    end
  end

  -- 最后一段
  table.insert(segments, {start = seg_start, end_ = #inlines})

  -- 构建结果 blocks
  local result = {}
  for _, seg in ipairs(segments) do
    local seg_inlines = {}
    for j = seg.start, seg.end_ do
      table.insert(seg_inlines, inlines[j])
    end
    seg_inlines = trim_inlines(seg_inlines)
    if #seg_inlines > 0 and not is_blank_inlines(seg_inlines) then
      -- 保持原 block 类型（Para 或 Plain）
      local new_blk
      if blk.t == "Plain" then
        new_blk = pandoc.Plain(seg_inlines)
      else
        new_blk = pandoc.Para(seg_inlines)
      end
      new_blk.attr = blk.attr
      table.insert(result, new_blk)
    end
  end

  -- 如果分割后只有一个块，返回原块
  if #result <= 1 then
    return {blk}
  end

  return result
end

-- ============================================================================
-- 块过滤
-- ============================================================================

local function should_keep_block(blk)
  if blk.t == "Para" or blk.t == "Plain" then
    local text = pandoc.utils.stringify(blk):gsub("^%s+", ""):gsub("%s+$", "")
    if text == "" then
      return true  -- 空白段落保留
    end
    if is_page_number(text) then
      return false
    end
    if is_broken_table_fragment(text) then
      return false
    end
  end
  return true
end

-- ============================================================================
-- Inline 级页码清理：从段落内部删除 — N — 序列
-- ============================================================================

-- 检测单个 Str 是否为破折号（em-dash、en-dash、ASCII dash）
local function is_dash_str(s)
  return s == "—" or s == "–" or s == "-"
end

-- 从 inline 列表中清除 "SoftBreak + — N —" 模式
-- 返回清理后的 inline 列表
local function clean_page_numbers_from_inlines(inlines)
  local result = {}
  local i = 1
  while i <= #inlines do
    local matched = false
    local pos = i

    -- 可选前导 SoftBreak/LineBreak
    if pos <= #inlines and (inlines[pos].t == "SoftBreak" or inlines[pos].t == "LineBreak") then
      pos = pos + 1
    end

    -- 跳过空格
    while pos <= #inlines and inlines[pos].t == "Space" do
      pos = pos + 1
    end

    -- 匹配开头破折号
    if pos <= #inlines and inlines[pos].t == "Str" and is_dash_str(inlines[pos].text) then
      pos = pos + 1
      -- 跳过空格
      while pos <= #inlines and inlines[pos].t == "Space" do
        pos = pos + 1
      end
      -- 匹配数字
      if pos <= #inlines and inlines[pos].t == "Str" and inlines[pos].text:match("^%d+$") then
        pos = pos + 1
        -- 跳过空格
        while pos <= #inlines and inlines[pos].t == "Space" do
          pos = pos + 1
        end
        -- 匹配结尾破折号
        if pos <= #inlines and inlines[pos].t == "Str" and is_dash_str(inlines[pos].text) then
          pos = pos + 1
          -- 可选尾随 SoftBreak
          if pos <= #inlines and (inlines[pos].t == "SoftBreak" or inlines[pos].t == "LineBreak") then
            pos = pos + 1
          end
          matched = true
          i = pos
        end
      end
    end

    if not matched then
      table.insert(result, inlines[i])
      i = i + 1
    end
  end
  return result
end

-- ============================================================================
-- 段落合并：页码删除后，合并不以句号结尾的相邻段落
-- ============================================================================

-- 检测文本是否以句末标点结尾
-- 逐字 literal 比较，避免 Lua [。！？] 字符类无法匹配 UTF-8 多字节字符
local function ends_with_sentence_end(text)
  if #text < 3 then return false end
  local tail = text:sub(-3)  -- 取最后 3 字节（一个中文字符 = 3 字节 UTF-8）
  return tail == "。" or tail == "！" or tail == "？"
end

-- 判断块是否为"空白段落"（仅含空格/空内容）
local function is_empty_para(blk)
  if blk.t ~= "Para" and blk.t ~= "Plain" then return false end
  local text = pandoc.utils.stringify(blk):gsub("%s+", "")
  return text == ""
end

-- 在数组中查找第 start_idx 个非空的 Para/Plain 块
-- 返回: next_idx, block  (若找不到返回 nil)
local function find_next_nonempty(blocks, start_idx)
  local j = start_idx
  while j <= #blocks do
    local b = blocks[j]
    if b.t == "Para" or b.t == "Plain" then
      if not is_empty_para(b) then
        return j, b
      end
    else
      -- 非 Para/Plain 块打断搜索
      return nil, nil
    end
    j = j + 1
  end
  return nil, nil
end

local function merge_adjacent_paragraphs(blocks)
  local result = {}
  local i = 1
  while i <= #blocks do
    local blk = blocks[i]
    -- 跳过空段落
    if is_empty_para(blk) then
      i = i + 1
    elseif blk.t == "Para" or blk.t == "Plain" then
      local text1 = pandoc.utils.stringify(blk):gsub("%s+$", "")
      if ends_with_sentence_end(text1) then
        -- 句末结束，不合并
        table.insert(result, blk)
        i = i + 1
      else
        -- 查找下一个可合并的段落（跳过空段落）
        local next_idx, next_blk = find_next_nonempty(blocks, i + 1)
        if next_idx and next_blk then
          local text2 = pandoc.utils.stringify(next_blk):gsub("^%s+", "")
          if not starts_with_structure(text2) then
            -- 合并 blk + 中间的空段落 + next_blk
            local merged = {}
            for _, il in ipairs(blk.content) do table.insert(merged, il) end
            for _, il in ipairs(next_blk.content) do table.insert(merged, il) end
            blk.content = merged
            table.insert(result, blk)
            i = next_idx + 1
          else
            table.insert(result, blk)
            i = i + 1
          end
        else
          table.insert(result, blk)
          i = i + 1
        end
      end
    else
      table.insert(result, blk)
      i = i + 1
    end
  end
  return result
end

-- ============================================================================
-- Meta 阶段：读取 pre-clean 选项
-- ============================================================================

function Meta(meta)
  if meta["pre-clean"] then
    pre_clean = pandoc.utils.stringify(meta["pre-clean"])
  end
  return nil  -- 不修改 metadata
end

-- ============================================================================
-- Pandoc 阶段：遍历 AST 块，清除 markitdown 痕迹
-- ============================================================================

function Pandoc(doc)
  if pre_clean ~= "markitdown" then
    return doc
  end

  local new_blocks = {}
  for _, blk in ipairs(doc.blocks) do
    -- Pass 1: 在 第X章/节/条 前断开被合并的段落
    local sub_blocks = split_at_structure(blk)
    for _, sub in ipairs(sub_blocks) do
      -- Pass 2: 从段落内部删除 — N — 序列
      if sub.t == "Para" or sub.t == "Plain" then
        sub.content = clean_page_numbers_from_inlines(sub.content)
      end
      -- Pass 3: 过滤页码段落和表格碎片
      if should_keep_block(sub) then
        table.insert(new_blocks, sub)
      end
    end
  end

  -- Pass 4: 合并被页码切断的相邻段落（跳过空段落）
  doc.blocks = merge_adjacent_paragraphs(new_blocks)

  return doc
end

-- ============================================================================
-- 表格式返回（参考 format-zhidu.lua 模式）
-- ============================================================================

return {
  { Meta = Meta },
  { Pandoc = Pandoc },
}
