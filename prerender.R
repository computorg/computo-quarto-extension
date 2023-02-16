if (!file.exists(".Rprofile")) file.copy("_Rprofile",".Rprofile")
tinytex::tlmgr_install("dvisvgm")
tinytex::tlmgr_add("add")