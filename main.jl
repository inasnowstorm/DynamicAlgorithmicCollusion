using DataFrames, Plots

include("src/structs.jl")
include("src/init.jl")
include("src/training.jl")
include("src/data_management.jl")

tmax = Int64(2e6) #maximum time
n = 2 #number of firms

#simulation type
#1 = default simulation
#2 = brand loyalty
#3 = boycotting1
#4 = boycotting2
#5 = boycotting3

for simtype in 1:5
    
    if simtype == 1
        scenario = string("default")
    elseif simtype == 2
        scenario = string("brandloyalty")
    elseif simtype == 3
        scenario = string("boycotting1")
    elseif simtype == 4
        scenario = string("boycotting2")
    elseif simtype == 5
        scenario = string("boycotting3")
    end

    firms = Main.structs.firm(
        1, #id
        0.15, #alpha
        4e-6, #beta
        0.95, #gamma
        1.0, #mc
        11, #k
        0, #location
        zeros(1), #A
        zeros(1,1,1), #Q
        DataFrame(prices = [], profits = []), #data
    )

    consumers = Main.structs.consumer(
        0, #location
        2.0, #v (used as mean for normal distribution of value)
        2, #mu
        DataFrame(prices = [], profits = [], firm = []), #data
    )

    world = init.def_model(
        n, #number of firms
        50, #number of consumers
        firms, #base firm
        consumers, #base consumer
        0.2, #standard deviation for normal distribution of value
        tmax, #number of iterations simulation runs for
        0.1, #movement parameter
        2, #number of prices above calculated optimal
        simtype #simulation type
    )

    world = training.simulate_model(world)
    data_management.iterated_write(world, scenario)

    bin_nums = 1000
    divider = tmax/bin_nums

    bins = Vector{Int64}(undef,0)
    for i in 0:((tmax/divider)-1)
        push!(bins, Int64((i*divider)+1))
        push!(bins, Int64((i+1)*divider))
    end

    world = data_management.average_data(world,bins)

    bins = Vector{Int64}(undef,0)
    for i in 0:((tmax/divider)-1)
        push!(bins, Int64((i+1)*divider))
    end

    x = bins
    y = world.data.average_prices
    plot(x,y,title=string("average price (", scenario, ")"), xlabel="t", ylabel="average price")
    savefig(string("figs/", scenario,"/average_price(", scenario, ").png"))

    y = world.firms[1].data.prices
    plot(x,y,title=string("firm 1 prices (", scenario, ")"), xlabel="t", ylabel="average price")
    savefig(string("figs/", scenario,"/firm1_price(", scenario, ").png"))

    y = world.firms[1].data.profits
    plot(x,y,title=string("firm 1 profits (", scenario, ")"), xlabel="t", ylabel="average profit")
    savefig(string("figs/", scenario,"/firm1_profits(", scenario, ").png"))

    y = world.firms[2].data.prices
    plot(x,y,title=string("firm 2 prices (", scenario, ")"), xlabel="t", ylabel="average price")
    savefig(string("figs/", scenario,"/firm2_price(", scenario, ").png"))

    y = world.firms[2].data.profits
    plot(x,y,title=string("firm 2 profits (", scenario, ")"), xlabel="t", ylabel="average profit")
    savefig(string("figs/", scenario,"/firm2_profits(", scenario, ").png"))

end