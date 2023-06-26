local function ensure_html_deps()
  quarto.doc.addHtmlDependency({
    name = "pseudocode",
    version = "2.4",
    scripts = { "pseudocode.min.js" },
    stylesheets = { "pseudocode.min.css" }
  })
  -- generate the initialization script with the correct options
  local scriptTag = [[<script>
(function(d) {
  d.querySelectorAll(".pseudocode-container").forEach(function(el) {
    let pseudocodeOptions = {
      indentSize: el.dataset.indentSize || "1.2em",
      commentDelimiter: el.dataset.commentDelimiter || "//",
      lineNumber: el.dataset.lineNumber === "true" ? true : false,
      lineNumberPunc: el.dataset.lineNumberPunc || ":",
      noEnd: el.dataset.noEnd === "true" ? true : false,
      titlePrefix: el.dataset.algTitle || "Algorithm"
    };
    pseudocode.renderElement(el.querySelector(".pseudocode"), pseudocodeOptions);
  });
})(document);
(function(d) {
  d.querySelectorAll(".pseudocode-container").forEach(function(el) {
    titleSpan = el.querySelector(".ps-root > .ps-algorithm > .ps-line > .ps-keyword")
    titlePrefix = el.dataset.algTitle;
    titleIndex = el.dataset.chapterLevel ? el.dataset.chapterLevel + "." + el.dataset.pseudocodeIndex : el.dataset.pseudocodeIndex;
    titleSpan.innerHTML = titlePrefix + " " + titleIndex + " ";
  });
})(document);
</script>]]

  -- inject the rendering code
  quarto.doc.include_text("after-body", scriptTag)
end

local function ensure_latex_deps()
  quarto.doc.use_latex_package("algorithm")
  quarto.doc.use_latex_package("algpseudocode")
end

local function extract_source_code_options(source_code, option_type)
  local options = {}
  local source_codes = {}
  local found_source_code = false

  for str in string.gmatch(source_code, "([^\n]*)\n?") do
    if (string.match(str, "^%s*#|.*") or string.gsub(str, "%s", "") == "") and not found_source_code then
      if string.match(str, "^%s*#|%s+[" .. option_type .. "|label].*") then
        str = string.gsub(str, "^%s*#|%s+", "")
        local idx_start, idx_end = string.find(str, ":%s*")

        if idx_start and idx_end and idx_end + 1 < #str then
          k = string.sub(str, 1, idx_start - 1)
          v = string.sub(str, idx_end + 1)
          v = string.gsub(v, "^\"%s*", "")
          v = string.gsub(v, "%s*\"$", "")

          options[k] = v
        else
          quarto.log.warning("Invalid pseducode option: " .. str)
        end
      end
    else
      found_source_code = true
      table.insert(source_codes, str)
    end
  end

  return options, table.concat(source_codes, "\n")
end

local function render_pseudocode_block_html(el, alg_title, chapter_level, pseudocode_index)
  ensure_html_deps()

  local options, source_code = extract_source_code_options(el.text, "html")

  source_code = string.gsub(source_code, "%s*\\begin{algorithm}[^\n]+", "\\begin{algorithm}")
  source_code = string.gsub(source_code, "%s*\\begin{algorithmic}[^\n]+", "\\begin{algorithmic}")

  local alg_id = options["label"]
  options["label"] = nil
  options["html-alg-title"] = alg_title
  options["html-pseudocode-index"] = pseudocode_index

  if chapter_level then
    options["html-chapter-level"] = chapter_level
  end

  local data_options = {}
  for k, v in pairs(options) do
    if string.match(k, "^html-") then
      data_k = string.gsub(k, "^html", "data")
      data_options[data_k] = v
    end
  end

  local inner_el = pandoc.Div(source_code)
  inner_el.attr.classes = pandoc.List()
  inner_el.attr.classes:insert("pseudocode")

  local outer_el = pandoc.Div(inner_el)
  outer_el.attr.classes = pandoc.List()
  outer_el.attr.classes:insert("pseudocode-container")
  outer_el.attr.attributes = data_options

  if alg_id then
    outer_el.attr.identifier = alg_id
  end

  return outer_el
end

