-- gbt9704-metadata.lua
-- Pandoc Lua filter: 将 YAML 元数据映射到 gbt9704.cls 的 LaTeX 命令
-- 仅对 LaTeX/PDF 输出生效
--
-- YAML 元数据字段映射：
--   header-org         → \makeheader{header-org}{header-number}{header-signatory}
--   header-number
--   header-signatory
--   redline            → documentclass option: redline (true/false)
--   subtitle           → \gongwensubtitle{subtitle}
--   mainreceiver       → \mainreceiver{mainreceiver}
--   attachments        → \begin{attachments}...\attachmentitem{...}...\end{attachments}
--   signature          → \signature{signature}
--   signdate           → \signdate{signdate}
--   notes              → \notes{notes}
--   copyto             → \copyto{copyto}
--   issue-author       → \issueinfo{issue-author}{issue-date}
--   issue-date
--
-- 正文自动包裹在 gongwenbody 环境中

local function escape_latex(s)
  if not s then return "" end
  return pandoc.utils.stringify(s)
end

local function raw_latex(text)
  return pandoc.RawBlock("latex", text)
end

function Pandoc(doc)
  if not FORMAT:match("latex") then
    return doc
  end

  local meta = doc.meta
  local pre_blocks = {}
  local post_blocks = {}

  -- === 1. 红头版头（先保存、再注入）===
  local header_org = meta["header-org"] and escape_latex(meta["header-org"]) or ""
  local header_num = meta["header-number"] and escape_latex(meta["header-number"]) or ""
  local header_sig = meta["header-signatory"] and escape_latex(meta["header-signatory"]) or ""

  if header_org ~= "" then
    table.insert(pre_blocks, raw_latex(
      string.format("\\makeheader{%s}{%s}{%s}", header_org, header_num, header_sig)
    ))
  end

  -- === 2. 标题：抑制默认 \maketitle，由 filter 在红头之后注入 ===
  local title_text = meta["title"] and escape_latex(meta["title"]) or ""
  if title_text ~= "" then
    -- 清除 title 元数据，防止 Pandoc 默认模板在红头之前输出 \maketitle
    doc.meta["title"] = nil
    table.insert(pre_blocks, raw_latex(
      string.format("\\gongwentitle{%s}", title_text)
    ))
  end

  -- === 3. 副标题 ===
  local subtitle = meta["subtitle"] and escape_latex(meta["subtitle"]) or ""
  if subtitle ~= "" then
    table.insert(pre_blocks, raw_latex(
      string.format("\\gongwensubtitle{%s}", subtitle)
    ))
  end

  -- === 4. 主送机关 ===
  local mainreceiver = meta["mainreceiver"] and escape_latex(meta["mainreceiver"]) or ""
  if mainreceiver ~= "" then
    table.insert(pre_blocks, raw_latex(
      string.format("\\mainreceiver{%s}", mainreceiver)
    ))
  end

  -- === 5. 开始正文环境 ===
  table.insert(pre_blocks, raw_latex("\\begin{gongwenbody}"))

  -- === 6. 结束正文环境 + 附件 ===
  table.insert(post_blocks, raw_latex("\\end{gongwenbody}"))

  -- 附件（多附件环境）
  local attachments = meta["attachments"]
  if attachments then
    -- 计算 MetaList 长度
    local count = 0
    for _ in pairs(attachments) do count = count + 1 end
    if count > 0 then
      table.insert(post_blocks, raw_latex("\\begin{attachments}"))
      for _, item in ipairs(attachments) do
        local text = escape_latex(item)
        if text ~= "" then
          table.insert(post_blocks, raw_latex(
            string.format("\\attachmentitem{%s}", text)
          ))
        end
      end
      table.insert(post_blocks, raw_latex("\\end{attachments}"))
    end
  end

  -- === 7. 发文机关署名 ===
  local signature = meta["signature"] and escape_latex(meta["signature"]) or ""
  if signature ~= "" then
    table.insert(post_blocks, raw_latex(
      string.format("\\signature{%s}", signature)
    ))
  end

  -- === 8. 成文日期（用 signdate 避免与 Pandoc date 解析冲突）===
  local signdate = meta["signdate"] and escape_latex(meta["signdate"]) or ""
  if signdate == "" then
    -- 回退：尝试用 Pandoc 标准 date 字段
    signdate = meta["date"] and escape_latex(meta["date"]) or ""
  end
  if signdate ~= "" and signdate ~= "Invalid Date" then
    table.insert(post_blocks, raw_latex(
      string.format("\\signdate{%s}", signdate)
    ))
  end

  -- === 9. 附注 ===
  local notes = meta["notes"] and escape_latex(meta["notes"]) or ""
  if notes ~= "" then
    table.insert(post_blocks, raw_latex(
      string.format("\\notes{%s}", notes)
    ))
  end

  -- === 10. 版记分隔线 ===
  local copyto = meta["copyto"] and escape_latex(meta["copyto"]) or ""
  local issue_author = meta["issue-author"] and escape_latex(meta["issue-author"]) or ""
  -- 版记部分（抄送+印发）需用分隔线与正文隔开
  if copyto ~= "" or issue_author ~= "" then
    table.insert(post_blocks, raw_latex("\\seprule"))
  end

  -- === 11. 抄送机关 ===
  if copyto ~= "" then
    table.insert(post_blocks, raw_latex(
      string.format("\\copyto{%s}", copyto)
    ))
  end

  -- === 12. 印发机关 + 印发日期 ===
  local issue_date = meta["issue-date"] and escape_latex(meta["issue-date"]) or ""
  if issue_author ~= "" then
    table.insert(post_blocks, raw_latex(
      string.format("\\issueinfo{%s}{%s}", issue_author, issue_date)
    ))
  end

  -- 组装：前置块 + 正文 + 后置块
  local new_blocks = {}
  for _, b in ipairs(pre_blocks) do
    table.insert(new_blocks, b)
  end
  for _, b in ipairs(doc.blocks) do
    table.insert(new_blocks, b)
  end
  for _, b in ipairs(post_blocks) do
    table.insert(new_blocks, b)
  end

  doc.blocks = new_blocks
  return doc
end

return { { Pandoc = Pandoc } }
