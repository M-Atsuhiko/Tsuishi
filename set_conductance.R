segment_conductance <- function(Dendrite,cond_name,cond_Peak,Gaus_mean,Gaus_sd){
  Gaus_peak <- dnorm(Gaus_mean,mean=Gaus_mean,sd=Gaus_sd)
  N_Branch <- length(Dendrite)

  Dend_length <- Dendrite[[N_Branch]][["path_leng"]]

  Dendrite <- lapply(Dendrite,function(Branch){
    path_leng <- Branch[["path_leng"]]
    path_ratio <- path_leng/Dend_length
    Branch[[cond_name]] <- (dnorm(path_ratio,mean=Gaus_mean,sd=Gaus_sd)/Gaus_peak)*cond_Peak
    return(Branch)
  })
  return(Dendrite)
}

set_conductance <- function(Dendrite,Param){
  if(WITH_K){
    Dendrite <- segment_conductance(Dendrite,
                                    "K_conductance",
                                    Param[["K_peak"]],
                                    Param[["K_Gaus_mean"]],
                                    Param[["K_Gaus_sd"]]
                                    )
  }
  if(WITH_Ca)
    Dendrite <- segment_conductance(Dendrite,
                                    "Ca_conductance",
                                    Param[["Ca_peak"]],
                                    Param[["Ca_Gaus_mean"]],
                                    Param[["Ca_Gaus_sd"]]
                                    )
  return(Dendrite)
}
