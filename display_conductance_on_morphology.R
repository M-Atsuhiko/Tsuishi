display_conductance_on_morphology <- function(TREE,conductance){

    #--- シミュレーション全体の状態を3次元空間状に図示する --#

  cat("========== CREATING NEURON ==========\n")
  
  # RGLの描画を行う際
  library("rgl")
  rgl.clear()

  #3次元軸の生成
  ## rgl.lines(c(-300,300),0,0,color="red")
  ## rgl.lines(0,c(UPPER_SYNAPTIC_ZONE_Y,LOWER_SYNAPTIC_ZONE_Y),0,color="red")
  ## rgl.lines(0,0,c(-300,300),color="red")
  ## rgl.texts(c(300,0,0),c(0,UPPER_SYNAPTIC_ZONE_Y,0),c(0,0,300),text=c("x","y","z"),color="blue")
  
#  display_synaptic_zone()

  max_conductance <- 0
  Stem_conductances <- c()
  
  if(conductance == "K_conductance") max_conductance <- K_MAX
  else if(conductance == "Ca_conductance") max_conductance <- Ca_MAX

                                        #somaの描画
  ratio <- 0
  rgl.spheres(c(0,0,0),radius = SOMA_DIAM/2,sides = 10,color=rgb(ratio,0,(1 - ratio)))#,texture = SOMA_TEXTURE)#

                                        #Dendriteの描画
  for(i in 1:length(TREE)){
    display_dendrite_conductance(TREE[[i]],BRANCH_COLOR,max_conductance,conductance)
  }
  
  #synapseの描画
  for(i in 1:length(TREE)){
    display_synapse(TREE[[i]])
  }

  display_Legend(max_conductance,conductance)
}

display_dendrite_conductance <- function(Dendrite,Color,max_conductance,conductance){
#  rgl.spheres(c(0,0,0),radius = SOMA_DIAM/2,color = "green",sides = 10)#somaの描画
  #somaとdendriteの間に隙間があるように見えるが、これはRGLの球の描画が荒いせい？

  for(i in 1:length(Dendrite)){
    Branch_coordinate <- Dendrite[[i]][["coordi"]]
    diam <- Dendrite[[i]][["diam"]]
    ratio <- Dendrite[[i]][[conductance]]/max_conductance
    #ratioにあわせて薄くする
    Dendrite_cyl <- cylinder3d(Branch_coordinate,closed = -2,radius = diam,sides = 100)
    #コンダクタンスが多いほど赤く、少ないほど青く表示する
    shade3d(Dendrite_cyl,color = rgb(ratio,0,(1 - ratio)),override=TRUE)
  }
}

display_Legend <- function(max_conductance,conductance){
  
  dense <- seq(0,max_conductance,length=100)

  x <- 100
  y <- 0
  z <- 0

  for(dence in dense){
    one_Legend <- cylinder3d(rbind(c(-x,y,z),c(-x,y + 1,z)),closed=-1,radius=5,sides=100)
    shade3d(one_Legend,color=rgb(dence/max_conductance,0,(1 - dence/max_conductance)),alpha=1)
    y <- y + 1
  }

  dense <- signif(dense,digits=2)
  rgl.texts(-(numeric(100) + 80),seq(1,100,length=10),numeric(length(dense)),dense[seq(1,100,length=10)],
            cex=1)
  rgl.texts(-80,110,0,text=paste(conductance,"[S/cm^2]"),cex=1)
}
