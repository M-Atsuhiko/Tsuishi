NEURON {
    POINT_PROCESS simulSyn
    RANGE tau1,tau2,tau_rise,e_syn,g_syn,i,a,fire_time,a,syn_del
    NONSPECIFIC_CURRENT i
}

UNITS {
    (nA) = (nanoamp)
    (mV) = (millivolt)
    (uS) = (microsiemens)
}

ASSIGNED {
    tau1 (ms)
    tau2 (ms)
    tau_rise (ms)
    e_syn (mV)
    g_syn (uS)
    i (nA)
    v (mV)
    fire_time (ms)
    syn_del (ms)
    B : Max value of 2exp
    a (uS):valiable for debug
}

INITIAL { : default value will be changed after "finitialize" functionb in hoc file
    : This setting is matched with Exp2Syn
:    tau_rise = 0.2
    tau2 = 2   : [ms]
    :    tau1 = tau_rise*tau2/(tau2 + tau_rise) : [ms]
    tau1 = 0.5
    e_syn = 0  : [mV] reverse potensial = zero is not proper?
    g_syn = 0.5*10^(-3)

    fire_time = 30
    syn_del = 10
    a = 0
    B = exp(-(log(2)/tau2)) - exp(-(log(2)/tau1)) : B effects result 
:    B = 1
}

BREAKPOINT {
    if(t > syn_del){
	i = ((exp(-(t - syn_del)/tau2) - exp(-(t - syn_del)/tau1))/B)*g_syn*(v - e_syn)
    }
}
