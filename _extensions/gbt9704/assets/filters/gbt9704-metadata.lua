-- gbt9704-metadata.lua
-- Pandoc Lua filter: 将 YAML 元数据映射到输出
-- 支持 PDF (LaTeX)、DOCX、ConTeXt 三种格式
--
-- YAML 元数据字段：
--   header-org, header-number, header-signatory → 红头版头 (PDF/ConTeXt)
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

local function raw_context(text)
  return pandoc.RawBlock("context", text)
end

local function raw_html(text)
  return pandoc.RawBlock("html", text)
end

local function para_text(text)
  return pandoc.Para({pandoc.Str(text)})
end

function Pandoc(doc)
  local meta = doc.meta
  local is_latex   = FORMAT:match("latex")
  local is_docx    = FORMAT:match("docx")
  local is_context = FORMAT:match("context")
  local is_html    = FORMAT:match("html")

  if not is_latex and not is_docx and not is_context and not is_html then
    return doc
  end

  local pre_blocks = {}
  local post_blocks = {}

  -- ============================================================
  -- 标题 (所有格式: 抑制默认输出，由 filter 在红头之后注入)
  -- ============================================================
  -- Fallback: meta["title"] 为空时，从正文第一个 H1 提取标题
  if not meta["title"] or escape(meta["title"]) == "" then
    for i, block in ipairs(doc.blocks) do
      if block.t == "Header" and block.level == 1 then
        local h1_text = pandoc.utils.stringify(block)
        if h1_text ~= "" then
          meta["title"] = h1_text
          table.remove(doc.blocks, i)
        end
        break
      end
    end
  end

  local title_text = meta["title"] and escape(meta["title"]) or ""

  if title_text ~= "" then
    doc.meta["title"] = nil
  end

  -- ============================================================
  -- 1. 红头版头
  -- ============================================================
  local h_org = escape(meta["header-org"])
  local h_num = escape(meta["header-number"])
  local h_sig = escape(meta["header-signatory"])

  if h_org ~= "" then
    if is_latex then
      table.insert(pre_blocks, raw_latex(
        string.format("\\makeheader{%s}{%s}{%s}", h_org, h_num, h_sig)
      ))
    elseif is_context then
      if h_org ~= "" then
        table.insert(pre_blocks, raw_context(
          string.format("\\startalignment[middle]{\\switchtobodyfont[22pt]\\DaBiaoSong\\color[officialred]{%s}}\\stopalignment", h_org)
        ))
      end
      if h_num ~= "" then
        table.insert(pre_blocks, raw_context(
          string.format("\\startalignment[middle]{\\switchtobodyfont[15pt]\\SimSun %s}\\stopalignment", h_num)
        ))
      end
      if h_sig ~= "" then
        table.insert(pre_blocks, raw_context(
          string.format("\\startalignment[middle]{\\switchtobodyfont[15pt]\\SimSun %s}\\stopalignment", h_sig)
        ))
      end
      -- 红线：通过 redline 元数据触发
      if meta["redline"] and escape(meta["redline"]) == "true" then
        table.insert(pre_blocks, raw_context("\\redseparator"))
      end
    elseif is_docx then
      -- 红头：居中、红色、22pt 粗体
      table.insert(pre_blocks, pandoc.RawBlock("openxml",
        string.format(
          '<w:p><w:pPr><w:jc w:val="center"/><w:ind w:firstLine="0"/></w:pPr><w:r><w:rPr><w:rFonts w:eastAsia="方正小标宋简体"/><w:sz w:val="44"/><w:color w:val="C8102E"/><w:b/></w:rPr><w:t xml:space="preserve">%s</w:t></w:r></w:p>',
          h_org
        )
      ))
      if h_num ~= "" then
        table.insert(pre_blocks, pandoc.RawBlock("openxml",
          string.format(
            '<w:p><w:pPr><w:jc w:val="center"/><w:ind w:firstLine="0"/></w:pPr><w:r><w:rPr><w:rFonts w:eastAsia="宋体"/><w:sz w:val="28"/></w:rPr><w:t xml:space="preserve">%s</w:t></w:r></w:p>',
            h_num
          )
        ))
      end
      if h_sig ~= "" then
        table.insert(pre_blocks, pandoc.RawBlock("openxml",
          string.format(
            '<w:p><w:pPr><w:jc w:val="center"/><w:ind w:firstLine="0"/></w:pPr><w:r><w:rPr><w:rFonts w:eastAsia="宋体"/><w:sz w:val="28"/></w:rPr><w:t xml:space="preserve">%s</w:t></w:r></w:p>',
            h_sig
          )
        ))
      end
      -- 红线：最小行高单格表格 + 红色底边框 1.5pt
      if meta["redline"] and escape(meta["redline"]) == "true" then
        table.insert(pre_blocks, pandoc.RawBlock("openxml",
          '<w:tbl><w:tblPr><w:tblBorders><w:bottom w:val="single" w:sz="12" w:space="0" w:color="C8102E"/></w:tblBorders><w:tblW w:w="5000" w:type="pct"/></w:tblPr><w:tblGrid><w:gridCol w:w="9072"/></w:tblGrid><w:tr><w:tc><w:tcPr><w:tcW w:w="9072" w:type="dxa"/></w:tcPr><w:p><w:pPr><w:spacing w:before="0" w:after="0" w:line="20" w:lineRule="atLeast"/></w:pPr><w:r><w:rPr><w:sz w:val="2"/></w:rPr><w:t xml:space="preserve"> </w:t></w:r></w:p></w:tc></w:tr></w:tbl>'
        ))
      end
    elseif is_html then
      table.insert(pre_blocks, raw_html(
        string.format('<div class="gbt-header"><p class="gbt-header-org">%s</p>', h_org)
      ))
      if h_num ~= "" then
        table.insert(pre_blocks, raw_html(
          string.format('<p class="gbt-header-number">%s</p>', h_num)
        ))
      end
      if h_sig ~= "" then
        table.insert(pre_blocks, raw_html(
          string.format('<p class="gbt-header-signatory">%s</p>', h_sig)
        ))
      end
      if meta["redline"] and escape(meta["redline"]) == "true" then
        table.insert(pre_blocks, raw_html('<hr class="gbt-redrule">'))
      end
      table.insert(pre_blocks, raw_html('</div>'))
    end
  end

  -- ============================================================
  -- 2. 大标题 (红头之后注入)
  -- ============================================================
  if title_text ~= "" then
    if is_latex then
      table.insert(pre_blocks, raw_latex(
        string.format("\\gongwentitle{%s}", title_text)
      ))
    elseif is_context then
      table.insert(pre_blocks, raw_context(
        string.format("\\officialtitle{%s}", title_text)
      ))
    elseif is_docx then
      table.insert(pre_blocks, pandoc.RawBlock("openxml",
        string.format(
          '<w:p><w:pPr><w:jc w:val="center"/><w:ind w:firstLine="0"/></w:pPr><w:r><w:rPr><w:rFonts w:eastAsia="方正小标宋简体"/><w:sz w:val="44"/><w:b/></w:rPr><w:t xml:space="preserve">%s</w:t></w:r></w:p>',
          title_text
        )
      ))
    elseif is_html then
      table.insert(pre_blocks, raw_html(
        string.format('<h1 class="gbt-title">%s</h1>', title_text)
      ))
    end
  end

  -- ============================================================
  -- 3. 副标题 (大标题之后注入)
  -- ============================================================
  local subtitle = escape(meta["subtitle"])
  if subtitle ~= "" then
    doc.meta["subtitle"] = nil
    if is_latex then
      table.insert(pre_blocks, raw_latex(
        string.format("\\gongwensubtitle{%s}", subtitle)
      ))
    elseif is_context then
      table.insert(pre_blocks, raw_context(
        string.format("\\startalignment[middle]{\\switchtobodyfont[16pt]\\FangSong %s}\\stopalignment", subtitle)
      ))
    elseif is_docx then
      table.insert(pre_blocks, pandoc.RawBlock("openxml",
        string.format(
          '<w:p><w:pPr><w:jc w:val="center"/><w:ind w:firstLine="0"/></w:pPr><w:r><w:rPr><w:rFonts w:eastAsia="仿宋_GB2312"/><w:sz w:val="32"/></w:rPr><w:t xml:space="preserve">%s</w:t></w:r></w:p>',
          subtitle
        )
      ))
    elseif is_html then
      table.insert(pre_blocks, raw_html(
        string.format('<p class="gbt-subtitle">%s</p>', subtitle)
      ))
    end
  end

  -- ============================================================
  -- 4. 主送机关
  -- ============================================================
  local mainreceiver = escape(meta["mainreceiver"])
  if mainreceiver ~= "" then
    if is_latex then
      table.insert(pre_blocks, raw_latex(
        string.format("\\mainreceiver{%s}", mainreceiver)
      ))
    elseif is_context then
      doc.meta["mainreceiver"] = nil  -- 抑制模板重复输出
      table.insert(pre_blocks, raw_context(
        string.format("\\mainrecipient{%s}", mainreceiver)
      ))
    elseif is_docx then
      table.insert(pre_blocks, pandoc.RawBlock("openxml",
        string.format(
          '<w:p><w:pPr><w:ind w:firstLine="0" w:firstLineChars="0"/></w:pPr><w:r><w:rPr><w:rFonts w:ascii="仿宋_GB2312" w:hAnsi="仿宋_GB2312" w:eastAsia="仿宋_GB2312"/></w:rPr><w:t xml:space="preserve">%s</w:t></w:r></w:p>',
          mainreceiver
        )
      ))
    elseif is_html then
      table.insert(pre_blocks, raw_html(
        string.format('<p class="gbt-mainreceiver">%s</p>', mainreceiver)
      ))
    end
  end

  -- ============================================================
  -- 5. 正文环境 (PDF only)
  -- ============================================================
  if is_latex then
    table.insert(pre_blocks, raw_latex("\\begin{gongwenbody}"))
    table.insert(post_blocks, raw_latex("\\end{gongwenbody}"))
  end

  -- ============================================================
  -- 6. 附件
  -- ============================================================
  local attachments = meta["attachments"]
  if attachments then
    local count = 0
    for _ in pairs(attachments) do count = count + 1 end
    if count > 0 then
      local first = true
      for _, item in ipairs(attachments) do
        local text = escape(item)
        if text ~= "" then
          if is_latex then
            if first then
              table.insert(post_blocks, raw_latex(
                string.format("\\attachmentHZ{%s}", text)
              ))
              first = false
            else
              table.insert(post_blocks, raw_latex(
                string.format("\\attachmentNOHZ{%s}", text)
              ))
            end
          elseif is_context then
            if first then
              -- 2em缩进 + "附件：" (匹配 LaTeX \attachmentHZ)
              table.insert(post_blocks, raw_context(
                string.format("\\noindent\\hskip2em\\switchtobodyfont[16pt]\\FangSong 附件：%s", text)
              ))
              first = false
            else
              -- 5em缩进 (对齐第一项 "附件：" 之后的文字)
              table.insert(post_blocks, raw_context(
                string.format("\\noindent\\hskip5em\\switchtobodyfont[16pt]\\FangSong %s", text)
              ))
            end
          elseif is_docx then
            if first then
              table.insert(post_blocks, para_text("附件：" .. text))
              first = false
            else
              table.insert(post_blocks, para_text("　　　" .. text))
            end
          elseif is_html then
            if first then
              table.insert(post_blocks, raw_html(
                string.format('<p class="gbt-attachment"><span class="gbt-attachment-label">附件：</span>%s</p>', text)
              ))
              first = false
            else
              table.insert(post_blocks, raw_html(
                string.format('<p class="gbt-attachment">%s</p>', text)
              ))
            end
          end
        end
      end
    end
  end

  -- ============================================================
  -- 7. 发文机关署名
  -- ============================================================
  local signature = escape(meta["signature"])
  if signature ~= "" then
    if is_latex then
      table.insert(post_blocks, raw_latex(
        string.format("\\signature{%s}", signature)
      ))
    elseif is_context then
      -- 右对齐 + 2字符右缩进 (\hfill 前推 + \hskip2em 右留白)
      table.insert(post_blocks, raw_context(
        string.format("{\\hfill\\switchtobodyfont[16pt]\\FangSong %s\\hskip2em}", signature)
      ))
    elseif is_docx then
      table.insert(post_blocks, pandoc.RawBlock("openxml",
        string.format(
          '<w:p><w:pPr><w:jc w:val="right"/><w:ind w:firstLine="0"/></w:pPr><w:r><w:t xml:space="preserve">%s</w:t></w:r></w:p>',
          signature
        )
      ))
    elseif is_html then
      table.insert(post_blocks, raw_html(
        string.format('<p class="gbt-signature">%s</p>', signature)
      ))
    end
  end

  -- ============================================================
  -- 8. 成文日期
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
    elseif is_context then
      -- 右对齐 + 2字符右缩进
      table.insert(post_blocks, raw_context(
        string.format("{\\hfill\\switchtobodyfont[16pt]\\FangSong %s\\hskip2em}", signdate)
      ))
    elseif is_docx then
      table.insert(post_blocks, pandoc.RawBlock("openxml",
        string.format(
          '<w:p><w:pPr><w:jc w:val="right"/><w:ind w:firstLine="0"/></w:pPr><w:r><w:t xml:space="preserve">%s</w:t></w:r></w:p>',
          signdate
        )
      ))
    elseif is_html then
      table.insert(post_blocks, raw_html(
        string.format('<p class="gbt-signdate">%s</p>', signdate)
      ))
    end
  end

  -- ============================================================
  -- 9. 附注
  -- ============================================================
  local notes = escape(meta["notes"])
  if notes ~= "" then
    if is_latex then
      table.insert(post_blocks, raw_latex(
        string.format("\\notes{%s}", notes)
      ))
    elseif is_context then
      table.insert(post_blocks, raw_context(
        string.format("\\noindent\\switchtobodyfont[16pt]\\FangSong （%s）", notes)
      ))
    elseif is_docx then
      table.insert(post_blocks, pandoc.RawBlock("openxml",
        string.format(
          '<w:p><w:pPr><w:ind w:firstLine="0"/></w:pPr><w:r><w:t xml:space="preserve">（%s）</w:t></w:r></w:p>',
          notes
        )
      ))
    elseif is_html then
      table.insert(post_blocks, raw_html(
        string.format('<p class="gbt-notes">（%s）</p>', notes)
      ))
    end
  end

  -- ============================================================
  -- 10. 版记：抄送 + 印发
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
  elseif is_context then
    if copyto ~= "" then
      table.insert(post_blocks, raw_context(
        string.format("\\noindent\\switchtobodyfont[16pt]\\FangSong 抄送：%s", copyto)
      ))
    end
    if issue_author ~= "" then
      table.insert(post_blocks, raw_context(
        string.format("\\noindent\\switchtobodyfont[16pt]\\FangSong %s\\hfill %s", issue_author, issue_date)
      ))
    end
  elseif is_docx then
    if copyto ~= "" then
      table.insert(post_blocks, pandoc.RawBlock("openxml",
        string.format(
          '<w:p><w:pPr><w:ind w:firstLine="0"/></w:pPr><w:r><w:t xml:space="preserve">抄送：%s</w:t></w:r></w:p>',
          copyto
        )
      ))
    end
    if issue_author ~= "" then
      table.insert(post_blocks, pandoc.RawBlock("openxml",
        string.format(
          '<w:p><w:pPr><w:ind w:firstLine="0"/><w:tabs><w:tab w:val="right" w:pos="9072"/></w:tabs></w:pPr><w:r><w:t xml:space="preserve">%s</w:t></w:r><w:r><w:tab/></w:r><w:r><w:t xml:space="preserve">%s</w:t></w:r></w:p>',
          issue_author, issue_date
        )
      ))
    end
  elseif is_html then
    if copyto ~= "" or issue_author ~= "" then
      table.insert(post_blocks, raw_html('<hr class="gbt-seprule">'))
    end
    if copyto ~= "" then
      table.insert(post_blocks, raw_html(
        string.format('<p class="gbt-copyto">抄送：%s</p>', copyto)
      ))
    end
    if issue_author ~= "" then
      table.insert(post_blocks, raw_html(
        string.format('<p class="gbt-issueinfo"><span class="gbt-issue-author">%s</span><span class="gbt-issue-date">%s</span></p>', issue_author, issue_date)
      ))
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
