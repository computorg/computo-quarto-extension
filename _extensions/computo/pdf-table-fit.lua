--[[
  PDF only: shrink-to-fit tables whose natural width would overflow the
  text width (e.g. results tables with long/technical column names).

  Pandoc always renders `Table` elements as `longtable`, but `longtable`
  cannot be wrapped in `\resizebox`/`adjustbox` (it does its own multi-pass,
  page-breaking layout, which is incompatible with box-measuring macros).
  So for tables that are unlikely to need page-breaking (heuristically:
  not too many rows) we instead render them as a plain `tabular`, wrapped in
  `adjustbox{max width=\linewidth}`. This only scales tables down when they
  are actually wider than the text column; narrower tables are left at
  their natural size.

  Any table with a crossref id (`#| label: tbl-x`, or `::: {#tbl-x}`) is
  wrapped by Quarto in a `FloatRefTarget` custom AST node - regardless of
  authoring syntax, its inner `Table` node itself never carries the id or
  caption (those live on the FloatRefTarget) at the point *any* Lua filter
  sees it, since Quarto resolves crossref numbering/captioning later. So we
  must not add our own `table`/`caption` wrapper around such tables -
  Quarto already supplies one around whatever content we return - or the
  float/caption ends up duplicated (nested `\begin{table}` or, worse, a
  `\caption` stranded outside any float).

  A table with no id at all (e.g. a bare `knitr::kable(..., caption = )`)
  is never wrapped in a FloatRefTarget, so it gets no external wrapper: we
  must supply our own there, using the caption pandoc embedded directly in
  the longtable, or it would be silently dropped.
]]--

-- Tables with more rows than this are left as `longtable`: converting them
-- would drop automatic page-breaking, and very tall tables are unlikely to
-- be the "wide header" case this filter targets.
local MAX_ROWS_TO_CONVERT = 40

local function count_rows(tbl)
  local n = #tbl.head.rows
  for _, body in ipairs(tbl.bodies) do
    n = n + #body.head + #body.body
  end
  n = n + #tbl.foot.rows
  return n
end

-- Find the index of the `}` matching the `{` at position `open_idx` in
-- `s`, accounting for nested braces (pandoc's column specs can contain
-- braces of their own, e.g. `\real{0.2048}`).
local function find_matching_brace(s, open_idx)
  local depth = 0
  for i = open_idx, #s do
    local c = s:sub(i, i)
    if c == "{" then
      depth = depth + 1
    elseif c == "}" then
      depth = depth - 1
      if depth == 0 then return i end
    end
  end
  return nil
end

