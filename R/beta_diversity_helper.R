#' A function to facilitate viewing and manipulating beta diversity estimates
#' 
#' @param dv The output of a DivNet() call
#' @param physeq The phyloseq object containing the sample data and  abundance table
#' @param measure The beta diversityindex of interest
#' @param x The covariate 
#' 
#' @importFrom phyloseq sample_data get_variable
#' @importFrom tibble rownames_to_column add_column
#' @importFrom tidyr gather
#' @importFrom dplyr select distinct mutate
#' 
#' @return A data frame with the ecosystems, beta diversity estimates, and CIs
#' 
#' @export
simplifyBeta <- function(dv, 
                         physeq, 
                         measure,
                         x) {
  
  beta_var_matrix <- dv[[paste(measure, "-variance", sep = "")]]
  
  vars <- physeq %>% sample_data %>% get_variable(x) 
  names(vars) <- physeq %>% sample_names
  
  dv[[measure]] %>%
    data.frame(check.names=FALSE) %>%
    rownames_to_column("Sample1") %>%
    gather("Sample2", "beta_est", names(vars)) %>%
    add_column("beta_var" = beta_var_matrix %>%
                 data.frame(check.names=FALSE) %>%
                 rownames_to_column("Sample1") %>%
                 gather("Sample2", "var", names(vars)) %>%
                 select("var") %>% c %>% unlist) %>%
    mutate("Covar1" = vars[Sample1],
           "Covar2" = vars[Sample2]) %>%
    select(Covar1, Covar2, beta_est, beta_var) %>% 
    dplyr::filter(beta_est > 1e-16) %>%
    unique %>%
    distinct(beta_est, .keep_all = TRUE) %>%
    mutate("lower" = pmax(0, beta_est - 2*sqrt(beta_var)), 
           "upper" = pmax(0, beta_est + 2*sqrt(beta_var))) 
}
