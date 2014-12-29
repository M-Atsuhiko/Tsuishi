# 2014/05/23
# 論文[Systematic mapping between dendritic function and structure]
# BENJAMIN TORBEN-NIELSEN et al 2009
# inverse approachの中の、確率的に神経細胞形態を生成する部分
# パラメータ設定ヘッダ

# これらの値は暫定的なもの

# [論文で不明な点と改善方法]
#
# 1、Stem以外のlengthの算出方法が載ってない -> 他の参考文献からすべてのセグメントの長さは一定にする
# 2、Diameterの計算方法がおかしい。論文の方法では負の値になる(d_(i) = d_(i - 1)*Taper_rate) -> d_(i) = d_(i - 1) + d_(i - 1)Taper_rateにする。
# 3、Synaptic zoneの定義の仕方があいまい。somaからy軸方向にy > UPPER_SYNAPTIC_ZONE_Y(正の値)となる範囲をred synapse zone、somaからy < LOWER_SYNAPTIC_ZONE_Y(負の値)となる範囲をblue synaptic zoneとする

# [改良できそうな点]
#
# 1、GAの遺伝子をより直接的に遺伝子としてあつかう
# 2、遺伝子の、コンダクタンスと形態の比率を変えてみる。より電気的特性を詳しくする。
# 3、確率分布の選び方、これによって作成される形態が変わりそう

# プログラム中の主なデータ構造
# 基本的にリスト形式で扱っている
#
# 1, Segment  : 三次元空間中に伸びる、樹状突起を構成する円柱状のパーツ。長さ、伸張角度、始点と終点の三次元座標などのパラメータをもつ
# 2, Stem     : somaから最初に伸びるSegment
# 3, Branch   : Stem以外のSegment
# 4, Dendrite : 一つのStemと、そこから伸びるBranchをあわせたもの
# 5, param    : StemとBranchは一組のパラメータ群から作成される、その元となるパラメータのひとまとまり
# 6, Dendrite : 作成されたStemとBranchの組、これを一つのDendriteとして扱う
# 7, TREE     : 複数のparamから作成された複数のDendriteを格納するlist

RAND_SEED                      <- Sys.time()
#一応両方のSYNAPTIC ZONEに枝を伸ばすNEURONが作れる初期値: 1402805220
RAND_SEED <- 1403262665
cat("Rand_Seed: ",RAND_SEED,"\n")
set.seed(RAND_SEED)

Param_init <- function(Dend_color){ #確率的にランダムなパラメータ群を初期Paramとして返す
  
  Seg_length <- runif(1,min = 5,max = 30)
  
  Param <- list(
  ### Stem parameter ###
#Stem_elevation_MIEW (Gausian)
    runif(1,min = -80,max = 80),
#Stem_elevation_SIGMA (Gausian)
    10,


#Stem_rotation_MIEW            
    runif(1,min = 0,max = 360),
#Stem_rotation_SIGMA (Gausian)
    10,

#Stem_diameter (Const)
    runif(1,min = 0.2,max = 10),

#Segment_length  (Gausian(??))初期値は一様分布uniform(5,30)から選ばれる。Branchのlengthに関してはどこから得ているのか謎
    Seg_length,                
#Length_MIEW (Gausian) 論文からの変更点1 Stem以外のlengthはGausianに求めることにする 初期のMIEWはSegment_lengthと等しい値にする
    Seg_length,         
#Length_SIGMA
    10,                   

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
#Dendrite_Color
    Dend_color
    )
  names(Param) <- Param_Labels
  
  return(Param)
}

Segment_Labels <- c(
#     Stemデータ構造
#-----------------------
# segmentデータはリスト形式で表し、
# [[1]]:
  "No",
# [[2]]:
  "length",
# [[3]]:
  "elevation",
# [[4]]:
  "rotation",
# [[5]]:
  "diam",
# [[6]]:
  "path_leng",
# [[7]]:
  "parent",
# [[8]]:
  "connect",#(ベクトル)、結合しているBranchの番号
# [[9]]:
  "coordi", #そのsegmentの始点[1,]と終点[2,]を表す座標をもった2x3行列
# [[10]]:
  "nseg", #length/5.0 を奇数に繰り上げした値
# [[11]]:
  "synapse" #synapsを形成している位置をcoordi[1,]からcoordi[2,]を1とした比で表す。この比とUPPER_ZENE(UPPER_SYNAPTIC_ZONE_COLOR)かLOWER_ZONE(LOWER_SYNAPTIC_ZONE_COLOR)かの情報をもつ行列形式で格納する。シナプスがなければ -1(int)にしておく
  
# somaから最初に伸びる枝はStemとして扱う
# それ以外はBranch
  )

Dendrite_Labels <- c(
#     Dendriteデータ構造
#-----------------------
#[[1]]:
  "Stem",
#[[2]]  
  "Branch")


