#
#  _____ _   _ _   _  ____ _____ ___ ___  _   _ 
# |  ___| | | | \ | |/ ___|_   _|_ _/ _ \| \ | |
# | |_  | | | |  \| | |     | |  | | | | |  \| |
# |  _| | |_| | |\  | |___  | |  | | |_| | |\  |
# |_|    \___/|_| \_|\____| |_| |___\___/|_| \_|
#

judge_Trm <- function(Seg,Trm_alfa,Trm_beta){
  #--- 終端判定を行う関数 ---
  #伸張継続なら return 1
  #伸張終了なら return 0

  #ヒューリスティックス
  if(Seg[["diam"]] <= FOURCE_MIN_DIAM){
#    cat("termination due to small diam:",Seg[["diam"]],"\n")
    return(0)
  }
  else if(Seg[["path_leng"]] >= FOURCE_MAX_LENG){
#   cat("termination due to length:",Seg[["path_leng"]],"\n")
    return(0)
  }
  #終端判定
  else if(pgamma(Seg[["path_leng"]],shape = Trm_alfa,scale = Trm_beta) > runif(1)){
#    cat("termination due to stochastic\n")
    return(0)
  }
  else
    return(1)
}
judge_Trm <- cmpfun(judge_Trm)


judge_Bif <- function(Seg,Peak_val,Bif_alfa,Bif_beta){
  #--- 分岐を判定する関数 ---
  #分岐する場合   return 1
  #分岐しない場合 return 0
  Bif_prob <- (dgamma(Seg[["path_leng"]],shape = Bif_alfa, scale = Bif_beta)/Peak_val)*MAX_PEAK
  rand_num <- runif(1)
  
  if(Bif_prob > rand_num)
    return(1)
  else
    return(0)
}

calc_gamma_peak_val <- function(alfa,beta){ # scalingに用いるγ分布のピーク値
  return(dgamma(beta*(alfa - 1),shape = alfa, scale = beta))
}
#calc_gamma_peak_val <- cmpfun(judge_Bif) #この関数はコンパイルできなかった

make_branch <- function(N_Branch,param,isStem,isBif,Parent_Seg){
  #--- 新しい枝を作る関数 ---
  #枝は作るが、N_Barnchは変更しないので、呼び出しもとで管理する必要がある

#  Segment_length_MIEW <- param[["Length_MIEW"]]
#  Segment_length_SIGMA <- param[["Length_SIGMA"]]
#  Segment_length <- abs(rnorm(1,mean = Segment_length_MIEW, sd = Segment_length_SIGMA))
  Segment_length <- param[["Length_MIEW"]]
#  Segment_length <- 10 #Segment_lengthを決定しておくパターンを試してみる
  
  
  if(isStem == TRUE){
    elevation <- param[["Stem_elevation_MIEW"]]
    rotation <- param[["Stem_rotation_MIEW"]]
    diameter <- param[["Stem_diameter"]]
    Path_length <- Segment_length
    K_conductance <- param[["K_Stem_conductance"]]
    Ca_conductance <- param[["Ca_Stem_conductance"]]

    Parent_i <- -1
  }else{
    elevation_MIEW <- param[["Branch_elevation_MIEW"]]
    elevation_SIGMA <- param[["Branch_elevation_SIGMA"]]
  
    rotation_MIEW <- param[["Branch_rotation_MIEW"]]
    rotation_SIGMA <- param[["Branch_rotation_SIGMA"]]

    Length_MIEW <- param[["Length_MIEW"]]
    Length_SIGMA <- param[["Length_SIGMA"]]
    
    K_taper <- param[["K_taper"]]
    Ca_taper <- param[["Ca_taper"]]
    
    if(isBif == TRUE){#diameter 分岐しているとき
      diameter <- rnorm(1,mean = (Parent_Seg[["diam"]]/2),sd = 0.05)
    }else{
      diameter <- Parent_Seg[["diam"]] + Parent_Seg[["diam"]]*TAPER_RATE #diameter 論文からの変更点2 かけ算 こっちの方がよい結果が出たのでこっちを採用する
#      diameter <- Parent_Seg[["diam"]] + TAPER_RATE #diameter 別の論文を参考にした場合 足し算
    }
    
    if(diameter < FOURCE_MIN_DIAM)
      diameter <- FOURCE_MIN_DIAM
    
    Path_length <- Parent_Seg[["path_leng"]] + Segment_length#path length
    Parent_i <- Parent_Seg[["No"]]#parent

    K_conductance <- Parent_Seg[["K_conductance"]]*K_taper
     #conductanceをRANGEにおさめる
    K_conductance <- min(max(K_conductance,K_RANGE[1]),K_RANGE[2])*WITH_K
   
    Ca_conductance <- Parent_Seg[["Ca_conductance"]]*Ca_taper
     #conductanceをRANGEにおさめる
    Ca_conductance <- min(max(Ca_conductance,Ca_RANGE[1]),Ca_RANGE[2])*WITH_Ca
    
    elevation <- rnorm(1,mean = elevation_MIEW,sd = elevation_SIGMA)#elevation
    rotation <- rnorm(1,mean = rotation_MIEW,sd = rotation_SIGMA)#rotation
  }

  Branch_No <- N_Branch + 1
  Connect <- 0
  Coordi <- matrix(0,ncol=3,nrow=2)

  Nseg <- ceiling(Segment_length/COMP_MAX_SIZE)#The number of compartments was set to 1 per 5μm(COMP_MAX_SIZE) (rounded up toward the next odd number).
  if(Nseg %% 2 == 0)Nseg <- Nseg + 1

  Synapse <- -1

  New_Branch <- list(#枝を確率的に与える
                     Branch_No,#No
                     Segment_length,#length これあってるか謎
                     elevation,
                     rotation,
                     diameter,#diametre
                     Path_length,#path length
                     Parent_i,#parent
                     Connect,#connect
                     Coordi,#coordi
                     Nseg,#nseg
                     Synapse,#synapse
                     K_conductance,
                     Ca_conductance)
  
  names(New_Branch) <- Segment_Labels
  return(New_Branch)
}
make_branch <- cmpfun(make_branch)

