Param_init <- function(N_DENDRITE){ #確率的にランダムなパラメータ群を初期Paramとして返す

  INDIVIDUAL <- as.list(NULL)

  for(i in 1:N_DENDRITE){
    Param <- list(  ### Stem parameter ###
                                        #Stem_elevation_MIEW (Gausian)
                  runif(1,min = -80,max = 80),
                                        #Stem_rotation_MIEW            
                  runif(1,min = 0,max = 360),

                                        #Stem_diameter (Const)
                  runif(1,min = 0.2,max = 10),

                                        #Segment_length  (Gausian(??))初期値は一様分布uniform(5,30)から選ばれる。Branchのlengthに関してはどこから得ているのか謎
#                  Seg_length,                
                                        #Length_MIEW (Gausian) 論文からの変更点1 Stem以外のlengthはGausianに求めることにする 初期のMIEWはSegment_lengthと等しい値にする
                  runif(1,min = 5,max = 30),         
                                        #Length_SIGMA
#                  10,                   

### Branch parameter ###
                                        #Branch_rotation_MIEW (Gausian)
                  runif(1,min = 0,max = 8),
                                        #Branch_rotation_SIGMA
                  10,


                                        #Branch_elevation_MIEW (Gausian)
                  runif(1,min = 0,max = 8),
                                        #Branch_elevation_SIGMA
                  10,

                                        #Bif_alfa (Scaled γ)
                  runif(1,min = 0,max = 4) + 1,  
                                        #Bif_beta
                  runif(1,min = 90,max = 170),
                  
                                        #Trm_alfa (Cumulative γ)
                  runif(1,min = 0,max = 4) + 1,                  
                                        #Trm_beta
                  runif(1,min = 5,max = 50),
                                        #K_Stem_Conductance (Uniform)
                  runif(1,min = 10^(-7),max = 0.08)*WITH_K,
                                        #K_taper
                  runif(1,min = 0.85,max = 1.15)*WITH_K,
                                        #Ca_Stem_Conductance (Uniform)
                  runif(1,min=10^(-8),max=0.0001)*WITH_Ca,
                                        #Ca_taper
                  runif(1,min = 0.85,max = 1.15)*WITH_Ca
                  )
    names(Param) <- Param_Labels
    INDIVIDUAL[[length(INDIVIDUAL) + 1]] <- Param
  }
  return(INDIVIDUAL)
}
