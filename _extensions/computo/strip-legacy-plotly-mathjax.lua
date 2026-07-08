--[[
  HTML only: strip the legacy MathJax 2.x loader that Plotly figures embed
  in their own output (`fig.show()` etc. include a
  `cdnjs.cloudflare.com/.../mathjax/2.x/MathJax.js` script + Hub.Config
  call as a defensive fallback in case no MathJax is already on the page).

  Computo pages always already load MathJax 3 (see mathjax-ams.html) with
  our own macro config (\operatornamewithlimits, \llbracket, ...). When a
  Plotly figure's embedded MathJax 2 loader executes later, it reinitializes
  `window.MathJax` for its own (incompatible) v2 API, discarding our v3
  config - which silently breaks every equation on the page rendered after
  that point (macros become "undefined control sequence").

  Since the page's own MathJax 3 instance can already typeset any math a
  Plotly figure might contain, this legacy loader is always redundant here,
  so we just remove it outright rather than trying to coordinate the two.
]]--

local function strip_legacy_mathjax(html)
  local out, n = html:gsub(
    '<script[^>]*src="[^"]*cdnjs%.cloudflare%.com/ajax/libs/mathjax/2[^"]*"[^>]*></script>',
    ""
  )
  out = out:gsub(
    "<script>if %(window%.MathJax && window%.MathJax%.Hub && window%.MathJax%.Hub%.Config%).-</script>",
    ""
  )
  return out, n
end

return {
  {
    RawBlock = function(el)
      if el.format ~= "html" or not quarto.doc.is_format("html") then
        return nil
      end
      local out, n = strip_legacy_mathjax(el.text)
      if n == 0 then return nil end
      return pandoc.RawBlock("html", out)
    end,
    RawInline = function(el)
      if el.format ~= "html" or not quarto.doc.is_format("html") then
        return nil
      end
      local out, n = strip_legacy_mathjax(el.text)
      if n == 0 then return nil end
      return pandoc.RawInline("html", out)
    end,
  },
}
