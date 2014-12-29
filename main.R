#Rprof(filename="~/Datas/Rprof.out")
### Systematic mapping between dendritic function and structure
### 最も外側で回るmainプログラム

#parameter設定、他のプログラムインクルード
source("Tsuishi_Dendritic_function_parameter.R")

#シミュレーションで使用するパラメータをまとめたhocファイルを生成する
make_simul_parameter(SIMUL_PARAMETER_FILE,celsius,cai,cao,ek)

#プログラムのパラメータについての表示
cat("SEED: ",RAND_SEED,"\n")
cat("Delta_t: ",DELTA_T,"\n")
cat("* Conductances neuron containing : ")
if(WITH_K) cat("Ka ")
if(WITH_Ca) cat("CaT ")
if(WITH_K + WITH_Ca == 0) cat("Nothing")
cat("\n")
if(THIS_IS_TEST) cat("@@@@@ NOTICE: MAX_GENERATION AND N_INDIVIDUAL IS MODIFIED FOR TEST @@@@@\n")
cat("Function ratio:",Function_ratio,"\n")
cat("Morphology ratio:",Morphology_ratio,"\n")
cat("Conductane ratio:",Conductance_ratio,"\n")

MULTI_GENERATION <- as.list(NULL)

####### 初期化部分 #######
for(ID_IND in 1:N_INDIVIDUAL){
  Params <- Param_init(N_DENDRITE)
  if(length(Params[[1]]) != length(Param_Labels)){
    print("Error! The Parameter length is not justified!\n")
    cat("length of Params, Param Labels:",length(Params),length(Param_Labels),"\n")
  }
    
#        _                                _ 
#    ___| |__   __ _ _ __   __ _  ___  __| |
#   / __| '_ \ / _` | '_ \ / _` |/ _ \/ _` |
#  | (__| | | | (_| | | | | (_| |  __/ (_| |
#   \___|_| |_|\__,_|_| |_|\__, |\___|\__,_|
#                          |___/
  
  INDIVIDUAL_DATA <- list(ID_IND,
                          MORPHO_FILE_NAME[ID_IND],
                          SYNAPSE_FILE_NAME[ID_IND],
                          OUTPUT_UPPER_LOWER_FILE_NAME[ID_IND],
                          OUTPUT_LOWER_UPPER_FILE_NAME[ID_IND],
                          OUTPUT_UPPER_TEST_FILE_NAME[ID_IND],
                          OUTPUT_LOWER_TEST_FILE_NAME[ID_IND],
                          Params,
                          NULL,#SEED
                          NULL,#TREE
                          NULL,#TREE_volume
                          NULL,#Ca_Amount
                          NULL,#K_Amount
                          NULL,#Estimate
                          NULL,#Ratio
                          NULL, #Parent
                          NULL,#RANK
                          "Initial"#Result
                          )
#  names(INDIVIDUAL_DATA) <- MULTI_GENERATION_Labels
  names(INDIVIDUAL_DATA) <- RERATIVE_MULTI_GENERATION_Labels
  MULTI_GENERATION[[ID_IND]] <- INDIVIDUAL_DATA
}

Generation_Estimates <- c() #最良の値、平均値、標準偏差を保存する行列
Best_Datas <- as.list(NULL) #各世代の最良の木を保存する
Generation_Performance <- c()           #各世代で　本来の評価関数で評価された個体の個数、シミュレーションでペナルティを与えられた個体の個数、形態的ペナルティを与えられた個体の個数を記録する
Start_GENER <- 1

