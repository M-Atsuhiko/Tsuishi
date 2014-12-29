evolution <- function(MULTI_GENERATION,Good_ID,Top_Estimate){
  # 論文によると、すべての個体がcross_overによってのみ作られているわけではないらしい
  # もとの個体のパラメータをそのままコピーする個体もいるようだが、それがどうやって選ばれるのかは謎
  
  GENERATION_Params <- lapply(MULTI_GENERATION,"[[","Params")

  N_Cross_over <- sum(runif(N_INDIVIDUAL) <= GA_CROSS_OVER)#一点交叉を行う個体の総数

  #一点交叉しない個体の番号を成績上位から選ぶ(最も成績の良かった個体はエリート保存を行う)
  Not_Cross_ID <- Good_ID[c(rep(TRUE,(N_INDIVIDUAL - N_Cross_over)),rep(FALSE,(N_Cross_over)))]
  Cross_ID <- setdiff(Good_ID[1:N_INDIVIDUAL],Not_Cross_ID)

  # 1:エリート保存(Good_ID[1]の個体にはなにもしない) シミュレーションの行える個体が発生してから有効にする
  Best_ID <- Good_ID[1]#最も最良の個体
  Worst_ID <- Good_ID[N_INDIVIDUAL]#最も最悪の個体

  #最良個体のIDを取り出す
  Not_Cross_ID <- setdiff(Not_Cross_ID,c(Best_ID,Good_ID[N_INDIVIDUAL]))
  Cross_ID <- setdiff(Cross_ID,c(Best_ID,Good_ID[N_INDIVIDUAL]))

  MULTI_GENERATION[[Best_ID]][["TREE"]] <- as.list(NULL)
  MULTI_GENERATION[[Best_ID]][["Estimate"]] <- NULL
  MULTI_GENERATION[[Best_ID]][["Parent"]] <- Best_ID

  #最悪の個体に最良の個体のパラメータを突然変異させて残す これはNot_Cross_overの個体と関係なく行う
  MULTI_GENERATION[[Worst_ID]][["Params"]] <- mutation(MULTI_GENERATION[[Best_ID]][["Params"]])
  MULTI_GENERATION[[Worst_ID]][["TREE"]] <- as.list(NULL)
  MULTI_GENERATION[[Worst_ID]][["Estimate"]] <- NULL
  MULTI_GENERATION[[Worst_ID]][["Parent"]] <- Best_ID

  # 2:一点交叉
  for(IND_i in Cross_ID){
    DECENDENT <- list(NULL)# 次世代の個体、以下でそのパラメータを決める
    
    parent_pair <- sample(Good_ID[1:ES_RAMDA],size=2,prob=SELECT_PROB)

#      cat("parent1: ",Good_ID[parent1_i],"(",parent1_i,") parent2: ",Good_ID[parent2_i],"(",parent2_i,")\n")
    
      # 1組のパラメータセットはMAX_PARAMS個の要素があるので、1~MAX_PARAMSのランダムな数字を交叉点(cross_point)とする。
      # ただしcross_point = 1の時は要素1を残して残りの要素を入れ替える。
      # cross_point = MAX_PARAMSの時は全ての要素を入れ替える
      # 一回の交叉で1つの子個体が作られるとする
      # 入れ替えるDendriteはparent1、parent2からそれぞれランダムに選択する
      # parent1とparen2の内、Dendriteの本数が少ない方の各Dendriteについて一回ずつ一点交叉を行う
      # 二つのparentの持つDendriteの本数が異なる場合
      # Dendriteの本数が多いparentの内、交叉に関与しなかった、余ったDendriteはそのまま子に引き継がれる

      
      # Upper paramを一点交叉させる
    parent_pair <- sample(parent_pair,2)#交叉する際の上下を決める
    
    parent1 <- GENERATION_Params[[parent_pair[1]]][[1]]
    parent2 <- GENERATION_Params[[parent_pair[2]]][[1]]

    Cross_point <- sample(1:MAX_PARAMS,1,replace=TRUE)

    New_Upper_Param <- as.list(NULL)
    
    for(i in 1:MAX_PARAMS){
      if(i <= Cross_point) New_Upper_Param[[i]] <- parent1[[i]]
      else New_Upper_Param[[i]] <- parent2[[i]]
    }

    names(New_Upper_Param) <- Param_Labels

    # Lower paramを一点交叉
    parent_pair <- sample(parent_pair,2)#交叉する際の上下を決める
    
    parent1 <- GENERATION_Params[[parent_pair[1]]][[2]]
    parent2 <- GENERATION_Params[[parent_pair[2]]][[2]]

    Cross_point <- sample(1:MAX_PARAMS,1,replace=TRUE)

    New_Lower_Param <- as.list(NULL)
                                                   
    for(i in 1:MAX_PARAMS){
      if(i <= Cross_point) New_Lower_Param[[i]] <- parent1[[i]]
      else New_Lower_Param[[i]] <- parent2[[i]]
    }
    
    names(New_Lower_Param) <- Param_Labels

    DECENDENT <- list(New_Upper_Param,New_Lower_Param)

    MULTI_GENERATION[[IND_i]][["Params"]] <- DECENDENT
    #前世代で作ったTREEも削除する
    MULTI_GENERATION[[IND_i]][["TREE"]] <- as.list(NULL)
    MULTI_GENERATION[[IND_i]][["Estimate"]] <- NULL
    MULTI_GENERATION[[IND_i]][["Parent"]] <- parent_pair
    
  }#end(交叉する場合)

  # 3:前世代の個体をコピーして突然変異
  for(IND_i in Not_Cross_ID){
    MULTI_GENERATION[[IND_i]][["Params"]] <- mutation(MULTI_GENERATION[[IND_i]][["Params"]])
    #前世代で作ったTREEも削除する
    MULTI_GENERATION[[IND_i]][["TREE"]] <- as.list(NULL)
    MULTI_GENERATION[[IND_i]][["Estimate"]] <- NULL
    MULTI_GENERATION[[IND_i]][["Parent"]] <- IND_i
  }
  
  return(MULTI_GENERATION)
}

