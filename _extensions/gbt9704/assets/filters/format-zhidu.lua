-- ============================================================================
-- format-zhidu.lua — 制度文档格式渲染
-- ============================================================================
-- 受 YAML 元数据 `title-type: zhidu` 控制。
--
-- 规则：
--   1. H2 (##) → 转为居中段落：整行黑体加粗，不缩进，"第X章"后两个全角空格
--   2. H3 (###) → 转为普通段落："第X条" 黑体加粗 + 两个全角空格，其余正文
--   3. H2/H3 若不以 第X章/第X条 开头，仍转为普通段落（不添加特殊样式）
--
-- 支持的输出格式：PDF（LaTeX）、DOCX（OpenXML）、HTML
-- ============================================================================

local is_zhidu = false

-- ============================================================================
-- 工具函数
-- ============================================================================

local function escape_xml(s)
  return s:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"):gsub('"', "&quot;"):gsub("'", "&apos;")
end

-- LaTeX 特殊字符安全转义（与 gbt9704-metadata.lua 同策略）
local function latex_escape(s)
  if not s then return "" end
  local out, i, n = {}, 1, #s
  while i <= n do
    local c = s:sub(i, i)
    if c == "\\" then
      if s:sub(i + 1, i + 1) == "\\" then
        out[#out + 1] = "\\\\"
        i = i + 2
      else
        out[#out + 1] = "\\textbackslash{}"
        i = i + 1
      end
    elseif c == "$" or c == "&" or c == "%" or c == "#" or c == "_" or c == "{" or c == "}" then
      out[#out + 1] = "\\" .. c
      i = i + 1
    elseif c == "^" then
      out[#out + 1] = "\\textasciicircum{}"
      i = i + 1
    elseif c == "~" then
      out[#out + 1] = "\\textasciitilde{}"
      i = i + 1
    else
      out[#out + 1] = c
      i = i + 1
    end
  end
  return table.concat(out)
end

-- 提取 "第X章" 或 "第X条" 编号词
local function extract_number_word(text, suffix)
  -- 直接匹配：开头的 "第...章" 或 "第...条"
  local pattern = "^(第[%w一二三四五六七八九十百千万]+" .. suffix .. ")"
  return text:match(pattern)
end

-- 将编号词后的空白替换为两个全角空格
local function insert_double_fullwidth_space(text, number_word)
  if not number_word then return text end
  local pattern = "^(" .. number_word .. ")%s+"
  local replaced = text:gsub(pattern, "%1　　")
  return replaced
end

-- ============================================================================
-- 各格式渲染
-- ============================================================================

-- --- LaTeX ---

local function render_chapter_latex(number_word, text)
  local formatted = insert_double_fullwidth_space(text, number_word)
  return string.format(
    "\\begin{center}\n\\heiti\\bfseries\\fontsize{16pt}{20pt}\\selectfont %s\n\\end{center}",
    latex_escape(formatted)
  )
end

local function render_chapter_latex_no_number(text)
  return string.format(
    "\\begin{center}\n\\heiti\\bfseries\\fontsize{16pt}{20pt}\\selectfont %s\n\\end{center}",
    latex_escape(text)
  )
end

local function render_article_latex(number_word, text)
  local rest = text:sub(#number_word + 1):gsub("^%s+", "")
  return string.format(
    "{\\heiti\\bfseries %s}　　%s",
    latex_escape(number_word), latex_escape(rest)
  )
end

local function render_article_latex_no_number(text)
  return latex_escape(text)
end

-- --- DOCX (OpenXML) ---

local function render_chapter_docx(number_word, text)
  local formatted = insert_double_fullwidth_space(text, number_word)
  formatted = escape_xml(formatted)
  return string.format(
    '<w:p><w:pPr><w:jc w:val="center"/><w:ind w:firstLine="0"/></w:pPr>'
    .. '<w:r><w:rPr><w:rFonts w:eastAsia="黑体"/><w:sz w:val="32"/><w:b/></w:rPr>'
    .. '<w:t xml:space="preserve">%s</w:t></w:r></w:p>',
    formatted
  )
end

local function render_chapter_docx_no_number(text)
  text = escape_xml(text)
  return string.format(
    '<w:p><w:pPr><w:jc w:val="center"/><w:ind w:firstLine="0"/></w:pPr>'
    .. '<w:r><w:rPr><w:rFonts w:eastAsia="黑体"/><w:sz w:val="32"/><w:b/></w:rPr>'
    .. '<w:t xml:space="preserve">%s</w:t></w:r></w:p>',
    text
  )
end

local function render_article_docx(number_word, text)
  local rest = text:sub(#number_word + 1):gsub("^%s+", "")
  local tiao_part = escape_xml(number_word .. "　　")
  local rest_part = escape_xml(rest)
  return string.format(
    '<w:p>'
    .. '<w:r><w:rPr><w:rFonts w:eastAsia="黑体"/><w:sz w:val="32"/><w:b/></w:rPr>'
    .. '<w:t xml:space="preserve">%s</w:t></w:r>'
    .. '<w:r><w:rPr><w:rFonts w:eastAsia="仿宋_GB2312"/><w:sz w:val="32"/></w:rPr>'
    .. '<w:t xml:space="preserve">%s</w:t></w:r>'
    .. '</w:p>',
    tiao_part, rest_part
  )
end

local function render_article_docx_no_number(text)
  text = escape_xml(text)
  return string.format(
    '<w:p><w:r><w:rPr><w:rFonts w:eastAsia="仿宋_GB2312"/><w:sz w:val="32"/></w:rPr>'
    .. '<w:t xml:space="preserve">%s</w:t></w:r></w:p>',
    text
  )
end

-- --- HTML ---

local function render_chapter_html(number_word, text)
  local formatted = insert_double_fullwidth_space(text, number_word)
  return string.format('<p class="gbt-zhidu-chapter">%s</p>', formatted)
end

local function render_chapter_html_no_number(text)
  return string.format('<p class="gbt-zhidu-chapter">%s</p>', text)
end

local function render_article_html(number_word, text)
  local rest = text:sub(#number_word + 1):gsub("^%s+", "")
  return string.format(
    '<p class="gbt-zhidu-article"><strong>%s</strong>　　%s</p>',
    number_word, rest
  )
end

local function render_article_html_no_number(text)
  return string.format('<p>%s</p>', text)
end

-- ============================================================================
-- 主处理
-- ============================================================================

function Pandoc(doc)
  if not is_zhidu then return doc end

  local is_latex = FORMAT:match("latex")
  local is_docx  = FORMAT:match("docx")
  local is_html  = FORMAT:match("html")

  if not is_latex and not is_docx and not is_html then
    return doc
  end

  local new_blocks = {}

  for _, blk in ipairs(doc.blocks) do
    if blk.t == "Header" and blk.level == 2 then
      local text = pandoc.utils.stringify(blk)
      local chapter_word = extract_number_word(text, "章")

      if chapter_word then
        if is_latex then
          table.insert(new_blocks, pandoc.RawBlock("latex", render_chapter_latex(chapter_word, text)))
        elseif is_docx then
          table.insert(new_blocks, pandoc.RawBlock("openxml", render_chapter_docx(chapter_word, text)))
        elseif is_html then
          table.insert(new_blocks, pandoc.RawBlock("html", render_chapter_html(chapter_word, text)))
        end
      else
        -- H2 但不以 "第X章" 开头：仍转为居中黑体段落
        if is_latex then
          table.insert(new_blocks, pandoc.RawBlock("latex", render_chapter_latex_no_number(text)))
        elseif is_docx then
          table.insert(new_blocks, pandoc.RawBlock("openxml", render_chapter_docx_no_number(text)))
        elseif is_html then
          table.insert(new_blocks, pandoc.RawBlock("html", render_chapter_html_no_number(text)))
        end
      end

    elseif blk.t == "Header" and blk.level == 3 then
      local text = pandoc.utils.stringify(blk)
      local tiao_word = extract_number_word(text, "条")

      if tiao_word then
        if is_latex then
          table.insert(new_blocks, pandoc.RawBlock("latex", render_article_latex(tiao_word, text)))
        elseif is_docx then
          table.insert(new_blocks, pandoc.RawBlock("openxml", render_article_docx(tiao_word, text)))
        elseif is_html then
          table.insert(new_blocks, pandoc.RawBlock("html", render_article_html(tiao_word, text)))
        end
      else
        -- H3 但不以 "第X条" 开头：转为普通正文段落
        if is_latex then
          table.insert(new_blocks, pandoc.RawBlock("latex", render_article_latex_no_number(text)))
        elseif is_docx then
          table.insert(new_blocks, pandoc.RawBlock("openxml", render_article_docx_no_number(text)))
        elseif is_html then
          table.insert(new_blocks, pandoc.RawBlock("html", render_article_html_no_number(text)))
        end
      end

    else
      table.insert(new_blocks, blk)
    end
  end

  doc.blocks = new_blocks
  return doc
end

-- ============================================================================
-- 表格式返回：Meta 阶段读取 title-type
-- ============================================================================

return {
  {
    Meta = function(meta)
      local tt = meta["title-type"]
      if tt then
        is_zhidu = pandoc.utils.stringify(tt):lower() == "zhidu"
      end
      return nil
    end,
  },
  {
    Pandoc = Pandoc,
  },
}