local function render_pseudocode_block_latex(el, alg_title)
  ensure_latex_deps()
  quarto.doc.include_text("before-body", "\\floatname{algorithm}{" .. alg_title .. "}")

  local options, source_code = extract_source_code_options(el.text, "pdf")

  if options["pdf-placement"] then
    source_code = string.gsub(source_code, "\\begin{algorithm}%s*\n", "\\begin{algorithm}[" .. options["pdf-placement"] .. "]\n")
  end

  if not options["pdf-line-number"] or options["pdf-line-number"] == "true" then
    source_code = string.gsub(source_code, "\\begin{algorithmic}%s*\n", "\\begin{algorithmic}[1]\n")
  end

  if options["label"] then
    source_code = string.gsub(source_code, "\\begin{algorithmic}", "\\label{" .. options["label"] .. "}\n\\begin{algorithmic}")
  end

  el = pandoc.RawInline("latex", source_code)

  return el
end

local function render_pseudocode_block(el, alg_title, chapter_level, pseudocode_index)
  if quarto.doc.is_format("html") then
    el = render_pseudocode_block_html(el, alg_title, chapter_level, pseudocode_index)
  elseif quarto.doc.is_format("latex") then
    el = render_pseudocode_block_latex(el, alg_title)
  end

  return el
end

local function render_pseudocode_ref_html(doc, alg_prefix, chapater_level)
  local pseudocodes = {}

  for _, el in pairs(doc.blocks) do
    if el.t == "Div" and el.attr and el.attr.classes:includes("pseudocode-container") then
      pseudocodes[el.identifier] = {
        alg_prefix = el.attr.attributes["data-alg-prefix"] or alg_prefix,
        chapater_level = chapater_level,
        pseudocode_index = el.attr.attributes["data-pseudocode-index"]
      }
    end
  end

  local filter = {
    Cite = function(el)
      local cite_text = pandoc.utils.stringify(el.content)
      for k, v in pairs(pseudocodes) do
        if cite_text == "@" .. k then
          local link_src = "#" .. k
          local alg_id = v["pseudocode_index"]

          if v["chapater_level"] then
            alg_id = v["chapater_level"] .. "." .. alg_id
          end

          local link_text = v["alg_prefix"] .. " " .. alg_id
          return pandoc.Link(link_text, link_src)
        end
      end
    end
  }

  return filter
end

local function render_pseudocode_ref_latex(alg_prefix)
  local filter = {
    Cite = function(el)
      local cite_text = pandoc.utils.stringify(el.content)

      if string.match(cite_text, "^@alg-") then
        return pandoc.RawInline("latex", " " .. alg_prefix .. "~\\ref{" .. string.gsub(cite_text, "^@", "") .. "} " )
      end
    end
  }

  return filter
end

local function render_pseudocode_ref(doc, alg_prefix, chapater_level)
  local filter = {
    Cite = function(el)
      return el
    end
  }

  if quarto.doc.is_format("html") then
    filter = render_pseudocode_ref_html(doc, alg_prefix, chapater_level)
  elseif quarto.doc.is_format("latex") then
    filter = render_pseudocode_ref_latex(alg_prefix)
  end

  return filter
end

function Pandoc(doc)
  local alg_title = "Algorithm"
  local alg_prefix = "Algorithm"
  local pseudocode_index = 1
  local chapater_level = nil

  if doc.meta["pseudocode"] then
    alg_title = pandoc.utils.stringify(doc.meta["pseudocode"]["alg-title"]) or "Algorithm"
    alg_prefix = pandoc.utils.stringify(doc.meta["pseudocode"]["alg-prefix"]) or "Algorithm"
  end

  -- get current chapter level
  if doc.meta["book"] then
    local _, input_qmd_filename = string.match(quarto.doc["input_file"], "^(.-)([^\\/]-%.([^\\/%.]-))$")
    local renders = doc.meta["book"]["render"]

    for _, render in pairs(renders) do
      if render["file"] and render["number"] and pandoc.utils.stringify(render["file"]) == input_qmd_filename then
        chapater_level = pandoc.utils.stringify(render["number"])
      end
    end
  end

  -- render pseudocode blocks
  for idx, el in pairs(doc.blocks) do
    if el.t == "CodeBlock" and el.attr and el.attr.classes:includes("pseudocode") then
      doc.blocks[idx] = render_pseudocode_block(el, alg_title, chapater_level, pseudocode_index)
      pseudocode_index = pseudocode_index + 1
    end
  end

  -- render pseudocode references
  return doc:walk(render_pseudocode_ref(doc, alg_prefix, chapater_level))
end
