% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/simulate_infections.R
\name{simulate_infections}
\alias{simulate_infections}
\title{Simulate infections using a given trajectory of the time-varying reproduction number}
\usage{
simulate_infections(
  estimates,
  R = NULL,
  model = NULL,
  samples = NULL,
  batch_size = 10,
  verbose = interactive()
)
}
\arguments{
\item{estimates}{The \code{estimates} element of an \code{epinow} run that has been done with
output = "fit", or the result of \code{estimate_infections} with \code{return_fit} set to TRUE.}

\item{R}{A numeric vector of reproduction numbers; these will overwrite the reproduction numbers
contained in \code{estimates}, except elements set to NA. If it is longer than the time series
of reproduction numbers contained in \code{estimates}, the values going beyond the length of
estimated reproduction numbers are taken as forecast.}

\item{model}{A compiled stan model as returned by \code{rstan::stan_model}.}

\item{samples}{Numeric, number of posterior samples to simulate from. The default is to use all
samples in the \code{estimates} input.}

\item{batch_size}{Numeric, defaults to 100. Size of batches in which to simulate. May decrease
run times due to reduced IO costs but this is still being evaluated. If set to NULL then all
simulations are done at once.}

\item{verbose}{Logical defaults to \code{interactive()}. Should a progress bar (from \code{progressr}) be
shown.}
}
\description{
This function simulates infections using an existing fit to observed cases but
with a modified time-varying reproduction number. This can be used to explore forecast models
or past counterfactuals. Simulations can be run in parallel using \code{future::plan}.
}
\examples{
\donttest{
# get example case counts
reported_cases <- EpiNow2::example_confirmed[1:50]

# set up example generation time
generation_time <- get_generation_time(disease = "SARS-CoV-2", source = "ganyani")
# set delays between infection and case report
incubation_period <- get_incubation_period(disease = "SARS-CoV-2", source = "lauer")
reporting_delay <- list(mean = convert_to_logmean(3, 1), mean_sd = 0.1,
                        sd = convert_to_logsd(3, 1), sd_sd = 0.1, max = 15)
                        
# fit model to data to recover Rt estimates
est <- estimate_infections(reported_cases, generation_time = generation_time,
                           delays = list(incubation_period, reporting_delay),
                           rt = list(prior = list(mean = 2, sd = 0.2)),
                           stan_args = list(cores = ifelse(interactive(), 4, 1)))
                                  
# update Rt trajectory and simulate new infections using it
R <- c(rep(NA_real_, 40), rep(0.5, 10), rep(0.8, 7))
sims <- simulate_infections(est, R)
plot(sims)
}
}
