--[[
  Normalize the `status` metadata field (submitted | accepted | published)
  into the derived fields consumed by the PDF and HTML templates: the
  `submitted`, `accepted` and `published` booleans, and `status-watermark`,
  the text stamped on PDF drafts/preprints.
]]--

local VALID_STATUSES = { submitted = true, accepted = true, published = true }

local WATERMARKS = {
  submitted = "submitted",
  accepted = "in press",
}

function normalize_status(meta)
  local status = "submitted"
  if meta.status ~= nil then
    status = pandoc.utils.stringify(meta.status)
  end
  if not VALID_STATUSES[status] then
    status = "submitted"
  end

  meta.status = status
  meta.submitted = (status == "submitted")
  meta.accepted = (status == "accepted")
  meta.published = (status == "published")
  meta["status-watermark"] = WATERMARKS[status]

  return meta
end

return {
  { Meta = normalize_status }
}
