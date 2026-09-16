# Golem Hook function

Golem Hook function

## Usage

``` r
golem_hook(path, package_name, ...)
```

## Arguments

- path:

  Name of the folder to create the package in. This will also be used as
  the package name.

- package_name:

  Package name to use. By default, `{golem}` uses `basename(path)`. If
  `path == '.'` & `package_name` is not explicitly set, then
  `basename(getwd())` will be used.

- ...:

  Arguments passed from `create_golem()`, unused in the default
  function.

## Value

Used for side effect

## Examples

``` r
if (requireNamespace("golem") & interactive()) {
  golem::create_golem("myapp", project_hook = golem_hook)
}
#> Loading required namespace: golem
```
