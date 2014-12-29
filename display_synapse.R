display_synapse <- function(Dendrite){
  for(Branch in Dendrite){
    synapse_matrix <- Branch[["synapse"]]
    if(is.matrix(synapse_matrix)){
      Branch_coordi <- Branch[["coordi"]]
      for(rn in 1:nrow(synapse_matrix)){
        synapse_position_ratio <- synapse_matrix[rn,1]
        synaptic_zone<- synapse_matrix[rn,2]

        synapse_coordi <-(Branch_coordi[2,] - Branch_coordi[1,])*synapse_position_ratio + Branch_coordi[1,]
          
        if(synaptic_zone == UPPER_SYNAPTIC_ZONE_INDEX){        #UPPER SYNAPTIC ZONE
          rgl.spheres(synapse_coordi,radius = SYNAPSE_RADIUS,sides = 10,color = UPPER_SYNAPTIC_ZONE_COLOR)
        }else if(synaptic_zone == LOWER_SYNAPTIC_ZONE_INDEX){  #LOWER SYNAPTIC ZONE
          rgl.spheres(synapse_coordi,radius = SYNAPSE_RADIUS,sides = 10,color = LOWER_SYNAPTIC_ZONE_COLOR)
        }
      }
    }
  }
}

