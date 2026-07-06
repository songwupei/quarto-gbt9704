-- gbt9704-metadata.lua
-- Pandoc Lua filter: 将 YAML 元数据映射到输出
-- 支持 PDF (LaTeX) 和 DOCX 两种格式
--
-- YAML 元数据字段：
--   header-org, header-number, header-signatory → 红头版头 (PDF only)
--   subtitle           → 副标题
--   mainreceiver       → 主送机关
--   attachments        → 附件列表
--   signature          → 发文机关署名
--   signdate           → 成文日期
--   notes              → 附注
--   copyto             → 抄送机关
--   issue-author, issue-date → 印发机关和日期

local function escape(s)
  if not s then return "" end
  return pandoc.utils.stringify(s)
end

local function raw_latex(text)
  return pandoc.RawBlock("latex", text)
end

local function para_text(text)
  return pandoc.Para({pandoc.Str(text)})
end

function Pandoc(doc)
  local meta = doc.meta
  local is_latex = FORMAT:match("latex")
  local is_docx  = FORMAT:match("docx")

  if not is_latex and not is_docx then
    return doc
  end

  local pre_blocks = {}
  local post_blocks = {}

  -- ============================================================
  -- 标题 (PDF: 抑制默认 \maketitle 后自行注入 \gongwentitle)
  -- ============================================================
  local title_text = meta["title"] and escape(meta["title"]) or ""

  if is_latex and title_text ~= "" then
    doc.meta["title"] = nil  -- 抑制默认 \maketitle
  end

  -- ============================================================
  -- 1. 红头版头 (PDF only — DOCX 不需要红头)
  -- ============================================================
  if is_latex then
    local h_org = escape(meta["header-org"])
    local h_num = escape(meta["header-number"])
    local h_sig = escape(meta["header-signatory"])
    if h_org ~= "" then
      table.insert(pre_blocks, raw_latex(
        string.format("\\makeheader{%s}{%s}{%s}", h_org, h_num, h_sig)
      ))
    end
  end

  -- ============================================================
  -- 2. 大标题
  -- ============================================================
  if is_latex and title_text ~= "" then
    table.insert(pre_blocks, raw_latex(
      string.format("\\gongwentitle{%s}", title_text)
    ))
  end

  -- ============================================================
  -- 3. 副标题
  --   PDF: 清除 Pandoc 默认 subtitle，自行注入 \gongwensubtitle
  --   DOCX: Pandoc 默认处理 subtitle 字段，无需重复注入
  -- ============================================================
  local subtitle = escape(meta["subtitle"])
  if subtitle ~= "" then
    if is_latex then
      doc.meta["subtitle"] = nil  -- 抑制 Pandoc 默认 subtitle
      table.insert(pre_blocks, raw_latex(
        string.format("\\gongwensubtitle{%s}", subtitle)
      ))
    end
    -- DOCX: subtitle 由 Pandoc 默认模板处理，不重复注入
  end

  -- ============================================================
  -- 4. 主送机关
  --   PDF: \mainreceiver (自带 \noindent)
  --   DOCX: 用 Normal 样式（无首行缩进）
  -- ============================================================
  local mainreceiver = escape(meta["mainreceiver"])
  if mainreceiver ~= "" then
    if is_latex then
      table.insert(pre_blocks, raw_latex(
        string.format("\\mainreceiver{%s}", mainreceiver)
      ))
    elseif is_docx then
      table.insert(pre_blocks, pandoc.RawBlock("openxml",
        string.format(
          '<w:p><w:pPr><w:pStyle w:val="Normal"/></w:pPr><w:r><w:t xml:space="preserve">%s</w:t></w:r></w:p>',
          mainreceiver
        )
      ))
    end
  end

  -- ============================================================
  -- 5. 开始正文环境 (PDF only)
  -- ============================================================
  if is_latex then
    table.insert(pre_blocks, raw_latex("\\begin{gongwenbody}"))
  end

  -- ============================================================
  -- 6. 结束正文环境 (PDF only)
  -- ============================================================
  if is_latex then
    table.insert(post_blocks, raw_latex("\\end{gongwenbody}"))
  end

  -- ============================================================
  -- 7. 附件
  -- ============================================================
  local attachments = meta["attachments"]
  if attachments then
    local count = 0
    for _ in pairs(attachments) do count = count + 1 end
    if count > 0 then
      if is_latex then
        table.insert(post_blocks, raw_latex("\\begin{attachments}"))
        for _, item in ipairs(attachments) do
          local text = escape(item)
          if text ~= "" then
            table.insert(post_blocks, raw_latex(
              string.format("\\attachmentitem{%s}", text)
            ))
          end
        end
        table.insert(post_blocks, raw_latex("\\end{attachments}"))
      elseif is_docx then
        local first = true
        for _, item in ipairs(attachments) do
          local text = escape(item)
          if text ~= "" then
            if first then
              table.insert(post_blocks, para_text("附件：" .. text))
              first = false
            else
              table.insert(post_blocks, para_text("　　　" .. text))
            end
          end
        end
      end
    end
  end

  -- ============================================================
  -- 8. 发文机关署名
  -- ============================================================
  local signature = escape(meta["signature"])
  if signature ~= "" then
    if is_latex then
      table.insert(post_blocks, raw_latex(
        string.format("\\signature{%s}", signature)
      ))
    elseif is_docx then
      table.insert(post_blocks, para_text(signature))
    end
  end

  -- ============================================================
  -- 9. 成文日期
  -- ============================================================
  local signdate = escape(meta["signdate"])
  if signdate == "" then
    signdate = escape(meta["date"])
  end
  if signdate ~= "" and signdate ~= "Invalid Date" then
    if is_latex then
      table.insert(post_blocks, raw_latex(
        string.format("\\signdate{%s}", signdate)
      ))
    elseif is_docx then
      table.insert(post_blocks, para_text(signdate))
    end
  end

  -- ============================================================
  -- 10. 附注
  -- ============================================================
  local notes = escape(meta["notes"])
  if notes ~= "" then
    if is_latex then
      table.insert(post_blocks, raw_latex(
        string.format("\\notes{%s}", notes)
      ))
    elseif is_docx then
      table.insert(post_blocks, para_text("（" .. notes .. "）"))
    end
  end

  -- ============================================================
  -- 11. 版记分隔线 + 抄送 + 印发
  -- ============================================================
  local copyto = escape(meta["copyto"])
  local issue_author = escape(meta["issue-author"])
  local issue_date = escape(meta["issue-date"])

  if is_latex then
    if copyto ~= "" or issue_author ~= "" then
      table.insert(post_blocks, raw_latex("\\seprule"))
    end
    if copyto ~= "" then
      table.insert(post_blocks, raw_latex(
        string.format("\\copyto{%s}", copyto)
      ))
    end
    if issue_author ~= "" then
      table.insert(post_blocks, raw_latex(
        string.format("\\issueinfo{%s}{%s}", issue_author, issue_date)
      ))
    end
  elseif is_docx then
    if copyto ~= "" then
      table.insert(post_blocks, para_text("抄送：" .. copyto))
    end
    if issue_author ~= "" then
      table.insert(post_blocks, para_text(issue_author .. "  " .. issue_date))
    end
  end

  -- ============================================================
  -- 组装
  -- ============================================================
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
