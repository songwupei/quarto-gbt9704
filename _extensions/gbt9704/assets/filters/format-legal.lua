-- format-legal.lua
-- 处理三种公文结构（仅 LaTeX/PDF 输出）：
--   1. 第X章 + 空格 → 三号黑体居中，空格替换为全角空格
--   2. 第X节 + 空格 → 三号黑体居中，空格替换为全角空格
--   3. 第X条 + 空格 → 正文内无衬线字体 + 全角空格

local function is_tiao_word(text)
    return text:match("^第[一二三四五六七八九十百千万0-9]+条$") ~= nil
end

local function is_zhang_word(text)
    return text:match("^第[一二三四五六七八九十百千万0-9]+章") ~= nil
end

local function is_jie_word(text)
    return text:match("^第[一二三四五六七八九十百千万0-9]+节") ~= nil
end

local function is_space(elem)
    if elem.t == "Space" then return true end
    if elem.t == "Str" and elem.text == "　" then return true end
    return false
end

function Pandoc(doc)
    if not FORMAT:match("latex") then
        return doc
    end

    local new_blocks = {}

    for _, blk in ipairs(doc.blocks) do
        if blk.t == "Para" then
            local content = blk.content
            local pos = 1
            local leading_spaces = {}

            -- 收集段首空格
            while pos <= #content and is_space(content[pos]) do
                table.insert(leading_spaces, content[pos])
                pos = pos + 1
            end

            if pos <= #content and content[pos].t == "Str" then
                local first_text = content[pos].text
                local is_heading = false
                local heading_text = nil
                local heading_end = pos

                -- 判断“第X章”
                if is_zhang_word(first_text) then
                    is_heading = true
                    heading_text = first_text
                    heading_end = pos
                elseif first_text == "第" and pos+1 <= #content and content[pos+1].t == "Str" and
                       is_zhang_word("第" .. content[pos+1].text) then
                    is_heading = true
                    heading_text = "第" .. content[pos+1].text
                    heading_end = pos + 1
                -- 判断“第X节”
                elseif is_jie_word(first_text) then
                    is_heading = true
                    heading_text = first_text
                    heading_end = pos
                elseif first_text == "第" and pos+1 <= #content and content[pos+1].t == "Str" and
                       is_jie_word("第" .. content[pos+1].text) then
                    is_heading = true
                    heading_text = "第" .. content[pos+1].text
                    heading_end = pos + 1
                end

                -- 如果是章节标题，且后面紧跟空格
                if is_heading and heading_end+1 <= #content and is_space(content[heading_end+1]) then
                    -- 获取段落纯文本
                    local raw_text = pandoc.utils.stringify(blk)
                    -- 将标题词后的连续空白（含半角/全角空格、制表符等）替换为一个全角空格
                    local pattern = "^(" .. heading_text .. ")%s+"
                    local replaced_text = raw_text:gsub(pattern, "%1　")
                    -- 生成 LaTeX 块
                    local latex_block = string.format(
                        "\\begin{center}\n\\sffamily\\bfseries\\fontsize{16pt}{20pt}\\selectfont %s\\par\n\\end{center}",
                        replaced_text
                    )
                    table.insert(new_blocks, pandoc.RawBlock("latex", latex_block))

                -- 否则尝试处理“第X条”
                else
                    local matched_tiao = false
                    local tiao_text = nil
                    local tiao_end = pos

                    if is_tiao_word(content[pos].text) then
                        matched_tiao = true
                        tiao_text = content[pos].text
                        tiao_end = pos
                    elseif content[pos].text == "第" and pos+1 <= #content and
                           content[pos+1].t == "Str" and is_tiao_word("第" .. content[pos+1].text) then
                        matched_tiao = true
                        tiao_text = "第" .. content[pos+1].text
                        tiao_end = pos + 1
                    end

                    if matched_tiao and tiao_end+1 <= #content and is_space(content[tiao_end+1]) then
                        local new_inlines = {}
                        -- 保留段首空格
                        for _, sp in ipairs(leading_spaces) do
                            table.insert(new_inlines, sp)
                        end
                        -- 无衬线字体“第X条”
                        table.insert(new_inlines, pandoc.RawInline("latex", "\\textsf{" .. tiao_text .. "}"))
                        -- 强制全角空格
                        table.insert(new_inlines, pandoc.Str("　"))
                        -- 剩余内容
                        for i = tiao_end + 2, #content do
                            table.insert(new_inlines, content[i])
                        end
                        table.insert(new_blocks, pandoc.Para(new_inlines, blk.attr))
                    else
                        table.insert(new_blocks, blk)
                    end
                end
            else
                table.insert(new_blocks, blk)
            end
        else
            table.insert(new_blocks, blk)
        end
    end

    doc.blocks = new_blocks
    return doc
end

return { { Pandoc = Pandoc } }
