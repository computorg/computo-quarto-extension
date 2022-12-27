local default_color_code = '034E79'
local default_color_stdout = '797903'
local default_color_stderr = '790303'

local function color_fun(c, default)
    local x = pandoc.utils.stringify(c)
    if string.sub(x, 1, 1) == '#' then
        return string.sub(x, 2)
    end
    if x == 'true' then
        return default
    end
    error("Invalid color: "..x)
end


local injected_colors = false
local function inject_colors_latex()
    if not injected_colors then
        quarto.doc.include_text("before-body", "\\definecolor{code-block-code}{HTML}{"..default_color_code.."}")
        quarto.doc.include_text("before-body", "\\definecolor{code-block-stdout}{HTML}{"..default_color_stdout.."}")
        quarto.doc.include_text("before-body", "\\definecolor{code-block-stderr}{HTML}{"..default_color_stderr.."}")
        quarto.doc.include_text("before-body", "\\colorlet{shadecolor}{code-block-code!30!white}")
        quarto.doc.include_text("before-body", "\\def\\shadecolor{\\color{shadecolor}}")
        quarto.doc.include_text("before-body", "\\colorlet{code-block-stdout-light}{code-block-stdout!40!white}")
        quarto.doc.include_text("before-body", "\\colorlet{code-block-stderr-light}{code-block-stderr!40!white}")
        injected_colors = true
    end
end

function Meta(meta)
  for k, v in pairs(meta) do
        if k == 'code-block-codecolor' then
            default_color_code = color_fun(v, default_color_code)
        end
        if k == 'code-block-stdoutcolor' then
            default_color_stdout = color_fun(v, default_color_stdout)
        end
        if k == 'code-block-stderrcolor' then
            default_color_stderr = color_fun(v, default_color_stderr)
        end
    end
    if quarto.doc.is_format("latex") then
        inject_colors_latex()
    end
end

function Div(div)
    if quarto.doc.is_format("latex") then
        if div.classes:includes('cell-output-stdout') or div.classes:includes('cell-output-display') then
            local content = div.content
            local change = false
            for i,el in pairs(content) do
                if el.t == "CodeBlock" then
                    change = true
                end
            end
            if change then
                table.insert(content,1, pandoc.RawInline('latex', '\\begin{tcolorbox}[boxrule=0pt, enhanced, borderline west={2pt}{0pt}{code-block-stdout-light}, interior hidden, frame hidden, breakable, sharp corners, grow to left by=-1em]'))
                table.insert(content, pandoc.RawInline('latex','\\end{tcolorbox}'))
            end
            return content
        end
        if div.classes:includes('cell-output-stderr') then
            local content = div.content
            table.insert(content,1, pandoc.RawInline('latex', '\\begin{tcolorbox}[boxrule=0pt, enhanced, borderline west={2pt}{0pt}{code-block-stderr-light}, interior hidden, frame hidden, breakable, sharp corners, grow to left by=-1em]'))
            table.insert(content, pandoc.RawInline('latex','\\end{tcolorbox}'))
            return content
        end
    end
end
