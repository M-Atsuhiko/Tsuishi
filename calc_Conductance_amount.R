calc_Conductance_amount <- function(TREE,WITH_K,WITH_Ca){
  
  All_K_Conductance <- 0 #S
  All_Ca_Conductance <- 0 #S

  Max_K_Conductance <- 0
  Max_Ca_Conductance <- 0
  
  for(Dendrite in TREE){
    for(Branch in Dendrite){
      length <- Branch[["length"]]
      diam <- Branch[["diam"]]
      K_conductance <- Branch[["K_conductance"]]
      Ca_conductance <- Branch[["Ca_conductance"]]
      surface <- (diam*pi*length)*10^(-8) #側面の面積のみ考える
      All_K_Conductance <- All_K_Conductance + surface*K_conductance
      All_Ca_Conductance <- All_Ca_Conductance + surface*Ca_conductance

      Max_K_Conductance <- Max_K_Conductance + surface*K_MAX
      Max_Ca_Conductance <- Max_Ca_Conductance + surface*Ca_MAX
    }
  }

  return(c(All_K_Conductance,All_Ca_Conductance,Max_K_Conductance,Max_Ca_Conductance))
}
