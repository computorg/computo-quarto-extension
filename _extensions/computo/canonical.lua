--[[
  Inject a <link rel="canonical"> tag pointing to the document's hosted
  location on the Computo Journal website, derived from the `repo`
  metadata. Only applies to published documents rendered to HTML.
]]--

function inject_canonical(meta)
  if not quarto.doc.isFormat("html") then return meta end
  if meta.published ~= true then return meta end
  if meta.repo == nil then return meta end

  local repo = pandoc.utils.stringify(meta.repo)
  local url = "https://computo-journal.org/" .. repo .. "/"

  quarto.doc.include_text(
    "in-header",
    '<link rel="canonical" href="' .. url .. '">'
  )

  return meta
end

return {
  { Meta = inject_canonical }
}
