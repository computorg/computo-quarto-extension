# Changelog

## v1.0.4

### Bug Fixes

- **HTML figures rendered as invisible/black boxes**: R's Cairo-based `svg()` device (used by default for `fig-format: svg`) emulates semi-transparent layers (e.g. `scale_color_viridis(na.value = NA)`, alpha-blended ribbons) via SVG filter chains (`feImage`/`feColorMatrix` compositing groups) that most browsers fail to render correctly, leaving a solid black rectangle in place of the plot. Switched the HTML knitr device to `svglite`, which supports transparency natively without this filter-based workaround.

---

All notable changes to the Computo Quarto extension, from `v0.2.9` to `v1.0.3`.

## Features

- Canonical link filter: automatically generates the canonical link in published HTML output.
- Manuscript status (`draft`/`submitted`/`accepted`/`published`): new `status` metadata field, with a dedicated HTML banner and a neutral PDF header for drafts; default status changed from "draft" to "submitted".
- DOI shown in the PDF of published articles.
- `shields-encode` shortcode: generates DOI badge URLs (shields.io).
- `author-list` shortcode: auto-generates the author list in the README.
- `cite-as` shortcode: "how to cite" line adapted to the manuscript's status (submitted / accepted "in press" / published with month-year).
- AMS math support enabled for both PDF and HTML.
- Shortcodes made available to all formats, including `gfm-commonmark` (generated README).
- Adaptive PDF title banner: now grows to fit long titles instead of clipping them; author affiliations use numbered superscripts.
- GitHub Actions release workflow: automatically publishes a GitHub Release on every version tag.

## Bug Fixes

- Fixed a `lualatex` crash when a math formula appears in a section title.
- Fixed a title color regression in the branded PDF banner.
- Fixed incorrect spacing and stale links in the HTML title metadata block (several successive fixes).
- Removed the redundant `description` metadata field.
- Fixed a malformed version string (`0.3-3` → `0.3.3`).
- **PDF math fonts**: replaced `libertinust1math` with `unicode-math` + Libertinus Math for correct math rendering under `lualatex`.
- **HTML algorithm rendering**: `pseudocode.js` sniffs `MathJax.version` to pick its math backend, which races MathJax 3's asynchronous startup. Depending on timing this either crashed (`MathJax.version.split is not a function`) and left the algorithm empty, or silently dropped all math inside an otherwise-rendered algorithm. Fixed by having `pseudocode.js` use KaTeX (natively and synchronously supported) instead of relying on the page's MathJax.
- **Missing HTML math macros**: `\operatornamewithlimits`, `\llbracket`/`\rrbracket` (`stmaryrd`) and `\sfrac` (`xfrac`) are not defined by MathJax by default (unlike LaTeX), so they rendered as literal text. All four are now defined as MathJax macros.
- **HTML math clobbered by Plotly figures**: every Plotly figure embeds its own legacy MathJax 2.7.5 loader as a fallback. When it runs on a Computo page (which always already loads MathJax 3 with our macro config), it silently reinitializes `window.MathJax` for its incompatible v2 API, breaking every macro above (and any other math) rendered after that point. The redundant legacy loader is now stripped from Plotly's embedded HTML.
- **PDF tables overflowing the page margin**: results tables with long/technical column names (e.g. from a `pandas` Styler) were rendered as unconstrained-width `longtable` and could overflow into the margin. These are now shrunk to fit via `adjustbox`, but only when actually wider than the text column; narrower tables are left untouched.
  - Follow-up fixes: this initially crashed the PDF build for tables without a crossref id (e.g. a bare `knitr::kable(caption=)`), for tables using pandoc's own wide-table paragraph columns (`p{...}`, already sized to fit by pandoc), and for crossref tables authored as `::: {#tbl-x}` (produced a duplicated/nested `\begin{table}`). All three cases are now handled correctly.

## Build / CI / Environment (housekeeping)

- Migrated environment management to `renv` + `micromamba`/`uv`/`reticulate` for R/Python; updated to Python 3.13, latest R, refreshed `renv.lock`.
- Resolved several C library compatibility breaks (`libraqm`/`freetype`/`harfbuzz`) by updating `plotly`/`kaleido`.
- Added `matplotlib`/`ipython` dependencies, fixed a stale CI cache, lightened the Chrome/Quarto CI install.
- Miscellaneous cleanup of `.gitignore` and CI setup scripts.
