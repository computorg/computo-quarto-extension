# Computo Format Template

This is a Quarto template that assists you in creating a manuscript for Computo. You can learn more about ...

## Creating a New Article

You can use this as a template to create an article for an AFT journal. To do this, use the following command:

```bash
quarto use template quarto-journals/article-format-template
```

This will install the extension and create an example qmd file and bibiography that you can use as a starting place for your article.

## Installation For Existing Document

You may also use this format with an existing Quarto project or document. From the quarto project or document directory, run the following command to install this format:

```bash
quarto install extension computorg/computo-quarto-extension
```

## Usage

To use the format, you can use the format names `computo-html`. For example:

```bash
quarto render article.qmd --to computo-html
```

or in your document yaml

```yaml
format:
  computo-html: default
```

You can view a preview of the rendered template at <https://quarto-journals.github.io/article-format-template/>.


Documentation and sample of a [Quarto-based](https://quarto.org) submission for the Computo journal.

Shows how to automatically setup and build the HTML outputs, ready to submit to our peer-review platform.

## Process overview

Submissions to Computo require both scientific content (typically equations, codes and figures) and a proof that this content is reproducible. This is achieved via the standard notebook systems available for R, Python and Julia (Quarto, Jupyter-book and Rmarkdown), coupled with the binder build system. 

A Computo submission is thus a git(hub) repository like this one typically containing 

- the source of the notebook (a markdown file with metadata + a BibTeX + some statics files typically in `figs/`)
- configuration files for the binder environment to build the final notebook files in HTML (`environment.yml`). 

The following picture gives an overview of the process on the author's side:

![Computo author process](https://computo.sfds.asso.fr/assets/img/computo_process_authors.png)

## Step-by-step procedure

### Step 0: setup a github repository

Clone/copy this repo to use it as a starter for your own contributions.

**Note**: _You can rename the .Rmd and .bib files at your convenience, but we suggest you to keep the name of the config files unchanged, unless you know what you are doing._

Typical git manipulations involve the following commands (change `my_github_account` and `my_article_for_computo`): by doing so, you will keep changes from the computo template if need (optional)

``` bash
git clone https://github.com/computorg/template-computo-Rmarkdown.git
git remote rm origin
git remote add origin https://github.com/my_github_account/my_article_for_computo.git
git remote add upstream https://github.com/computorg/template-computo-Rmarkdown
```

### Step 1. write your contribution 

Write your notebook as usual, as demonstrated in the `template-computo-quarto.qmd` sample.

**Note**: _Make sure that you are able to build your manuscript as a regular notebook on your system before proceeding to the next step._

### Step 2: configure your binder environement

The file `environment.yml` tells binder how to setup the machine used to build your notebook with a conda environment. It must be configured to have all the dependencies required to run you notebook (R, Python, packages/feedstocks and system dependencies).

The default uses conda-forge and includes a couple of popular Python and R packages, since quarto supports both 'knitr' and 'jupyter' to coompile your notebook:

``` yaml
name: computorbuild
channels:
  - conda-forge
dependencies:
  - jupyter
  - matplotlib
  - numpy
  - r-base=4.1.1
  - r-knitr
  - r-plotly
  - r-tidyverse
  - r-reticulate
```

The available feedstocks (Python modules and R packages) for conda-forge are listed here: [https://conda-forge.org/feedstock-outputs/index.html](https://conda-forge.org/feedstock-outputs/index.html).


### Step 3: proof reproducibility

It is now time to put everything together and check that your work is indeed reproducible! 

To this end, you need to rely on a github action, whose default is found here: [.github/workflows/build.yml](https://github.com/computorg/template-computo-quarto/blob/main/.github/workflows/build.yml)

This action will

- Check out repository for Github action on a Mac OS machine
- Set up conda with the Python and R dependencies specified in `environment.yml`
- Render your qmd file to HTML
- Deploy your HTML on a github page on the gh-page branch

### Step 4. submit

Once step 3 is successful, you should end up with an HTML version published as a gh-page. A PDF file can be obtained by calling the printing function of your browser (using Chrome should facilitate the rendering). This PDF version can be submitted to the [Computo submission platform](https://computo.scholasticahq.com/):

<div id="scholastica-submission-button" style="margin-top: 10px; margin-bottom: 10px;"><a href="https://computo.scholasticahq.com/for-authors" style="outline: none; border: none;"><img style="outline: none; border: none;" src="https://s3.amazonaws.com/docs.scholastica/law-review-submission-button/submit_via_scholastica.png" alt="Submit to Computo"></a></div>


## Format Options
