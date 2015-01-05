source("./Simulation_Parameters.R")

cat("@@@@@ Tsuishi @@@@@\n")

Param_Labels <- Tsuishi_Param_Labels
MAX_PARAMS <- length(Param_Labels)
if(Conductance_ratio > 0) stop("Error: Tsuishi doesn't require Conductance RATIO!")

############### 関数include ###############
#[Param_init.R]               : paramの初期値を返す関数
source("./Tsuishi_Param_init.R")
#[Tsuishi_make_TREE.R]                   : 確率的に形態を生成する関数
source("Tsuishi_make_TREE.R")
#[set_coordinate.R]           : Branchの空間座標点を設定する関数
source("./set_coordinate.R")
#[set_synapse.R]              : Dendrite上にsynapseを設定する関数
source("./set_synapse.R")
#[display_morphology.R]       : 完成したDendriteを3次元空間状に描画する関数
source("./display_morphology.R")
#[display_morphology.R]       : 完成したDendriteを3次元空間状に描画する関数
source("./display_conductance_on_morphology.R")
#[display_synapse]            : synapseを3次元空間状に描画する関数
source("./display_synapse.R")
#[NEURON_syntax.R]            : Hocファイル生成時に用いる関数群
source("./NEURON_functions.R")
#[make_NEURON_morpho_conductance.R] : コンダクタンスを持った形態データの出力をする関数
source("./make_NEURON_morpho_conductance_data.R")
#[make_NEURON_synapse_data.R] : 作成したsynapseをhocファイルの形式で出力する
source("./make_NEURON_synapse_data.R")
#[data_check.R]               : 作成したdendriteデータにエラー(Noの設定が正しいか、synapseの位置が正しいかなど)をチェックする関数
source("./data_check.R")
#[Tsuishi_estimation.R]               : シミュレーション結果の評価
source("./Tsuishi_estimate.R")
#[penalty.R]                  : うまく形態生成ができなかった場合のpenaltyを与える関数
source("./penalty.R")
#[Tsuishi_evolution.R]                : 評価値から次の世代を生成する関数
source("./Tsuishi_evolution.R")
#[output_results.R]           : 結果をファイルに出力する関数
source("./output_results.R")
#[make_simul_parameter]       : シミュレーションで用いるパラメータのファイルを作成する関数
source("./make_simul_parameter.R")
#[parallel_task]              : シミュレーションを行うための関数 
#source("./Tsuishi_parallel_task.R")
source("./Tsuishi_parallel_task_rerative.R")
#[sum_length]                 : 木の大きさ(Dendriteの長さの総和)を返す関数
source("./sum_length.R")
#[canSimulation.R]            : 木の大きさ(Dendriteの長さの総和)を返す関数
source("./canSimulation.R")
#[set_Upper_or_Lower_or_Other.R] : TREEの枝に関してUpperの枝かLowerの枝かそれ以外かを区別する
source("./set_Upper_or_Lower_or_Other.R")
#[calc_Conductance_ratio.R]   : TREEのコンダクタンス分布量の最大量に対する比を計算する関数
source("./calc_Conductance_ratio.R")
#[Tsuishi_divid_and_set_conductance_liner.R]     
source("./Tsuishi_divid_and_set_conductance_liner.R")
#[Morpho_penalty.R]     
source("./Morpho_penalty.R")
#[calc_Vollume.R]             : TREEの体積を計算する関数  
source("./calc_volume.R")

#        _                                _ 
#    ___| |__   __ _ _ __   __ _  ___  __| |
#   / __| '_ \ / _` | '_ \ / _` |/ _ \/ _` |
#  | (__| | | | (_| | | | | (_| |  __/ (_| |
#   \___|_| |_|\__,_|_| |_|\__, |\___|\__,_|
#                          |___/            
#[return_result.R]             : シミュレーション結果を返す関数
source("./return_result.R")
#[calc_Conductance_amount.R]
source("./calc_Conductance_amount.R")
#[Result_Estimate.R]         
source("./Result_Estimate.R")

##主要な関数をコンパイルしておく
divid_and_set_conductance <- cmpfun(Tsuishi_divid_and_set_conductance_liner)#ここ注意
Param_init <- cmpfun(Param_init)
make_TREE <- cmpfun(make_TREE)
set_coordinate <- cmpfun(set_coordinate)
set_synapse <- cmpfun(set_synapse)
make_NEURON_morpho_conductance_data <- cmpfun(make_NEURON_morpho_conductance_data)
make_NEURON_synapse_data <- cmpfun(make_NEURON_synapse_data)
data_check <- cmpfun(data_check)
estimate <- cmpfun(estimate)
penalty <- cmpfun(penalty)
evolution <- cmpfun(evolution)
parallel_task <- cmpfun(parallel_task)
sum_length <- cmpfun(sum_length)
canSimulation <- cmpfun(canSimulation)
set_Upper_or_Lower_or_Other <- cmpfun(set_Upper_or_Lower_or_Other)
calc_Conductance_ratio <- cmpfun(calc_Conductance_ratio)
return_result <- cmpfun(return_result)
calc_Conductance_amount <- cmpfun(calc_Conductance_amount)
Result_Estimate <- cmpfun(Result_Estimate)



### 結果格納ディレクトリ ###
RESULT_DATA_DIR                     <- paste("./",paste(include_conductances,collapse="_"),"_","Result/",sep="")
RESULT_GRAPH_DIR                    <- paste("./",paste(include_conductances,collapse="_"),"_","Result/Graphs/",sep="")

extra_prefix <- ""
if(!(is.na(args_extra_prefix))) extra_prefix <- paste("_",args_extra_prefix,sep="")
#出力物につけるPrefix
Prefix <- paste("SEED",RAND_SEED,"_","dt",DELTA_T,"_",paste(include_conductances,collapse="_"),"_",paste("FR",Function_ratio,sep=""),extra_prefix,"_",sep="")     #出力物につける識別子

### テストのための変更
if(THIS_IS_TEST){
  Prefix <- paste("test_",Prefix,sep="")
  MAX_GENERATION                 <- 10                     # GAのMAX世代数
  ES_RAMDA                       <- 5                      # 次世代生成に用いる優秀な個体の数
  N_INDIVIDUAL                   <- 20                     # 1世代の個体数
  SELECT_PROB                    <- set_select_prob(ES_RAMDA,1)
  WITH_Ca <- TRUE
}
###\テストのための変更

### 形態情報TREEの保存先、ファイル名 ###
BEST_Datas_FILE                <- paste(RESULT_DATA_DIR,Prefix,"Best_Datas.xdr",sep="")
### 世代パラメータGENETRATIONの保存先、ファイル名prefix ###
#SAVE_GENERATION                <- paste(RESULT_DIR,Prefix,"GENERATION",sep="")
### 最終的な出力物 ###
ESTIMATE_GRAPH                 <- paste(RESULT_GRAPH_DIR,Prefix,"estimate_graph.eps",sep="")  # 世代毎の最優秀評価値と平均値をまとめたグラフ
PERFORMANCE_GRAPH              <- paste(RESULT_GRAPH_DIR,Prefix,"performance_graph.eps",sep="")  # 世代毎にどの評価関数で評価されたかをまとめたグラフ
GENERATION_ESTIMATE_FILE       <- paste(RESULT_DATA_DIR,Prefix,"MAX_MEAN_SE.xdr",sep="")
LAST_GENERATION_FILE           <- paste(RESULT_DATA_DIR,Prefix,"LAST_GENERATION.xdr",sep="")
