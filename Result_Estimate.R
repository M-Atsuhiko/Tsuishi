Result_Estimate <- function(MULTI_GENERATION){
  Good_i <- c() #Good_Resultになった個体の添字

  Max_F <- -1
  Max_Mor <- -1
  Max_Ca <- -1
  Max_K <- -1
  
  for(i in 1:N_INDIVIDUAL){
    
    if(MULTI_GENERATION[[i]][["Result"]] == Mor_E)
      MULTI_GENERATION[[i]][["Estimate"]] <- Morpho_penalty(MULTI_GENERATION[[i]][["TREE"]])
    
    else if(MULTI_GENERATION[[i]][["Result"]] == EPSP_E)
      MULTI_GENERATION[[i]][["Estimate"]] <- penalty(1,EPSP_PENALTY_MIEW,EPSP_PENALTY_SIGMA)

    else if(MULTI_GENERATION[[i]][["Result"]] == Bad_Result)
      MULTI_GENERATION[[i]][["Estimate"]] <- MULTI_GENERATION[[i]][["Ratio"]]*-1
    else if(MULTI_GENERATION[[i]][["Result"]] == Good_Result){
      Good_i <- c(Good_i,i)
      Max_F <- max(Max_F,MULTI_GENERATION[[i]][["Ratio"]])
      Max_Mor <- max(Max_Mor,MULTI_GENERATION[[i]][["TREE_Volume"]])
      Max_Ca <- max(Max_Ca,MULTI_GENERATION[[i]][["Ca_Amount"]])
      Max_K <- max(Max_K,MULTI_GENERATION[[i]][["K_Amount"]])
    }
  }
  
  for(i in Good_i){
    #全ての項目に対して世代中での相対的な評価をする
    Func_minus <- Function_ratio*(1 - MULTI_GENERATION[[i]][["Ratio"]]/Max_F)
    Morpho_minus <- Morphology_ratio*(MULTI_GENERATION[[i]][["TREE_Volume"]]/Max_Mor)
    
    K_Ratio <- 0
    Ca_Ratio <- 0

    if(WITH_K || WITH_Ca){
      #コンダクタンス量はあまりにも小さいとアンダーフローするか、0除算になる危険性がある
      if(WITH_K) K_Ratio <- MULTI_GENERATION[[i]][["K_Amount"]]/Max_K
      if(WITH_Ca) Ca_Ratio <- MULTI_GENERATION[[i]][["Ca_Amount"]]/Max_Ca

      Conductance_minus <- Conductance_ratio*(K_Ratio + Ca_Ratio)/(WITH_K + WITH_Ca)
    }else{
      Conductane_minus <- 0
    }
    
    Estimate_Value <- 100 - Func_minus - Morpho_minus - Conductance_minus
    
    MULTI_GENERATION[[i]][["Estimate"]] <- Estimate_Value
  }
  return(MULTI_GENERATION)
}


