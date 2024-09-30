using DataFrames, Plots

include("src/structs.jl")
include("src/init.jl")
include("src/training.jl")
include("src/data_management.jl")

tmax = Int64(2e6) #maximum time,
n = 2 #number of firms, 
d = 100 #number of consumers
move = 0.1 #movement parameter (how far consumers move per period)

#simulation type
#1 = default simulation
#2 = brand loyalty
#3 = boycotting1
#4 = boycotting2
#5 = boycotting3

for simtype in 2:5
    
    test_name = string(",n=2,move=0.1")

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
        0.05, #alpha
        4e-6, #beta
        0.95, #gamma
        1.0, #mc
        11, #k
        0, #location
        zeros(1), #A
        zeros(1,1,1), #Q
        DataFrame(prices = [], profits = []) #data
    )

    consumers = Main.structs.consumer(
        0, #location
        2.0, #v (used as mean for normal distribution of value)
        2, #mu
        DataFrame(prices = [], profits = [], firm = [], location = []) #data
    )

    world = init.def_model(
        n, #number of firms
        d, #number of consumers
        firms, #base firm
        consumers, #base consumer
        0.2, #standard deviation for normal distribution of value
        tmax, #number of iterations simulation runs for
        move, #movement parameter
        2, #number of prices above calculated optimal
        simtype #simulation type
    )

    #trains and writes simulation
    world = training.simulate_model(world)
    data_management.iterated_write(world, scenario)

    #creates bins to split data into for easier processing
    bin_nums = 1000
    divider = tmax/bin_nums

    bins = Vector{Int64}(undef,0)
    for i in 0:((tmax/divider)-1)
        push!(bins, Int64((i+1)*divider))
    end

    bins = [1; bins]
    x = bins
    y = []
    colours = []

    for c in world.consumers[1:10:100] #subset here just to reduce clutter
        push!(y, c.data.location[bins])
        push!(colours, :blue)
    end

    for f in world.firms
        push!(y, vcat(fill.(f.location, length(bins))))
        push!(colours, :red)
    end

    plot(x,y[1],lc=colours[1],title=string("consumer locations (", scenario, test_name, ")"), xlabel="t", ylabel="location", legend=false)
    for i in 2:length(y)
        plot!(x,y[i],lc=colours[i])
    end
    savefig(string("figs/", scenario,"/consumer_locations(", scenario, ").png"))

    bins = Vector{Int64}(undef,0)
    for i in 0:((tmax/divider)-1)
        push!(bins, Int64((i*divider)+1))
        push!(bins, Int64((i+1)*divider))
    end

    #averaging data
    ave_world = data_management.average_data(world,bins)

    bins = Vector{Int64}(undef,0)
    for i in 0:((tmax/divider)-1)
        push!(bins, Int64((i+1)*divider))
    end

    #plotting and saving plots
    x = bins
    y = ave_world.data.average_prices
    plot(x,y,title=string("average price (", scenario, test_name, ")"), xlabel="t", ylabel="average price")
    savefig(string("figs/", scenario,"/average_price(", scenario, test_name, ").png"))

    y = ave_world.data.average_prices
    plot(x,y,title=string("average price (", scenario, test_name, ")"), xlabel="t", ylabel="average price")
    savefig(string("figs/", scenario,"/average_price(", scenario, test_name, ").png"))

    for i in 1:n
        y = ave_world.firms[i].data.prices
        plot(x,y,title=string("firm ", i, " prices (", scenario, test_name, ")"), xlabel="t", ylabel="average price")
        savefig(string("figs/", scenario,"/firm", i, "_price(", scenario, test_name, ").png"))

        y = ave_world.firms[i].data.profits
        plot(x,y,title=string("firm ", i, " profits (", scenario, test_name, ")"), xlabel="t", ylabel="average profit")
        savefig(string("figs/", scenario,"/firm", i, "_profits(", scenario, test_name, ").png"))
    end

end