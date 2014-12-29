source("Tsuishi_Dendritic_function_parameter.R")
source("plot_func.R")

par(lwd=3,
    cex=1.4,
    mex=1.2)

output_dir <- "./Tsuishi_Result/"

WITH_K <- FALSE
WITH_Ca <- FALSE

RAND_SEED <- 1:4
DELTA_T <- seq(5,15,by=5)
Function_ratio <- 70
Conductance_ratio <- 0
Morphology_ratio <- 100 - (Function_ratio + Conductance_ratio)
extra_prefix <- paste("Tsuishi_liner_",Function_ratio,"_",Conductance_ratio,sep="")

if(WITH_K*WITH_Ca){
  name <- "k_ca"
}else if(WITH_K){
  name <- "k"
}else if(WITH_Ca){
  name <- "ca"
}else name <- "passive"

cat("inciude conductance:",name,"\n")

Data_Dir <- paste("./",name,"_Result/",sep="")

Datas <- as.list(NULL)

Fs <- c()
TREE_length <- c()
TREE_volume <- c()
N_Upper_Syn <- c()
N_Lower_Syn <- c()

for(dt in DELTA_T){
  cat("Delta_T:",dt,"\n")
  Data_i <- 1
  for(sd in RAND_SEED){
    cat("SEED:",sd,"\n")
    input_filename <- paste(Data_Dir,"SEED",sd,"_","dt",dt,"_",paste(name,collapse="_"),"_",paste("FR",Function_ratio,sep=""),"_",extra_prefix,"_Best_Datas.xdr",sep="")
    cat("input file:",input_filename,"\n")
    load(input_filename)
    Datas[[Data_i]] <- Best_Datas[[length(Best_Datas)]]
    Data_i <- Data_i + 1
  }

  Fs <- cbind(Fs,
              sapply(Datas,"[[","Ratio"))
  
  TREE_length <- cbind(TREE_length,
                       sapply(lapply(Datas,"[[","TREE"),sum_length))


  TREE_volume <- cbind(TREE_volume,
                       sapply(lapply(Datas,"[[","TREE"),calc_volume))

  N_Upper_Syn <- cbind(N_Upper_Syn,
                       sapply(lapply(Datas,"[[","TREE"),
                              function(TREE){
                                Dends <- set_Upper_or_Lower_or_Other(TREE)[["Upper_Dend"]]
                                return(sum(sapply(Dends,function(Dend){
                                  return(sum(sapply(Dend,function(Branch){
                                    if(is.matrix(Branch[["synapse"]])) return(nrow(Branch[["synapse"]]))
                                    else return(0)
                                    })))
                                  })))
                              }))

  N_Lower_Syn <- cbind(N_Lower_Syn,
                       sapply(lapply(Datas,"[[","TREE"),
                              function(TREE){
                                Dends <- set_Upper_or_Lower_or_Other(TREE)[["Lower_Dend"]]
                                return(sum(sapply(Dends,function(Dend){
                                  return(sum(sapply(Dend,function(Branch){
                                    if(is.matrix(Branch[["synapse"]])) return(nrow(Branch[["synapse"]]))
                                    else return(0)
                                    })))
                                  })))
                              }))
}

rowname <- expression(paste("Optimized ",Delta,"t [ms]"))

legend <- c()

output_dir <- paste(output_dir,"F",Function_ratio,"_",sep="")

colname <- "F"
Filename <- paste(output_dir,"Fs.eps",sep="")
color <- c("red")
plot_func(list(Fs),color,DELTA_T,Filename,
          colname,
          rowname,
          legend)

colname <- expression(paste("TREE Length [",mu,"m]"))
Filename <- paste(output_dir,"TREE_length.eps",sep="")
color <- c("red")
plot_func(list(TREE_length),color,DELTA_T,Filename,
          colname,
          rowname,
          legend)

colname <- expression(paste("TREE Volume [",mu,m^3,"]"))
Filename <- paste(output_dir,"TREE_volume.eps",sep="")
color <- c("red")
plot_func(list(TREE_volume),color,DELTA_T,Filename,
          colname,
          rowname,
          legend)

colname <-paste("Number of Synapses")
Filename <- paste(output_dir,"Number_synapse.eps",sep="")
color <- c("red","blue")
legend <- cbind(c("Red Synapse","Blue Synapse"),
                c("red","blue"),
                c("solid","solid"))
plot_func(list(N_Upper_Syn,N_Lower_Syn),color,DELTA_T,Filename,
          colname,
          rowname,
          legend)