#================ PROGRAM MAIN LOOP ===============#
for(I_GENER in Start_GENER:MAX_GENERATION){
  cat("<<< GENERATION: ",I_GENER," >>>\n")
  
  # ひと世代の内に
  SIM_IND <- c() # シミュレーションをし、本来の評価関数で評価された個体のID
  MOR_PENALTY_IND <- c() # 形態ペナルティを与えた個体のID
  EPSP_PENALTY_IND <- c() # シミュレーション結果でペナルティを与えた個体のID
  #を計算する

  # マルチコアでも乱数を扱えるように、(RAND_SEED、世代数、個体ID)に基づいた一意のランダムSEEDを設定する
  MULTI_GENERATION <- lapply(MULTI_GENERATION,function(INDIVIDUAL_DATA){
    INDIVIDUAL_DATA[["Seed"]] <- RAND_SEED*10^(8) + I_GENER*10^(4) + INDIVIDUAL_DATA[["ID_IND"]]
    return(INDIVIDUAL_DATA)
  })
  
  #形態情報から座標計算 シナプス付加 シミュレーション可能かの判断、シミュレーション実行までを行う
  MULTI_GENERATION <- foreach(one_please=MULTI_GENERATION) %dopar% parallel_task(one_please)
#  MULTI_GENERATION <- lapply(MULTI_GENERATION,parallel_task)
  
#        _                                _ 
#    ___| |__   __ _ _ __   __ _  ___  __| |
#   / __| '_ \ / _` | '_ \ / _` |/ _ \/ _` |
#  | (__| | | | (_| | | | | (_| |  __/ (_| |
#   \___|_| |_|\__,_|_| |_|\__, |\___|\__,_|
#                          |___/            
  MULTI_GENERATION <- Result_Estimate(MULTI_GENERATION)# 12/28変更 Rerativeを試すため


  

  ESTIMATION <- t(sapply(MULTI_GENERATION,function(INDIVIDUAL_DATA){
    return(c(INDIVIDUAL_DATA[["ID_IND"]],INDIVIDUAL_DATA[["Estimate"]]))
    }))

  Good_ID_ES<- ESTIMATION[rev(order(ESTIMATION[,2])),] #個体のIDを適応度順にソート
  Best_Datas[[I_GENER]] <- MULTI_GENERATION[[Good_ID_ES[1,1]]]#最も評価値の高いNEURONを保存

  MULTI_GENERATION <- lapply(MULTI_GENERATION,function(INDIVIDUAL_DATA){#個体に、今回の順位を持たせる
    INDIVIDUAL_DATA[["Rank"]] <- which(Good_ID_ES[,1] == INDIVIDUAL_DATA[["ID_IND"]])
    return(INDIVIDUAL_DATA)
  })

  Estimate_MIN_MEAN_SD <- c(max(ESTIMATION[,2]),mean(ESTIMATION[,2]),sd(ESTIMATION[,2]))
  cat("        MAX: ",Estimate_MIN_MEAN_SD[1],"\n       MEAN: ",Estimate_MIN_MEAN_SD[2],"\n         SD: ",Estimate_MIN_MEAN_SD[3],"\n","   Best ID: ",Good_ID_ES[1,1],"\n Best Ratio:",MULTI_GENERATION[[Good_ID_ES[1,1]]][["Ratio"]],"\n")
                           
  Generation_Estimates <- rbind(Generation_Estimates,Estimate_MIN_MEAN_SD)

  GOOD_PERFORMANCE_IND <- ESTIMATION[which(ESTIMATION[,2] > 0,arr.ind=TRUE),1]
  BAD_PERFORMANCE_IND <- ESTIMATION[which(ESTIMATION[,2] > -5 & ESTIMATION[,2] < 0,arr.ind=TRUE),1]
  EPSP_PENALTY_IND <- ESTIMATION[which(ESTIMATION[,2] < -10 & ESTIMATION[,2] > (MORPHO_PENALTY_MIEW + EPSP_PENALTY_MIEW)/2,arr.ind=TRUE),1]
  MOR_PENALTY_IND <- setdiff(1:N_INDIVIDUAL,c(GOOD_PERFORMANCE_IND,BAD_PERFORMANCE_IND,EPSP_PENALTY_IND))

  Generation_Performance <- rbind(Generation_Performance,c(length(MOR_PENALTY_IND)
                                                           ,length(EPSP_PENALTY_IND)
                                                           ,length(c(GOOD_PERFORMANCE_IND,BAD_PERFORMANCE_IND))))

  cat("  (Good,BAD,P-EPSP,P-MORPHO) :",length(GOOD_PERFORMANCE_IND),length(BAD_PERFORMANCE_IND),length(EPSP_PENALTY_IND),length(MOR_PENALTY_IND),"\n")
  cat("<<< END GENERATION: ",I_GENER," >>>\n\n")

    #GAによるパラメータ変更 evolution関数の中で、個体のTREEを削除する
  if(I_GENER < MAX_GENERATION){    #最終世代を変更せずに取り出す為に、最後の一回は進化を行わない
    MULTI_GENERATION <- evolution(MULTI_GENERATION,Good_ID_ES[,1],Good_ID_ES[1,1])
  }

}# MAIN_LOOP終了

## Best_Datas <- lapply(Best_Datas,function(Individual_Data){
##   Individual_Data[["TREE"]] <- divid_and_set_conductance_liner(Individual_Data[["TREE"]],Individual_Data[["Params"]])
##   return(Individual_Data)
## })

## MULTI_GENERATION <- lapply(MULTI_GENERATION,function(Individual_Data){
##   Individual_Data[["TREE"]] <- divid_and_set_conductance_liner(Individual_Data[["TREE"]],Individual_Data[["Params"]])
##   return(Individual_Data)
## })

#display_conductance_on_morphology(MULTI_GENERATION[[length(MULTI_GENERATION) - 4]][["TREE"]],"Ca_conductance")
output_results(Generation_Estimates,
               Generation_Performance,
               Best_Datas,
               MULTI_GENERATION)
cat("SIMULATION END\n")
#Rprof(NULL)
#summaryRprof()