make_Dend <- function(param){
  #パラメータの読み出し
  
  Bif_alfa <- param[["Bif_alfa"]]
  Bif_beta <- param[["Bif_beta"]]
  Trm_alfa <- param[["Trm_alfa"]]
  Trm_beta <- param[["Trm_beta"]]

#  cat("NEW DEND Trm_alfa,Beta:",Trm_alfa,Trm_beta,"\n")

  N_branch <- 0

  Dendrite <- as.list(NULL)

  Dendrite[[1]] <- make_branch(N_branch,param,TRUE,FALSE,FALSE)#Stemの作成
  N_Branch <- 1

  Peak_val <- calc_gamma_peak_val(Bif_alfa,Bif_beta)

  if(judge_Trm(Dendrite[[1]],Trm_alfa,Trm_beta) == 0){#Stemの伸張判定
#    cat("elongation stopped at STEM...\n")
  }else{
    if(judge_Bif(Dendrite[[1]],Peak_val,Bif_alfa,Bif_beta) == 1){#Stemの分岐判定
      Dendrite[[N_Branch + 1]] <- make_branch(N_Branch,param,FALSE,TRUE,Dendrite[[1]])
      Dendrite[[N_Branch + 2]] <- make_branch(N_Branch + 1,param,FALSE,TRUE,Dendrite[[1]])
      Dendrite[[1]][["connect"]] <- c(N_Branch + 1,N_Branch + 2)
      N_Branch <- N_Branch + 2
    }else{
      Dendrite[[N_Branch + 1]] <- make_branch(N_Branch,param,FALSE,FALSE,Dendrite[[1]])
      Dendrite[[1]][["connect"]] <- c(N_Branch + 1)
      N_Branch <- N_Branch + 1
    }
#    cat("-------------------- Start main loop --------------------\n")
    #もしStemが終端していた場合は即時終了
    if(N_Branch != 1) grow_Nums <- 2:N_Branch
    else grow_Nums <- c()
    
    while(length(grow_Nums) > 0){ #morphology生成メインループ
      new_grow <- c()
      for(i in grow_Nums){
        if(judge_Trm(Dendrite[[i]],Trm_alfa,Trm_beta) == 1){#伸張継続か
          if(judge_Bif(Dendrite[[i]],Peak_val,Bif_alfa,Bif_beta) == 1){#分岐するか
            Dendrite[[N_Branch + 1]] <- make_branch(N_Branch,param,FALSE,TRUE,Dendrite[[i]])
            Dendrite[[N_Branch + 2]] <- make_branch(N_Branch + 1,param,FALSE,TRUE,Dendrite[[i]])
            Dendrite[[i]][["connect"]] <- c(N_Branch + 1, N_Branch + 2)
            new_grow <- c(new_grow,N_Branch + 1, N_Branch + 2)
            N_Branch <- N_Branch + 2
          }else{#分岐しない
#            cat("grow\n")
            Dendrite[[N_Branch + 1]] <- make_branch(N_Branch,param,FALSE,FALSE,Dendrite[[i]])
            Dendrite[[i]][["connect"]] <- c(N_Branch + 1)
            new_grow <- c(new_grow,N_Branch + 1)
            N_Branch <- N_Branch + 1
          }
        }
        grow_Nums <- new_grow
      }
    }
  }

#  Dendrite <- set_coordinate(Dendrite)#3次元空間上の座標点情報を与える
#  Dendrite <- set_synapse(Dendrite)#シナプスをつける
  
  return(Dendrite)
}
make_Dend <- cmpfun(make_Dend)

#  __  __    _    ___ _   _ 
# |  \/  |  / \  |_ _| \ | |
# | |\/| | / _ \  | ||  \| |
# | |  | |/ ___ \ | || |\  |
# |_|  |_/_/   \_\___|_| \_|
#

make_TREE <- function(Params){
  TREE <- list(NULL)
  
  N_DEND <- length(Params)
#  cat("========== ID: ",ID_IND," NEURON WITH ",N_DEND," DENDRITES ==========\n")

  for(i in 1:N_DEND){
#    cat("======== DENDRITE: ",i,"=========\n")
    TREE[[i]] <- make_Dend(Params[[i]])
#    data_check(TREE[[i]]) #data_checkはシナプスの設定をチェックしているので、シナプスの設定を後で行う場合、ここではdata_checkは使えない
  }

#  cat("========== Finish making morphology ==========\n")

#  for(i in 1:N_DEND){
#    cat("* DEND[[",i,"]] with ",length(TREE[[i]]),"branchs\n")
#  }

#  if(Simulation_or_Not <- canSimulation(TREE)){#シミュレーションができる個体のみ、hocファイルを生成する
#    make_NEURON_morpho_conductance_data(TREE,MORPHO_FILE_NAME)
#    make_NEURON_synapse_data(TREE,SYNAPSE_FILE_NAME)
#  }
  return(TREE)
  #  take_movie()#作成した形態のgifを作成する
#  cat("========== FINISH ST_MOL ==========\n")
}

