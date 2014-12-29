divid_and_set_conductance_liner <- function(TREE,Params){
  New_TREE <- as.list(NULL)
  for(TREE_i in 1:length(TREE)){
    Dendrite <- TREE[[TREE_i]]

    New_Dendrite <- as.list(NULL)
    N_New <- 1
    N_Branch <- length(Dendrite)
      
    Nsegs <- sapply(Dendrite,"[[","nseg")
                                        #Branchを細分化したときの新しいNoの組をあらかじめ与えておく
    New_mx <- cbind(1:N_Branch,
                    sapply(1:N_Branch,function(i){
                      return(sum(Nsegs[c(rep(TRUE,(i - 1)),rep(FALSE,(N_Branch - (i - 1))))]) + 1)
                    }),
                    sapply(1:N_Branch,function(i){
                      return(sum(Nsegs[1:i]))
                    }))
    
    for(Branch in Dendrite){
      No <- Branch[["No"]]
      nseg <- Branch[["nseg"]]
      length <- Branch[["length"]]
      elevation <- Branch[["elevation"]]
      rotation <- Branch[["rotation"]]
      my_diam <- Branch[["diam"]]
      path_leng <- Branch[["path_leng"]]
      parent <- Branch[["parent"]]
      connect <- Branch[["connect"]]
      coordi <- Branch[["coordi"]]
      synapse <- Branch[["synapse"]]

      K_conductance <- Branch[["K_conductance"]]
      Ca_conductance <- Branch[["Ca_conductance"]]

      seg_vect <- (coordi[2,] - coordi[1,])/nseg

      if(parent == -1){
        parent_diam <- my_diam
        parent_path <- 0
      }else{
        parent_diam <- Dendrite[[parent]][["diam"]]
        parent_path <- Dendrite[[parent]][["path_leng"]]
      }
      
      seg_attenuate <- (my_diam - parent_diam)/nseg
      seg_leng <- length/nseg

      if(is.matrix(synapse)){#あらかじめシナプスをつけるセグメントを計算しておく
        new_synapse <- as.list(NULL)
        synapse <- rbind(synapse,c(1,-1))
        synapse_i <- 1
        for(i in 1:nseg){
          if(i/nseg > synapse[synapse_i,1] && i/nseg <= synapse[synapse_i + 1,1]){
            new_synapse[[i]] <- matrix(c(0.5,synapse[synapse_i,2]),nrow=1)
            synapse_i <- synapse_i + 1
          }else{
            new_synapse[[i]] <- -1
          }
        }
      }else{
        new_synapse <- lapply(1:nseg,function(i) return(-1))
      }

      for(i in 1:nseg){
        if(i == 1){
          seg_elevation <- elevation
          seg_rotation <- rotation
          if(parent == -1) New_parent <- -1
          else New_parent <- New_mx[parent,3]
        }else{
          seg_elevation <- 0
          seg_rotation <- 0
          New_parent <- N_New - 1
        }

        if(i == nseg){
          if(connect[1] == 0)
            New_connect <- 0
          else{
            New_connect <- New_mx[connect,2]
          }
        }else{
          New_connect <- N_New + 1
        }

        my_path <- parent_path + seg_leng*i

        new_seg <- list(N_New,
                        seg_leng,
                        seg_elevation,
                        seg_rotation,
                        parent_diam + seg_attenuate*i,
                        my_path,
                        New_parent,
                        New_connect,
                        rbind(coordi[1,] + seg_vect*(i - 1),
                              coordi[1,] + seg_vect*i),
                        1,
                        new_synapse[[i]],
                        K_conductance,
                        Ca_conductance
                        )
        names(new_seg) <- Segment_Labels
        New_Dendrite[[N_New]] <- new_seg
        N_New <- N_New + 1
      }
    }
    New_TREE[[TREE_i]] <- New_Dendrite
  }
  return(New_TREE)
}
