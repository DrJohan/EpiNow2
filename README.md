
# EpiNow2: Estimate real-time case counts and time-varying epidemiological parameters

[![R-CMD-check](https://github.com/epiforecasts/EpiNow2/workflows/R-CMD-check/badge.svg)](https://github.com/epiforecasts/EpiNow2/actions)
[![Codecov test
coverage](https://codecov.io/gh/epiforecasts/EpiNow2/branch/master/graph/badge.svg)](https://codecov.io/gh/epiforecasts/EpiNow2?branch=master)
[![metacran
downloads](http://cranlogs.r-pkg.org/badges/grand-total/EpiNow2?color=ff69b4)](https://cran.r-project.org/package=EpiNow2)

[![MIT
license](https://img.shields.io/badge/License-MIT-blue.svg)](https://lbesson.mit-license.org/)
[![GitHub
contributors](https://img.shields.io/github/contributors/epiforecasts/EpiNow2)](https://github.com/epiforecasts/EpiNow2/graphs/contributors)
[![PRs
Welcome](https://img.shields.io/badge/PRs-welcome-yellow.svg)](http://makeapullrequest.com)
[![GitHub
commits](https://img.shields.io/github/commits-since/epiforecasts/EpiNow2/v1.2.1.svg?color=orange)](https://GitHub.com/epiforecasts/EpiNow2/commit/master/)
[![DOI](https://zenodo.org/badge/272995211.svg)](https://zenodo.org/badge/latestdoi/272995211)

This package estimates the time-varying reproduction number, rate of
spread, and doubling time using a range of open-source tools ([Abbott et
al.](https://doi.org/10.12688/wellcomeopenres.16006.1)), and current
best practices ([Gostic et
al.](https://doi.org/10.1101/2020.06.18.20134858)). It aims to help
users avoid some of the limitations of naive implementations in a
framework that is informed by community feedback and is under active
development.

It estimates the time-varying reproduction number on cases by date of
infection (using a similar approach to that implemented in
[`{EpiEstim}`](https://github.com/mrc-ide/EpiEstim)). Imputed infections
are then mapped to observed data (for example cases by date of report)
via a series of uncertain delay distributions (in the examples in the
package documentation these are an incubation period and a reporting
delay) and a reporting model that can include weekly periodicity.

Uncertainty is propagated from all inputs into the final parameter
estimates, helping to mitigate spurious findings. This is handled
internally. The time-varying reproduction estimates and the uncertain
generation time also give time-varying estimates of the rate of growth.

The default model uses a non-stationary Gaussian process to estimate the
time-varying reproduction number and then infer infections. Other
options include:

  - A stationary Gaussian process (faster to estimate but currently
    gives reduced performance for real time estimates).
  - User specified breakpoints.
  - A fixed reproduction number.
  - As piecewise constant by combining a fixed reproduction number with
    breakpoints.
  - As a random walk (by combining a fixed reproduction number with
    regularly spaced breakpoints (i.e weekly)).
  - Inferring infections using back-calculation and then calculating the
    time-varying reproduction number.

The documentation for
[`estimate_infections`](https://epiforecasts.io/EpiNow2/reference/estimate_infections.html)
provides examples of the different options available.

Forecasting is also supported for the time-varying reproduction number,
infections and reported cases. The time-varying reproduction number can
be forecast forwards in time using an integration with the
[`{EpiSoon}`](https://epiforecasts.io/EpiSoon/) package, and converted
to a case forecast using the renewal equation. Alternatively, the
time-varying reproduction number and cases can be forecast using a
Gaussian process.

## Installation

Install the stable version of the package:

``` r
install.packages("EpiNow2")
```

Install the stable development version of the package using
[`{drat}`](https://epiforecasts.io/drat/):

``` r
install.packages("drat")
drat:::add("epiforecasts")
install.packages("EpiNow2")
```

Install the unstable development version of the package with:

``` r
remotes::install_github("epiforecasts/EpiNow2")
```

Windows users will need a working installation of Rtools in order to
build the package from source. See
[here](https://github.com/stan-dev/rstan/wiki/RStan-Getting-Started#checking-the-c-toolchain)
for a guide to installing Rtools for use with Stan (which is the
statistical modelling platform used for the underlying model). For
simple deployment/development a prebuilt docker image is also available
(see documentation
[here](https://github.com/epiforecasts/EpiNow2/wiki/Docker)).

## Quick start

`{EpiNow2}` is designed to be used with a single function call or to be
used in an ad-hoc fashion via individual function calls. The core
functions of `{EpiNow2}` are the two single-call functions
[`epinow`](https://epiforecasts.io/EpiNow2/reference/epinow.html),
[`regional_epinow`](https://epiforecasts.io/EpiNow2/reference/regional_epinow.html),
plus functions
[`estimate_infections`](https://epiforecasts.io/EpiNow2/reference/estimate_infections.html),
and
[`forecast_infections`](https://epiforecasts.io/EpiNow2/reference/forecast_infections.html).
In the following section we give an overview of the simple use case for
`epinow` and `regional_epinow`.
[`estimate_infections`](https://epiforecasts.io/EpiNow2/reference/estimate_infections.html)
can be use on its own to infer the underlying infection case curve from
reported cases and estimate Rt. Estimating the underlying infection case
curve via back-calculation (and then calculating Rt) is substantially
less computationally demanding than generating using default settings
but may result in less reliable estimates of Rt. For more details on
using each function see the [function
documentation](https://epiforecasts.io/EpiNow2/reference/index.html).

The first step to using the package is to load it as follows.

``` r
library(EpiNow2)
```

### Reporting delays, incubation period and generation time

Distributions can either be fitted using package functionality or
determined elsewhere and then defined with uncertainty for use in
`{EpiNow2}`. When data is supplied a subsampled bootstrapped lognormal
will be fit (to account for uncertainty in the observed data without
being biased by changes in incidence). An arbitrary number of delay
distributions are supported with the most common use case likely to be a
incubation period followed by a reporting delay.

``` r
reporting_delay <- bootstrapped_dist_fit(rlnorm(1000, log(3), 1), max_value = 15,
                                         bootstraps = 1)
```

Here we define the incubation period and generation time based on
literature estimates for Covid-19 (see
[here](https://github.com/epiforecasts/EpiNow/tree/master/data-raw) for
the code that generates these estimates).

``` r
generation_time <- get_generation_time(disease = "SARS-CoV-2", source = "ganyani")
incubation_period <- get_incubation_period(disease = "SARS-CoV-2", source = "lauer")
```

### [epinow](https://epiforecasts.io/EpiNow2/reference/epinow.html)

This function represents the core functionality of the package and
includes results reporting, plotting and optional saving. It requires a
data frame of cases by date of report and the distributions defined
above. An additional forecasting module is supported via `EpiSoon` and
companion packages (see documentation for an example).

Load example case data from `{EpiNow2}`.

``` r
reported_cases <- example_confirmed[1:90]
head(reported_cases)
#>          date confirm
#> 1: 2020-02-22      14
#> 2: 2020-02-23      62
#> 3: 2020-02-24      53
#> 4: 2020-02-25      97
#> 5: 2020-02-26      93
#> 6: 2020-02-27      78
```

Estimate cases by date of infection, the time-varying reproduction
number, the rate of growth and forecast these estimates into the future
by 7 days. Summarise the posterior and return a summary table and plots
for reporting purposes. If a `target_folder` is supplied results can be
internally saved (with the option to also turn off explicit returning of
results). *Note: For real use cases more samples and a longer warm up
may be needed*. See fitting progress by setting `verbose = TRUE`.

``` r
estimates <- epinow(reported_cases = reported_cases, 
                    generation_time = generation_time,
                    delays = list(incubation_period, reporting_delay),
                    rt = list(prior = list(mean = 2, sd = 0.2)))
names(estimates)
#> [1] "estimates"                "estimated_reported_cases"
#> [3] "summary"                  "plots"                   
#> [5] "timing"
```

Both summary measures and posterior samples are returned for all
parameters in an easily explored format which can be accessed using
`summary`. The default is to return a summary table of estimates for key
parameters at the latest date partially supported by data.

``` r
knitr::kable(summary(estimates))
```

| measure                               | estimate              |
| :------------------------------------ | :-------------------- |
| New confirmed cases by infection date | 470 (243 – 979)       |
| Expected change in daily cases        | Unsure                |
| Effective reproduction no.            | 0.8 (0.6 – 1.2)       |
| Rate of growth                        | \-0.04 (-0.11 – 0.06) |
| Doubling/halving time (days)          | \-16.3 (12.4 – -6.1)  |

Summarised parameter estimates can also easily be returned, either
filtered for a single parameter or for all parameters.

``` r
head(summary(estimates, type = "parameters", params = "R"))
#>          date variable strat     type   median     mean         sd lower_90
#> 1: 2020-02-22        R  <NA> estimate 2.195021 2.200483 0.14374008 1.969388
#> 2: 2020-02-23        R  <NA> estimate 2.169293 2.173288 0.12041395 1.983408
#> 3: 2020-02-24        R  <NA> estimate 2.138305 2.143185 0.10202264 1.984195
#> 4: 2020-02-25        R  <NA> estimate 2.111161 2.109974 0.08807366 1.968147
#> 5: 2020-02-26        R  <NA> estimate 2.075076 2.073684 0.07766037 1.944451
#> 6: 2020-02-27        R  <NA> estimate 2.033070 2.034571 0.06981595 1.920332
#>    lower_50 lower_20 upper_20 upper_50 upper_90
#> 1: 2.099674 2.157409 2.231548 2.297621 2.446492
#> 2: 2.089044 2.134026 2.202135 2.258649 2.372369
#> 3: 2.069457 2.114090 2.169933 2.216259 2.312148
#> 4: 2.045736 2.086382 2.133095 2.172648 2.252204
#> 5: 2.017395 2.053551 2.094023 2.125552 2.203466
#> 6: 1.988095 2.016389 2.051487 2.079475 2.149661
```

Reported cases are returned in a separate data frame in order to
streamline the reporting of forecasts and for model evaluation.

``` r
head(summary(estimates, output = "estimated_reported_cases"))
#>          date  type median    mean       sd lower_90 lower_50 lower_20 upper_20
#> 1: 2020-02-22 gp_rt     57  58.504 14.61683    36.95       48       53       61
#> 2: 2020-02-23 gp_rt     67  69.154 16.66764    45.00       57       63       71
#> 3: 2020-02-24 gp_rt     70  72.269 18.36644    46.00       59       66       75
#> 4: 2020-02-25 gp_rt     71  73.141 18.17392    47.00       60       67       76
#> 5: 2020-02-26 gp_rt     94  95.041 22.66153    61.00       80       89      100
#> 6: 2020-02-27 gp_rt    125 127.979 29.53135    82.00      108      119      133
#>    upper_50 upper_90
#> 1:       68    85.00
#> 2:       80    99.00
#> 3:       83   106.00
#> 4:       84   106.00
#> 5:      109   133.00
#> 6:      146   180.05
```

A range of plots are returned (with the single summary plot shown
below). These plots can also be generated using the following `plot`
method.

``` r
plot(estimates)
```

![](man/figures/unnamed-chunk-13-1.png)<!-- -->

### [regional\_epinow](https://epiforecasts.io/EpiNow2/reference/regional_epinow.html)

The `regional_epinow` function runs the `epinow` function across
multiple regions in an efficient manner.

Define cases in multiple regions delineated by the region variable.

``` r
reported_cases <- data.table::rbindlist(list(
   data.table::copy(reported_cases)[, region := "testland"],
   reported_cases[, region := "realland"]))
head(reported_cases)
#>          date confirm   region
#> 1: 2020-02-22      14 testland
#> 2: 2020-02-23      62 testland
#> 3: 2020-02-24      53 testland
#> 4: 2020-02-25      97 testland
#> 5: 2020-02-26      93 testland
#> 6: 2020-02-27      78 testland
```

Calling `regional_epinow` runs the `epinow` on each region in turn (or
in parallel depending on the settings used).

``` r
estimates <- regional_epinow(reported_cases = reported_cases, 
                             generation_time = generation_time,
                             delays = list(incubation_period, reporting_delay),
                             rt = list(prior = list(mean = 2, sd = 0.2)))
#> INFO [2020-11-08 21:10:44] Producing following optional outputs: regions, summary, samples, plots, latest
#> INFO [2020-11-08 21:10:44] Reporting estimates using data up to: 2020-05-21
#> INFO [2020-11-08 21:10:44] No target directory specified so returning output
#> INFO [2020-11-08 21:10:44] Producing estimates for: testland, realland
#> INFO [2020-11-08 21:10:44] Regions excluded: none
#> INFO [2020-11-08 21:10:44] Showing progress using progressr. Modify this behaviour using progressr::handlers.
#> INFO [2020-11-08 21:21:07] Completed estimates for: testland
#> INFO [2020-11-08 21:31:26] Completed estimates for: realland
#> INFO [2020-11-08 21:31:26] Completed regional estimates
#> INFO [2020-11-08 21:31:26] Regions with estimates: 2
#> INFO [2020-11-08 21:31:26] Regions with runtime errors: 0
#> INFO [2020-11-08 21:31:26] Producing summary
#> INFO [2020-11-08 21:31:26] No summary directory specified so returning summary output
#> INFO [2020-11-08 21:31:26] No target directory specified so returning timings
```

Results from each region are stored in a `regional` list with across
region summary measures and plots stored in a `summary` list. All
results can be set to be internally saved by setting the `target_folder`
and `summary_dir` arguments. Each region can be estimated in parallel
using the `{future}` package (when in most scenarios `cores` should be
set to 1). For routine use each MCMC chain can also be run in parallel
(with `future` = TRUE) with a time out (`max_execution_time`) allowing
for partial results to be returned if a subset of chains is running
longer than expected. See the documentation for the `{future}` package
for details on nested futures.

Summary measures that are returned include a table formatted for
reporting (along with raw results for further processing). Futures
updated will extend the S3 methods used above to smooth access to this
output.

``` r
knitr::kable(estimates$summary$summarised_results$table)
```

| Region   | New confirmed cases by infection date | Expected change in daily cases | Effective reproduction no. | Rate of growth        | Doubling/halving time (days) |
| :------- | :------------------------------------ | :----------------------------- | :------------------------- | :-------------------- | :--------------------------- |
| realland | 474 (239 – 965)                       | Unsure                         | 0.9 (0.6 – 1.2)            | \-0.04 (-0.11 – 0.05) | \-16.7 (14.6 – -6.2)         |
| testland | 471 (249 – 968)                       | Unsure                         | 0.9 (0.6 – 1.2)            | \-0.04 (-0.11 – 0.05) | \-17.1 (13.7 – -6.4)         |

A range of plots are again returned (with the single summary plot shown
below).

``` r
estimates$summary$summary_plot
```

![](man/figures/unnamed-chunk-17-1.png)<!-- -->

### Reporting templates

Rmarkdown templates are provided in the package (`templates`) for
semi-automated reporting of estimates. These are currently undocumented
but an example integration can be seen
[here](https://github.com/epiforecasts/covid/blob/master/_posts/national/united-kingdom/united-kingdom.Rmd).
If using these templates to report your results please highlight our
[limitations](https://doi.org/10.12688/wellcomeopenres.16006.1) as these
are key to understanding the results from `{EpiNow2}` .

## Interactive figures

`{EpiNow2}` is integrated with the `{RtD3}` package which provides
interactive visualisations of Rt estimates. See the package
[documentation](https://epiforecasts.io/RtD3/) for details.

## Contributing

File an issue [here](https://github.com/epiforecasts/EpiNow2/issues) if
you have identified an issue with the package. Please note that due to
operational constraints priority will be given to users informing
government policy or offering methodological insights. We welcome all
contributions, in particular those that improve the approach or the
robustness of the code base.
