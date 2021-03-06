% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/estimate_infections.R
\name{fit_model_with_vb}
\alias{fit_model_with_vb}
\title{Fit a Stan Model using Variational Inference}
\usage{
fit_model_with_vb(args, future = FALSE, id = "stan", verbose = FALSE)
}
\arguments{
\item{args}{List of stan arguments}

\item{future}{Logical, defaults to \code{FALSE}. Should \code{future} be used to run stan chains in parallel.}

\item{id}{A character string used to assign logging information on error. Used by \code{regional_epinow}
to assign errors to regions. Alter the default to run with error catching.}

\item{verbose}{Logical, defaults to \code{FALSE}. Should verbose progress information be returned.}
}
\value{
A stan model object
}
\description{
Fit a Stan Model using Variational Inference
}
