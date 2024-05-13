
param nPeriods >= 1 default 8760;   

# Sets
set T = {1..nPeriods} ordered; #time
set G; #generator
set S; #storage
set N; #nuclear

# General parameters
#param length{T};
param demand{T};
param power_viol_penalty >= 0 default 10000;

# Generator parameters
param operating_cost{G};
param social_cost{G};
param invest_cost_g{G};
param availability{T,G} >=0, <=1, default 1;

# Storage parameters
param invest_cost_s{S};
param storage_init_charge{S}>=0, default 0;
param storage_duration{S}>= 0, default 4;
param discharge_coef{S}>=0, <=1, default .93;
param charge_coef{S}>=0, <=1, default .93;

#Nuclear parameters
param fixed_cost_n{N}; #existing nuclear fixed cost
param operating_cost_n{N}; #existing nuclear op cost
param capacity_n_existing{N}; #existing nuclear capacity

# Variables
var capacity_g{g in G} >= 0;
var capacity_s{s in S} >=0;
var capacity_n{n in N} >= 0; #how much existing nuclear to activate
var output_gt{g in G, t in T} >= 0;
var output_nt{n in N, t in T} >=0; #existing nuclear output per t
var discharge_st{s in S, t in T} >=0;
var charge_st{s in S, t in T} >=0;
var SOC_st{s in S, t in T} >=0;
var slack_t{t in T}>=0;
var surplus_t{t in T}>=0;

# Objective function
minimize total_cost:
    (sum{g in G, t in T} ((operating_cost[g]+social_cost[g])*output_gt[g,t]))+
    (sum{g in G} (invest_cost_g[g]*capacity_g[g]))+
    (sum{n in N}(fixed_cost_n[n]*capacity_n[n]))+
    (sum{n in N, t in T}(operating_cost_n[n]*output_nt[n,t]))+
    (sum{t in T} power_viol_penalty*(slack_t[t]+surplus_t[t]))+
    (sum{s in S} (invest_cost_s[s]*capacity_s[s]));
    
# Constraints

s.t. existing_nuclear_capacity{n in N}:
capacity_n[n]<=capacity_n_existing[n];

# generator availability
s.t. power_output{g in G, t in T}:
output_gt[g,t]<=availability[t,g]*capacity_g[g];

s.t. nuclear_output{n in N, t in T}:
output_nt[n,t]<=capacity_n[n];

# demand / system balance
s.t. meet_demand{t in T}:
#sum{g in G}(output_gt[g,t])+(sum{s in S}(discharge_st[s,t]-charge_st[s,t]))+slack_t-surplus_t[t]=demand_t[t];
(sum{g in G} output_gt[g,t]) +(sum{s in S} (discharge_st[s,t]-charge_st[s,t]))+(sum{n in N} output_nt[n,t])+slack_t[t]-surplus_t[t] = demand[t];

# max storage charge
s.t. max_charge{s in S, t in T}:
charge_st[s,t]<=capacity_s[s];

# max storage discharge
s.t. max_discharge{s in S, t in T}:
discharge_st[s,t]<=capacity_s[s];

# storage SOC consistency
s.t. battery_state_of_charge_first_instance{s in S, t in {first(T)}}:
SOC_st[s,t]-storage_init_charge[s]+discharge_st[s,t]/discharge_coef[s]-charge_coef[s]*charge_st[s,t]=0;

s.t. battery_state_of_charge{s in S, t in T diff{first(T)}}:
SOC_st[s,t]-SOC_st[s,t-1]+discharge_st[s,t]/discharge_coef[s]-charge_coef[s]*charge_st[s,t]=0;

s.t. max_storage_capacity{s in S, t in T}:
SOC_st[s,t]<=storage_duration[s]*capacity_s[s];

# exsiting capacities
s.t. current_capacity_solar{g in G}:
capacity_g['SOLAR']>=4400;

s.t. current_capacity_wind{g in G}:
capacity_g['WIND']>=2500;
