
simudata_lmm2 <- function (params=list()) {
    # Note: this function is modified from https://gist.github.com/HaiyangJin/097e33a79597ec73bcbf419c428086c1.
    # Here it simulates data for a 2 * 2 design.
    
    # function (version 2) to simulate the data set for fitting linear mixed models
    # This function simulates a dataset for fitting linear mixed mode. Please make sure library(tidyverse) is installed properly.
    # A more detailed explanation could be found [here](https://haiyangjin.github.io/2020/09/simulate-data-v2/)
    # Created by Haiyang Jin (https://haiyangjin.github.io/)
    #
    # Usage:
    # # You may set up any parameter in P (see below the default parameters), otherwise the default parameters will be used.
    # devtools::source_gist("https://gist.github.com/HaiyangJin/097e33a79597ec73bcbf419c428086c1") # OR
    # simulation <- simudata_lmm2()  # will use the default parameters
    # # There are three outputs:
    # #    simudata: the simulated data file.
    # #    population: the true values of the six parameters when `contr.sdif` is used (P$alpha, P$beta_ori, P$beta_sp, P$beta_ori_sp, P$beta_ori_hm).
    # #    params : all the parameters used for the simulation (i.e., P in this function).
    
    # load library
    library(tidyverse)    
    
    ############ set the default parameters ############ 
    P <- list(
        N_subj = 30,
        N_item = 30,
        IV1 = c("upright", "inverted"),    # orientation
        IV2 = c("low", "high"),  # spatial frequency
        # define the population (fixed effects) parameters
        alpha = -4,        # the grand mean
        beta_ori = -2,     # orientation: inverted - upright
        beta_sp = -1,      # spatial frequency: high - low
        beta_ori_sp = 1,   # interaction between orientation and (high-low)

        # the sigma (residuals)
        sigma = 2,
        
        # by-subject random effects
        alpha_u_sd = 2,        # sd of the by-subject random intercepts of orientation
        beta_ori_u_sd = .5,    # sd of the by-subject random slopes of orientation
        beta_sp_u_sd = .5,     # sd of the by-subject random slopes of high - low
        beta_ori_sp_u_sd = .5, # sd of the by-subject random slopes of interaction between orientation and (high-low)
        rho_u = 0.4,           # correlations between the by-subject random effects
        
        # by-item random effects
        alpha_w_sd = 1,        # sd of the by-item random intercepts of orientation
        beta_ori_w_sd = .3,    # sd of the by-item random slopes of orientation
        beta_sp_w_sd = .3,     # sd of the by-item random slopes of high - low
        beta_ori_sp_w_sd = .3, # sd of the by-item random slopes of interaction between orientation and (high-low)
        rho_w = 0.3           # correlations between the by-item random effects
    )
    
    # update the default parameters with the input
    for (temp_name in names(params)) {
        P[[temp_name]] <- params[[temp_name]]
    }
    
    # summary of the true values
    fixed_true <- c(P$alpha, P$beta_ori, P$beta_sp, P$beta_ori_sp)
    u_sd_true <- c(P$alpha_u_sd, P$beta_ori_u_sd, P$beta_sp_u_sd, P$beta_ori_sp_u_sd)
    w_sd_true <- c(P$alpha_w_sd, P$beta_ori_w_sd, P$beta_sp_w_sd, P$beta_ori_sp_w_sd)
    
    ############ the fixed effects ############ 
    nlevel_ori <- length(P$IV1)
    nlevel_sf <- length(P$IV2)
    N_cond <- nlevel_ori * nlevel_sf
    N_trial <- N_cond * P$N_subj * P$N_item
    
    # Create a experiment condition tibble
    df_cond <- tibble(
        subject = rep(rep(1:P$N_subj, each = P$N_item), each = N_cond),
        stimulus = rep(rep(1:P$N_item, times = P$N_subj), each = N_cond),
        Orientation = as_factor(rep(rep(P$IV1, each = nlevel_sf), times = P$N_subj * P$N_item)),
        SF = as_factor(rep(P$IV2, times = P$N_subj * P$N_item * nlevel_ori))
    )
    
    # set back difference coding for the independent variables
    contrasts(df_cond$Orientation) <- MASS::contr.sdif(nlevel_ori)
    contrasts(df_cond$SF) <- MASS::contr.sdif(nlevel_sf)
    
    # Create the design matrix (including the interaction)
    df_simu_design <- model.matrix( ~ 1 + Orientation * SF, df_cond)
    
    # Simulating the fixed effects
    dv_fixed <- df_simu_design %*% fixed_true
    
    ############ the random effects for subjects ############ 
    # random effects for subject
    N_u_sd <- length(u_sd_true)
    
    # correlation matrix
    u_corr <- (1- diag(N_u_sd)) * P$rho_u + diag(N_u_sd)
    # Cholesky factor
    L_u <- chol(u_corr)
    # # We  can verify that we recover rho_u with:
    # t(L_u) %*% L_u
    
    # simulate random effects for subjects
    # uncorrelated z values from the standard normal distribution for all random effects
    z_u <- replicate(N_u_sd, rnorm(P$N_subj, 0, 1))
    # Variance matrix
    u_var <- diag(N_u_sd) * u_sd_true
    
    # random effects of subjects
    u <- u_var %*% t(L_u) %*% t(z_u)
    random_u <- t(u)[df_cond$subject, ]
    
    # random effects of subjects for each trial
    dv_u <- rowSums(df_simu_design * random_u)
    
    ############ the random effects for items ############ 
    # random effects for item
    N_w_sd <- length(w_sd_true)
    
    # correlation matrix
    w_corr <- (1- diag(N_w_sd)) * P$rho_w + diag(N_w_sd)
    # Cholesky factor
    L_w <- chol(w_corr)
    # # We verify that we recover rho_w,
    # t(L_w) %*% L_w
    
    # simulate random effects for subjects
    # uncorrelated z values from the standard normal distribution for all random effects
    z_w <- replicate(N_w_sd, rnorm(P$N_subj, 0, 1))
    # Variance matrix
    w_var <- diag(N_w_sd) * w_sd_true
    
    # random effects of items
    w <- w_var %*% t(L_w) %*% t(z_w)
    random_w <- t(w)[df_cond$stimulus, ]
    
    # random effects of items for each trial
    dv_w <- rowSums(df_simu_design * random_w)
    
    ############ generate the dependent variables ############ 
    # combine fixed, random effects and the sigma (residuals)
    df_simu <- df_cond %>% 
        mutate(DV = dv_fixed[, 1] + dv_u + dv_w + rnorm(n(), 0, P$sigma))
    
    ############ return the output ############
    contr_matrix <- df_simu_design %>% unique() %>% as.matrix() 
    population_true <- contr_matrix %*% as.matrix(fixed_true) %>% as.vector()
    names(population_true) <- paste(rep(substr(P$IV1, 1, 3), each = length(P$IV2)), 
                                    rep(substr(P$IV2, 1, 3), times = length(P$IV1)),
                                    sep = "_")
    
    return(list(simudata = df_simu, 
                population = population_true, 
                params = P))
}