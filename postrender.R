condapref <- Sys.getenv("CONDA_PREFIX")
if ((condapref != "")  &
        (Sys.getenv("MAMBA_EXE") != "") &
        file.exists(file.path(condapref,"conda-meta-tmp"))) {
        file.rename(file.path(condapref,"conda-meta-tmp"),file.path(condapref,"conda-meta"))
}