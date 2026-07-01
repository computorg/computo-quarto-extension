--[[
  This file defines the shortcodes that your extension will make available
  https://quarto.org/docs/authoring/shortcodes.html#custom-shortcodes
  Quarto exports utils function that can be used in all filters. See
  https://github.com/quarto-dev/quarto-cli/blob/main/src/resources/pandoc/datadir/init.lua#L1522-L1576
]]--

-- Example shortcode that provides a nicely formatted 'LaTeX' string
function latex()
  if quarto.doc.isFormat("pdf") then
    return pandoc.RawBlock('tex', '{\\LaTeX}')
  elseif quarto.doc.isFormat("html") then
    return pandoc.Math('InlineMath', "\\LaTeX")
  else
    return pandoc.Span('LaTeX')
  end
end

-- Encode a metadata value for use in a shields.io badge URL.
-- shields.io uses '-' as a label/message/color separator, so literal dashes
-- must be doubled ('--') and slashes must be percent-encoded ('%2F').
-- Usage: {{< shields-encode citation.doi >}}
function shields_encode(args, _, meta)
  local key = pandoc.utils.stringify(args[1])
  local value = meta
  for part in key:gmatch("[^.]+") do
    if type(value) ~= "table" then return pandoc.Str("") end
    value = value[part]
  end
  if value == nil then return pandoc.Str("") end
  local str = pandoc.utils.stringify(value)
  str = str:gsub("%-", "--")
  str = str:gsub("/", "%%2F")
  return pandoc.Str(str)
end
