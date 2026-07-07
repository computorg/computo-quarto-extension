--[[
  This file defines the shortcodes that your extension will make available
  https://quarto.org/docs/authoring/shortcodes.html#custom-shortcodes
  Quarto exports utils function that can be used in all filters. See
  https://github.com/quarto-dev/quarto-cli/blob/main/src/resources/pandoc/datadir/init.lua#L1522-L1576
]]--

local MONTH_NAMES = {
  "January", "February", "March", "April", "May", "June",
  "July", "August", "September", "October", "November", "December",
}

-- Render a date string as "Month Year" when it can be parsed as an ISO
-- (YYYY-MM-DD or YYYY-MM) date, falling back to the bare year, then to the
-- raw string if no year can be found.
local function month_year(date_str)
  if not date_str or date_str == "" then return "" end
  local y, m = date_str:match("^(%d%d%d%d)%-(%d%d)")
  if y and m then
    return MONTH_NAMES[tonumber(m)] .. " " .. y
  end
  return date_str:match("%d%d%d%d") or date_str
end

-- Build the "Author1, Author2 and Author3" string used in citations.
local function author_names(meta)
  local authors = meta["by-author"]
  if not authors then return "" end

  local names = {}
  for _, author in ipairs(authors) do
    table.insert(names, pandoc.utils.stringify(author.name and author.name.literal or pandoc.Str("")))
  end

  if #names == 0 then return "" end
  if #names == 1 then return names[1] end
  return table.concat(names, ", ", 1, #names - 1) .. " and " .. names[#names]
end

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

  -- Generate a "how to cite" line that adapts to the manuscript's status:
  -- submitted papers get a plain "Submitted to Computo." notice; accepted
  -- papers get a full citation stamped "in press"; published papers get a
  -- full citation with the month and year of publication.
  -- Usage: {{< cite-as >}}
  ["cite-as"] = function(_, _, meta)
    local status = meta.status and pandoc.utils.stringify(meta.status) or "submitted"

    if status == "submitted" then
      return pandoc.Para({pandoc.Str("Submitted to Computo.")})
    end

    local date_part = "in press"
    if status == "published" then
      date_part = month_year(meta.date and pandoc.utils.stringify(meta.date) or "")
    end

    local title = meta.title and pandoc.utils.stringify(meta.title) or ""
    local container = meta.citation and meta.citation["container-title"]
      and pandoc.utils.stringify(meta.citation["container-title"]) or ""
    local doi = meta.citation and meta.citation.doi and pandoc.utils.stringify(meta.citation.doi) or nil

    local text = author_names(meta) .. " (" .. date_part .. "). " .. title .. "."
    if container ~= "" then text = text .. " " .. container .. "." end

    local inlines = {pandoc.Str(text)}
    if doi then
      table.insert(inlines, pandoc.Space())
      table.insert(inlines, pandoc.Link({pandoc.Str("https://doi.org/" .. doi)}, "https://doi.org/" .. doi))
    end
    return pandoc.Para(inlines)
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