mutation <- function(individual){
  for(i_dend in 1:length(individual)){# 各パラメータ値をランダムにガウス乱数を用いて変更する
    Mutation_or_Not <- runif(MAX_PARAMS)
    for(param_i in 1:MAX_PARAMS){
      if(Mutation_or_Not[param_i] < GA_MUTATION_AR_G){
        param_name <- Param_Labels[[param_i]]
        parameter <- individual[[i_dend]][[param_name]]
        
                                        #負の値をとってもいいパラメータ
                                        #prameterのオーダが 10^1 ~ 10^2 くらいのもの
        if(!(is.na(match(param_name,"Stem_elevation_MIEW"))) ||
           !(is.na(match(param_name,"Stem_rotation_MIEW"))) ||
           !(is.na(match(param_name,"Branch_rotation_MIEW"))) ||
           !(is.na(match(param_name,"Branch_elevation_MIEW")))){
          new_parameter <- rnorm(1,mean=parameter,sd=MUTATION_ANGLE_MIEW_SD)
        }

                                        #以下は負の値になってはいけないパラメータ
                                        #parameterのオーダが 10^1 ~ 10^2 くらいのもの
        else if(!(is.na(match(param_name,"Branch_rotation_SIGMA"))) ||
                !(is.na(match(param_name,"Branch_elevation_SIGMA")))){
          new_parameter <- abs(rnorm(1,mean=parameter,sd=MUTATION_ANGLE_SIGMA_SD))
        }
        else if(!(is.na(match(param_name,"Length_MIEW")))){
          new_parameter <- abs(rnorm(1,mean=parameter,sd=MUTATION_LENGTH_MIEW_SD))
        }

        else if(!(is.na(match(param_name,"Bif_beta"))) ||
                !(is.na(match(param_name,"Trm_beta"))) ){
          new_parameter <- abs(rnorm(1,mean=parameter,sd=MUTATION_beta_SIGMA_SD))
          new_parameter <- max(new_parameter,MIN_GAMMMA_BETA)
        }
                                        #parameterのオーダが 10^0 くらいのもの
        else if(!(is.na(match(param_name,"Bif_alfa"))) ||
                !(is.na(match(param_name,"Trm_alfa")))){
          new_parameter <- abs(rnorm(1,mean=parameter,sd=MUTATION_alfa_taper_diam_SD))
          new_parameter <- max(new_parameter,MIN_GAMMMA_ALFA)
        }

        else if(!(is.na(match(param_name,"K_taper"))) ||
                !(is.na(match(param_name,"Ca_taper"))) ){
          new_parameter <- max(rnorm(1,mean=parameter,sd=MUTATION_alfa_taper_diam_SD),0)
        }

                  #以下は特殊なもの
        else if(!(is.na(match(param_name,"K_Stem_conductance")))){#K_Stem_conductanceはある範囲の値をとる
          new_parameter <- rnorm(1,mean=parameter,sd=MUTATION_CONDUCTANCE_SIGMA)
          new_parameter <- min(max(new_parameter,K_RANGE[1]),K_RANGE[2])*WITH_K #Kがはいってない場合は(WITH_K = 0)
        }
        else if(!(is.na(match(param_name,"Ca_Stem_conductance")))){#Ca_Stem_conductanceはある範囲の値をとる
          new_parameter <- rnorm(1,mean=parameter,sd=MUTATION_CONDUCTANCE_SIGMA)
          new_parameter <- min(max(new_parameter,Ca_RANGE[1]),Ca_RANGE[2])*WITH_Ca #Caがない場合は(WITH_Ca=0)
        }
        
        else if(!(is.na(match(param_name,"Stem_diameter")))){
          repeat{
            new_parameter <- rnorm(1,mean=parameter,sd=MUTATION_alfa_taper_diam_SD)
            if(new_parameter > FOURCE_MIN_DIAM) break
          }
        }
                                        #上で決定した新たなparameter値を格納する
        individual[[i_dend]][[param_name]] <- new_parameter
      }
    }
  }

  if(runif(1) < GA_DELETE){#樹状突起の削除
    individual[[sample(c(1,2),1)]] <- Param_init(1)[[1]]
  }
  return(individual)
}
