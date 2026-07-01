--[[
  This file defines the shortcodes that your extension will make available
  https://quarto.org/docs/authoring/shortcodes.html#custom-shortcodes
  Quarto exports utils function that can be used in all filters. See
  https://github.com/quarto-dev/quarto-cli/blob/main/src/resources/pandoc/datadir/init.lua#L1522-L1576
]]--

return {

  -- Provides a nicely formatted 'LaTeX' string
  latex = function()
    if quarto.doc.isFormat("pdf") then
      return pandoc.RawBlock('tex', '{\\LaTeX}')
    elseif quarto.doc.isFormat("html") then
      return pandoc.Math('InlineMath', "\\LaTeX")
    else
      return pandoc.Span({pandoc.Str('LaTeX')})
    end
  end,

  -- Generate a Markdown bullet list of all authors with optional URL and affiliations.
  -- Usage: {{< author-list >}}
  ["author-list"] = function(_, _, meta)
    local authors = meta["by-author"]
    if authors == nil then return {} end

    local items = {}
    for _, author in ipairs(authors) do
      local name = pandoc.utils.stringify(author.name and author.name.literal or pandoc.Str(""))
      local url = author.url and pandoc.utils.stringify(author.url) or nil

      local affil_parts = {}
      if author.affiliations then
        for _, affil in ipairs(author.affiliations) do
          local affil_name = affil.name and pandoc.utils.stringify(affil.name) or nil
          if affil_name and affil_name ~= "" then
            table.insert(affil_parts, affil_name)
          end
        end
      end

      local inlines = {}
      if url and url ~= "" then
        table.insert(inlines, pandoc.Link({pandoc.Str(name)}, url))
      else
        table.insert(inlines, pandoc.Str(name))
      end
      if #affil_parts > 0 then
        table.insert(inlines, pandoc.Str(" (" .. table.concat(affil_parts, ", ") .. ")"))
      end

      table.insert(items, {pandoc.Plain(inlines)})
    end

    return pandoc.BulletList(items)
  end,

  -- Encode a metadata value for use in a shields.io badge URL.
  -- shields.io uses '-' as a label/message/color separator, so literal dashes
  -- must be doubled ('--') and slashes must be percent-encoded ('%2F').
  -- Usage: {{< shields-encode citation.doi >}}
  ["shields-encode"] = function(args, _, meta)
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
  end,

}
