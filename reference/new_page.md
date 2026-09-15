# Add page

Module template for golem

## Usage

``` r
new_page(name, path, export, ...)
```

## Arguments

- name:

  The name of the module.

- path:

  The path to the R script where the module will be written. Note that
  this path will not be set by the user but via `add_module()`.

- export:

  Should the module be exported? Default is `FALSE`.

- ...:

  Arguments to be passed to the `module_template` function.

## Value

Used for side effect

## Examples

``` r
if (requireNamespace("golem") & interactive()) {
  golem::add_module(name = "home", module_template = brochure::new_page)
}
```
