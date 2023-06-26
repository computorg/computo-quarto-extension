if (!file.exists(".Rprofile")) file.copy("_Rprofile",".Rprofile")
tinytex::tlmgr_path("add")