Param_Labels <- list(
### Stem parameter ###
#[[1]]:
  "Stem_elevation_MIEW",
#[[2]]:
  "Stem_elevation_SIGMA",
#[[3]]  
  "Stem_rotation_MIEW",
#[[4]]    
  "Stem_rotation_SIGMA",
#[[5]]    
  "Stem_diameter",
#[[6]]  
  "Segment_length",
#[[7]]    
  "Length_MIEW",
#[[8]]    
  "Length_SIGMA",
#[[9]]    
  "Branch_rotation_MIEW",
#[[10]]    
  "Branch_rotation_SIGMA",
#[[11]]    
  "Branch_elevation_MIEW",
#[[12]]    
  "Branch_elevation_SIGMA",
#[[13]]    
  "Bif_alfa",
#[[14]]    
  "Bif_beta",
#[[15]]    
  "Trm_alfa",
#[[16]]    
  "Trm_beta",
#[[17]]
  "Dendrite_Color"
  )

###   st_mol用のパラメータ  ###
FOURCE_MAX_LENG                <- 2000                   # [μm] 強制的に終端させる長さ
FOURCE_MIN_DIAM                <- 0.15                   # [μm] 強制的に終端させる太さ

MAX_PEAK                       <- 0.8                    # (Scaled γのピークの値) 

SOMA_DIAM                      <- 25                     # 球形のsomaの直径

TAPER_RATE                     <- -0.125                 # 論文では d_(i) = d_(i - 1)*Taper_rate の計算になってるけど、これはおかしい

AXIS_LENG                      <- 100                    #y'軸、z'軸を例示する際の直径

SOMA_COLOR                     <- "green"                #Somaを図示する際の色
SOMA_TEXTURE                   <- "sample1.png"          #Somaの球に貼る画像
STEM_COLOR                     <- "blue"                 #Stemを図示する際の色
BRANCH_COLOR                   <- "green"                #Branchを図示する際の色

OUTPUT_MOVIE                   <- "/Users/Atsuhiko/workspace/Function_Morphology/stochastic_morphology/movie/st_mol_output_movie" #gifデータ出力ファイル名

UPPER_SYNAPTIC_ZONE_COLOR      <- "red"
LOWER_SYNAPTIC_ZONE_COLOR      <- "blue"

UPPER_SYNAPTIC_ZONE_INDEX      <- 1
LOWER_SYNAPTIC_ZONE_INDEX      <- 0

UPPER_SYNAPTIC_ZONE_Y          <- 170.0                 # [μm] somaからの距離、red synapseを作る範囲を変更する
LOWER_SYNAPTIC_ZONE_Y          <- -170.0                # [μm] somaからの距離、blue synapseを作る範囲を変更する

SYNAPTIC_ZONE_DEPTH            <- 20.0                  # [μm] synaptic zoneの深さ

UPPER_SYNAPTIC_ZONE_BOUNDARY_Y <- UPPER_SYNAPTIC_ZONE_Y + SYNAPTIC_ZONE_DEPTH 
LOWER_SYNAPTIC_ZONE_BOUNDARY_Y <- LOWER_SYNAPTIC_ZONE_Y - SYNAPTIC_ZONE_DEPTH

SYNAPTIC_SHOW_SQUARE           <- 300.0                 # [μm] synaptic zoneを図示する際に用いるxy平面に平行な正方形の一辺の長さ
ALP                            <- 0.3                   # synaptic zoneを図示する際の透明度

SYNAPSE_RADIUS                 <- 2.5                   # [μm] synapseを球で表示する際の半径 DENDRITEが太い場合、シナプスは埋もれて見えなくなることがある

### NEURON用のパラメータ ###

COMP_MAX_SIZE                  <- 5.0                    #マルチコンパートメントモデルを作る際の1コンパートメントの最大サイズ

OUTPUT_MORPHO_FILE             <- "./output_morpho.hoc" #morphology用データ出力ファイル名
OUTPUT_SYNAPSE_FILE            <- "./output_synapse.hoc" #synapse用データ出力ファイル名

SOMA                           <- "soma"                # hocファイル出力で使用する名前
DEND                           <- "dend"                # hocファイル出力で使用する名前

UPPER_SYNAPSE                  <- "upperSyn"            # hocファイルに出力する名前
LOWER_SYNAPSE                  <- "lowerSyn"            # hocファイルに出力する名前

SYN_TYPE_NAME                  <- "test_syn"            # 自作した、テスト用のシナプスの名前


#================ PROGRAM TEST INIT ===============#
### 最終的にできるDendriteをすべてまとめて格納するlistとしてTREEを用いる ###
TREE <- list(NULL)
Params <- as.list(NULL)

for(i in 1:floor(runif(1,min = 1,max = 5))){
  #iはDENDRITEの色を表す 1が黒、2が赤でだいぶキモいDENDRITEになるので+2して3始まりにする
  Params[[i]] <- Param_init(i + 2)
}

