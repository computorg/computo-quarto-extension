--[[
  PDF only: shrink-to-fit tables whose natural width would overflow the
  text width (e.g. results tables with long/technical column names).

  Pandoc always renders `Table` elements as `longtable`, but `longtable`
  cannot be wrapped in `\resizebox`/`adjustbox` (it does its own multi-pass,
  page-breaking layout, which is incompatible with box-measuring macros).
  So for tables that are unlikely to need page-breaking (heuristically:
  not too many rows) we instead render them as a plain `tabular` inside a
  `table` float, wrapped in `adjustbox{max width=\linewidth}`. This only
  scales tables down when they are actually wider than the text column;
  narrower tables are left at their natural size.
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

local function longtable_to_tabular(tex)
  local _, colspec_end, colspec =
    tex:find("\\begin{longtable}%[%]{(.-)}")
  if not colspec then return nil end

  -- Quarto's crossref filter already wraps a captioned/labelled table in
  -- its own `table` float (with `\caption`/`\label`) around whatever block
  -- we return, so we must NOT add another float or caption here - just the
  -- resizable `tabular`, or the caption/float ends up duplicated.
  local body = tex:sub(colspec_end + 1)
  body = body:gsub("\\caption{.-}\\label{[^}]-}\\tabularnewline", "", 1)
  body = body:gsub("\\caption{}\\label{[^}]-}\\tabularnewline", "", 1)
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

  local out = {}
  table.insert(out, "\\begin{adjustbox}{max width=\\linewidth}")
  table.insert(out, "\\begin{tabular}{" .. colspec .. "}")
  table.insert(out, body)
  table.insert(out, "\\end{adjustbox}")
  return table.concat(out, "\n")
end

function Table(tbl)
  if not (quarto and quarto.doc and quarto.doc.is_format("pdf")) then
    return nil
  end
  if count_rows(tbl) > MAX_ROWS_TO_CONVERT then
    return nil
  end

  local rendered = pandoc.write(pandoc.Pandoc({ tbl }), "latex")
  local converted = longtable_to_tabular(rendered)
  if not converted then
    return nil
  end
  return pandoc.RawBlock("latex", converted)
end
