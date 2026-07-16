# Render the HTML lesson for participants.
#
# Facilitators can run this after editing lesson.Rmd. If Pandoc is available,
# rmarkdown will do the rendering. If not, we use commonmark so the workshop
# still has a ready-to-open HTML lesson without requiring Quarto or Pandoc.

if (requireNamespace("rmarkdown", quietly = TRUE) &&
    rmarkdown::pandoc_available("1.12.3")) {
  rmarkdown::render(
    input = "lesson.Rmd",
    output_file = "lesson.html",
    quiet = TRUE
  )
} else {
  if (!requireNamespace("commonmark", quietly = TRUE)) {
    install.packages("commonmark")
  }

  lines <- readLines("lesson.Rmd", warn = FALSE)

  if (length(lines) > 0 && trimws(lines[1]) == "---") {
    yaml_end <- which(trimws(lines[-1]) == "---")[1] + 1
    lines <- lines[(yaml_end + 1):length(lines)]
  }

  lines <- gsub("^```\\{r[^}]*\\}", "```r", lines)
  markdown <- paste(lines, collapse = "\n")
  body <- commonmark::markdown_html(markdown, extensions = TRUE)

  html <- paste0(
    "<!doctype html>\n<html lang=\"en\">\n<head>\n<meta charset=\"utf-8\">\n",
    "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">\n",
    "<title>Mapping Dengue Vector Suitability In Brazil</title>\n",
    "<style>\n",
    "body{margin:0;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',sans-serif;",
    "line-height:1.6;color:#1f2933;background:#f7faf9;}\n",
    "main{max-width:920px;margin:0 auto;padding:40px 24px 72px;background:#fff;}\n",
    "h1{font-size:42px;line-height:1.12;margin:0 0 16px;color:#0b3d3a;}\n",
    "h2{font-size:28px;margin-top:44px;color:#0b3d3a;border-top:1px solid #d8e3df;padding-top:26px;}\n",
    "h3{font-size:21px;margin-top:30px;color:#155e56;}\n",
    "p,li{font-size:17px;}\n",
    "code{background:#eef5f2;border-radius:4px;padding:2px 5px;font-size:0.95em;}\n",
    "pre{background:#10231f;color:#ecfdf5;border-radius:8px;padding:18px;overflow:auto;}\n",
    "pre code{background:transparent;color:inherit;padding:0;}\n",
    "blockquote{border-left:5px solid #f2b84b;margin-left:0;padding-left:18px;color:#374151;}\n",
    "a{color:#0f766e;}\n",
    "ul{padding-left:24px;}\n",
    ".hero{background:#d9f2ea;padding:36px 24px;margin:-40px -24px 32px;border-bottom:5px solid #f2b84b;}\n",
    ".hero p{max-width:760px;font-size:19px;}\n",
    "</style>\n</head>\n<body>\n<main>\n",
    "<section class=\"hero\"><h1>Mapping Dengue Vector Suitability In Brazil</h1>",
    "<p>A beginner-friendly species distribution modeling workshop in R, using ",
    "<em>Aedes aegypti</em>, GBIF occurrence records, WorldClim predictors, and biomod2.</p></section>\n",
    body,
    "\n</main>\n</body>\n</html>\n"
  )

  writeLines(html, "lesson.html")
}
