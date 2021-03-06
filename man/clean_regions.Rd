% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/regional_epinow.R
\name{clean_regions}
\alias{clean_regions}
\title{Clean Regions}
\usage{
clean_regions(reported_cases, non_zero_points)
}
\arguments{
\item{reported_cases}{A data frame of confirmed cases (confirm) by date (date), and region (\code{region}).}

\item{non_zero_points}{Numeric, the minimum number of time points with non-zero cases in a region required for
that region to be evaluated. Defaults to 2.}
}
\value{
A dataframe of cleaned regional data
}
\description{
Clean Regions
}
