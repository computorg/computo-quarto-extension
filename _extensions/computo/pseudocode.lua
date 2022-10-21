function CodeBlock(cb)
    if cb.attr.classes[1] == "pseudocode" then
        if quarto.doc.is_format("latex") then
            quarto.doc.use_latex_package("algorithm") 
            quarto.doc.use_latex_package("algpseudocodex")
            return pandoc.RawBlock('tex', cb.text)
        end
        if quarto.doc.is_format("html:js") then
            quarto.doc.addHtmlDependency({
                name = "pseudocode",
                version = "1.0.0",
                scripts = { "pseudocode.min.js" },
                stylesheets = { "pseudocode.min.css" }
            })
            -- generate the initialization script with the correct options
            local scriptTag = [[<script>
for (const element of document.getElementsByClassName("pseudocode")){
    pseudocode.renderElement(element);
}
</script>]]

            -- inject the rendering code
            quarto.doc.include_text("after-body", scriptTag)
        end
    end
end

