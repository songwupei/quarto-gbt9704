-- title-promotion.lua (pandoc.text UTF-8 安全)
local function promote(text)
  if not text then return nil end
  local len = pandoc.text.len(text)

  -- Rule 1: 一、、二、、... → Heading 1
  if len >= 2 and pandoc.text.sub(text, 2, 2) == "、" then
    local first_char = pandoc.text.sub(text, 1, 1)
    if first_char == "一" or first_char == "二" or first_char == "三" or first_char == "四"
       or first_char == "五" or first_char == "六" or first_char == "七" or first_char == "八"
       or first_char == "九" or first_char == "十" then
      return pandoc.Header(1, pandoc.Str(text))
    end
  end

  -- Rule 2: （一）、（二）、... → Heading 2
  if len >= 3 and pandoc.text.sub(text, 1, 1) == "（"
     and pandoc.text.sub(text, 3, 3) == "）" then
    local mid = pandoc.text.sub(text, 2, 2)
    if mid == "一" or mid == "二" or mid == "三" or mid == "四"
       or mid == "五" or mid == "六" or mid == "七" or mid == "八"
       or mid == "九" or mid == "十" then
      return pandoc.Header(2, pandoc.Str(text))
    end
  end

  -- Rule 3: 1.、2.、... → Heading 3
  if len >= 2 then
    local fc = pandoc.text.sub(text, 1, 1)
    local sc = pandoc.text.sub(text, 2, 2)
    if (fc == "0" or fc == "1" or fc == "2" or fc == "3"
        or fc == "4" or fc == "5" or fc == "6" or fc == "7"
        or fc == "8" or fc == "9") and (sc == "." or sc == "、") then
      return pandoc.Header(3, pandoc.Str(text))
    end
  end

  return nil
end

function Para(el)
  return promote(pandoc.utils.stringify(el))
end

-- Plain handler: 处理列表项等非段落块中的标题模式
function Plain(el)
  return promote(pandoc.utils.stringify(el))
end