local function longtable_to_tabular(tex, has_wrapper)
  local _, header_end = tex:find("\\begin{longtable}%[%]{")
  if not header_end then return nil end
  -- `header_end` is the index of the colspec's opening `{` itself (part of
  -- the matched pattern above), so the colspec body starts right after it.
  local colspec_end = find_matching_brace(tex, header_end)
  if not colspec_end then return nil end
  local colspec = tex:sub(header_end + 1, colspec_end - 1)

  -- Pandoc gives wide tables (many/long columns) paragraph-mode `p{...}`
  -- columns with widths it already computed to sum to `\linewidth`, i.e.
  -- these are already guaranteed to fit and don't need shrinking. They
  -- must also be left alone rather than "fixed": `adjustbox`/`resizebox`
  -- box-capturing is incompatible with paragraph-building column content
  -- (`p{}`/minipage cells), and wrapping one reliably breaks the build
  -- ("Paragraph ended before \@@array was complete").
  if colspec:find("p{", 1, true) then
    return nil
  end

  -- A Table with no caption of its own (e.g. one whose caption now lives
  -- on an enclosing FloatRefTarget instead) is wrapped by pandoc in
  -- `{\def\LTcaptype{none} ... \begin{longtable}...\end{longtable}\n}` to
  -- suppress the table counter. We discard that opening brace/def along
  -- with everything else before `\begin{longtable}`, so its matching
  -- closing brace (right after `\end{longtable}`) must be dropped too, or
  -- it prematurely closes our own `\end{adjustbox}`/`\end{table}` group.
  local has_nocaption_wrapper = tex:find("^%s*{\\def\\LTcaptype{none}") ~= nil

  local body = tex:sub(colspec_end + 1)
  local caption = nil
  local cap_s, _, cap_text = body:find("\\caption{(.-)}\\label{[^}]-}\\tabularnewline")
  if not cap_s then
    cap_s, _, cap_text = body:find("\\caption{(.-)}\\tabularnewline")
  end
  if cap_s and cap_text ~= "" then
    caption = cap_text
  end
  body = body:gsub("\\caption{.-}\\label{[^}]-}\\tabularnewline", "", 1)
  body = body:gsub("\\caption{}\\label{[^}]-}\\tabularnewline", "", 1)
  body = body:gsub("\\caption{.-}\\tabularnewline", "", 1)
  body = body:gsub("\\tabularnewline%s*", "", 1)

  -- Drop the repeated header block plus longtable's page-break plumbing.
  -- Pandoc emits `\endfirsthead` + a repeated header only when it thinks
  -- the table might span pages; short tables go straight from the (single)
  -- header to `\endhead`. Either way, keep the first header and discard
  -- everything from the first of those two markers through `\endlastfoot`.
  if body:find("\\endfirsthead", 1, true) then
    body = body:gsub("\\endfirsthead.-\\endlastfoot", "")
  else
    body = body:gsub("\\endhead.-\\endlastfoot", "")
  end

  body = body:gsub("\\end{longtable}", "\\bottomrule\\noalign{}\n\\end{tabular}")
  if has_nocaption_wrapper then
    -- Drop the one trailing `}` (with surrounding whitespace) that closes
    -- the `{\def\LTcaptype{none}...` group we discarded above.
    body = body:gsub("%s*}%s*$", "")
  end

  local out = {}
  if not has_wrapper then
    table.insert(out, "\\begin{table}")
    table.insert(out, "\\centering")
    if caption then
      table.insert(out, "\\caption{" .. caption .. "}")
    end
  end
  table.insert(out, "\\begin{adjustbox}{max width=\\linewidth}")
  table.insert(out, "\\begin{tabular}{" .. colspec .. "}")
  table.insert(out, body)
  table.insert(out, "\\end{adjustbox}")
  if not has_wrapper then
    table.insert(out, "\\end{table}")
  end
  return table.concat(out, "\n")
end

-- Converts a `Table` node to our shrink-to-fit RawBlock. `has_wrapper`
-- tells us whether an external float (Quarto's FloatRefTarget rendering)
-- will supply the `table`/`caption` wrapper, or whether we must.
local function convert_table(tbl, has_wrapper)
  if count_rows(tbl) > MAX_ROWS_TO_CONVERT then
    return nil
  end
  local rendered = pandoc.write(pandoc.Pandoc({ tbl }), "latex")
  local converted = longtable_to_tabular(rendered, has_wrapper)
  if not converted then
    return nil
  end
  return pandoc.RawBlock("latex", converted)
end

-- Find a Table node directly inside a block, or one level down inside a Div
-- (e.g. R/knitr chunk output wraps its table in a Div).
local function find_table(block)
  if block.t == "Table" then
    return block
  elseif block.t == "Div" then
    for _, b in ipairs(block.content) do
      if b.t == "Table" then
        return b
      end
    end
  end
  return nil
end

local function is_pdf()
  return quarto and quarto.doc and quarto.doc.is_format("pdf")
end

-- Crossref-managed tables: Quarto wraps them in a `FloatRefTarget` custom
-- node (regardless of `#| label:` vs `::: {#tbl-x}` authoring syntax) and
-- supplies the `table`/`caption` wrapper itself once it resolves
-- numbering, so we only replace the inner table's markup here. This must
-- run as its own top-level filter (not a nested `doc:walk` call from
-- within a `Pandoc` function) for Quarto's custom AST node types to be
-- walked at all.
local function convert_float_table(float)
  if not is_pdf() or float.type ~= "Table" or not float.content then
    return float
  end
  local content = float.content
  local block = content.t and content or content[1]
  local tbl = find_table(block)
  if not tbl then
    return float
  end
  local converted = convert_table(tbl, true)
  if not converted then
    return float
  end
  float.content = pandoc.Blocks({ converted })
  return float
end

-- Any other (non-crossref, e.g. bare `knitr::kable(..., caption=)`) table
-- is never wrapped in a FloatRefTarget, so we must supply our own wrapper
-- for its caption, or it would be silently dropped. Tables inside a
-- FloatRefTarget are handled (and already converted to RawBlock) by the
-- pass above, which runs first, so this only ever sees real plain Tables.
local function convert_plain_table(tbl)
  if not is_pdf() then
    return nil
  end
  return convert_table(tbl, false)
end

return {
  { FloatRefTarget = convert_float_table },
  { Table = convert_plain_table },
}
