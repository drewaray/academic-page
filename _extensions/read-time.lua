-- Read time calculator for Quarto
-- This filter calculates reading time based on word count and math content

local function count_words(text)
  if not text then return 0 end
  local words = 0
  for word in text:gmatch("%S+") do
    words = words + 1
  end
  return words
end

function Pandoc(doc)
  local total_words = 0
  local inline_math = 0
  local display_math = 0
  local math_elements = 0
  local display_math_blocks = 0

  -- Count words and math content in all blocks
  for _, block in ipairs(doc.blocks) do
    if block.t == "Para" or block.t == "Plain" then
      for _, inline in ipairs(block.content) do
        if inline.t == "Str" then
          total_words = total_words + count_words(inline.text)
        elseif inline.t == "Math" then
          if inline.mathtype == "InlineMath" then
            -- Count inline math elements
            inline_math = inline_math + 1
            total_words = total_words + 10  -- Inline math complexity
          elseif inline.mathtype == "DisplayMath" then
            -- Count display math elements
            display_math = display_math + 1
            total_words = total_words + 25  -- Display math complexity
          end
        elseif inline.t == "Space" or inline.t == "SoftBreak" then
          -- Skip spaces and soft breaks
        end
      end
    elseif block.t == "Header" then
      -- Count words in headers too
      for _, inline in ipairs(block.content) do
        if inline.t == "Str" then
          total_words = total_words + count_words(inline.text)
        elseif inline.t == "Math" then
          if inline.mathtype == "InlineMath" then
            inline_math = inline_math + 1
            total_words = total_words + 10
          elseif inline.mathtype == "DisplayMath" then
            display_math = display_math + 1
            total_words = total_words + 25
          end
        end
      end
    elseif block.t == "Math" then
      -- Fallback for block-level math (though this shouldn't happen in typical Quarto)
      display_math = display_math + 1
      total_words = total_words + 25
    end
  end

  -- Base reading speed: 200 words per minute for regular text
  -- Math content slows reading: inline math = 10 words, display math = 25 words
  local effective_words = total_words

  -- Calculate read time with adjusted speed for math-heavy content
  local base_wpm = 200
  local math_penalty = (inline_math+math_elements) * 0.3 + (display_math+display_math_blocks) * 0.5  -- Reduce WPM for math
  local adjusted_wpm = base_wpm * (1 - math.min(math_penalty, 0.7))  -- Max 70% reduction

  local read_time = math.ceil(effective_words / adjusted_wpm)

  -- Ensure minimum read time of 1 minute
  read_time = math.max(read_time, 1)

  -- Add to document metadata
  doc.meta.read_time = pandoc.MetaString(tostring(read_time) .. " min read")

  -- Optionally add math count for debugging
  -- if math_elements > 0 or display_math_blocks > 0 then
    doc.meta.math_count = pandoc.MetaString(
      tostring(inline_math+math_elements) .. " inline, " ..
      tostring(display_math+display_math_blocks) .. " display"
    )
  -- end

  return doc
end