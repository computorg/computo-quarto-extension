--[[
  Normalize the `status` metadata field (draft | accepted | published) into
  the derived fields consumed by the PDF and HTML templates: `draft` and
  `published` booleans (kept for templates/filters written before `status`
  existed), and `status-watermark`, the text stamped on PDF drafts/preprints.
]]--

local VALID_STATUSES = { draft = true, accepted = true, published = true }

local WATERMARKS = {
  draft = "submitted",
  accepted = "in press",
}

function normalize_status(meta)
  local status = "draft"
  if meta.status ~= nil then
    status = pandoc.utils.stringify(meta.status)
  end
  if not VALID_STATUSES[status] then
    status = "draft"
  end

  meta.status = status
  meta.draft = (status == "draft")
  meta.published = (status == "published")
  meta["status-watermark"] = WATERMARKS[status]

  return meta
end

return {
  { Meta = normalize_status }
}
