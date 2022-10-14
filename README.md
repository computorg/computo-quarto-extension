# Use of the Computo Format Template

This is a [Quarto-based](https://quarto.org) that assists you in creating a manuscript for Computo.

## Creating a New Article

You can use this as a template to create an article for an AFT journal. To do this, use the following command:

```bash
quarto use template computorg/computo-quarto-extension
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

You can view a preview of the rendered template at <https://computorg.github.io/computo-quarto-extension/>.


