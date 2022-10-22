setHook(packageEvent("plotly","onLoad"), function (...) webshot::install_phantomjs())

# https://github.com/rstudio/reticulate/issues/1184#issuecomment-1113450617

reticulateLoad <- function(...) {
        condapref <- Sys.getenv("CONDA_PREFIX")
        if ((condapref != "") &
                (Sys.getenv("MAMBA_EXE") != "") &
                file.exists(file.path(condapref,"conda-meta"))) {
                file.rename(file.path(condapref,"conda-meta"),file.path(condapref,"conda-meta-tmp"))
                reticulate_micromamba_hack <<- TRUE
        }
        pio <- reticulate::import("plotly.io")
        pio$renderers$default <- "browser+pdf"
}

setHook(packageEvent("reticulate","onLoad"), reticulateLoad)
