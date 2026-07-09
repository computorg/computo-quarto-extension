# Not sourced by anything: this file exists purely so that `renv`'s static
# dependency scanner (`renv::dependencies()`, used by `renv::snapshot()`)
# picks up packages this extension's Quarto/knitr configuration requires at
# render time, but never references via actual R code that renv can see.
#
# svglite: set as the HTML `knitr` chunk device (`dev: svglite`) in
# _extension.yml to render R plots with native SVG transparency support.
# That's a plain YAML string, not an R call, so renv has no way to detect it
# from the YAML alone - without this explicit reference, an author's
# `renv::snapshot()` silently omits svglite, and their `renv.lock` restores
# fine but fails at render time as soon as a plot needs to be drawn.
library(svglite)
