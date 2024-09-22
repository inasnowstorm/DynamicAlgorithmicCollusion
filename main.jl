using DataFrames, Plots

include("src/structs.jl")
include("src/init.jl")
include("src/training.jl")
include("src/data_management.jl")

tmax = Int64(2e6) #maximum time
n = 3 #number of firms
d = 100 #number of consumers

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

    #initialises the firm with firm variables
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

    #initialises the consumer with consumer variables
    consumers = Main.structs.consumer(
        0, #location
        2.0, #v (used as mean for normal distribution of value)
        2, #mu
        DataFrame(prices = [], profits = [], firm = [], location = []) #data
    )

    #initialises the model using the firm and consumer variables defined above
    world = init.def_model(
        n, #number of firms
        d, #number of consumers
        firms, #base firm
        consumers, #base consumer
        0.2, #standard deviation for normal distribution of value
        tmax, #number of iterations simulation runs for
        0.1, #movement parameter
        2, #number of prices above calculated optimal
        simtype #simulation type
    )

    #simulated the model and writes all data that was collected into CSV files
    world = training.simulate_model(world)
    data_management.iterated_write(world, scenario)

    #provides the number of bins that data should be sorted into
    bin_nums = 1000
    divider = tmax/bin_nums

    #creating a vector to use to only see 1000 data points, evenly spaced over time
    bins = Vector{Int64}(undef,0)
    for i in 0:((tmax/divider)-1)
        push!(bins, Int64((i+1)*divider))
    end

    #creates bins and colours for location plot
    bins = [1; bins]
    x = bins
    y = []
    colours = []

    #add consumer location data
    for c in world.consumers[1:10:100] #subset here just to reduce clutter
        push!(y, c.data.location[bins])
        push!(colours, :blue)
    end

    #adds firm location data
    for f in world.firms
        push!(y, vcat(fill.(f.location, length(bins))))
        push!(colours, :red)
    end

    #plot and save location data
    plot(x,y,title=string("consumer locations (", scenario, ")"), xlabel="t", ylabel="location", legend=false)
    savefig(string("figs/", scenario,"/consumer_locations(", scenario, ").png"))

    #similar to previous bins but this time bins act as a range (from 1 to 1000 for example)
    bins = Vector{Int64}(undef,0)
    for i in 0:((tmax/divider)-1)
        push!(bins, Int64((i*divider)+1))
        push!(bins, Int64((i+1)*divider))
    end

    #averages the data
    ave_world = data_management.average_data(world,bins)

    bins = Vector{Int64}(undef,0)
    for i in 0:((tmax/divider)-1)
        push!(bins, Int64((i+1)*divider))
    end

    #creates average price plot
    x = bins
    y = ave_world.data.average_prices
    plot(x,y,title=string("average price (", scenario, ")"), xlabel="t", ylabel="average price")
    savefig(string("figs/", scenario,"/average_price(", scenario, ").png"))

    #creates plots of profits and prices of individual firms
    for i in 1:n
        y = ave_world.firms[i].data.prices
        plot(x,y,title=string("firm ", i, " prices (", scenario, ")"), xlabel="t", ylabel="average price")
        savefig(string("figs/", scenario,"/firm", i, "_price(", scenario, ").png"))

        y = ave_world.firms[i].data.profits
        plot(x,y,title=string("firm ", i, " profits (", scenario, ")"), xlabel="t", ylabel="average profit")
        savefig(string("figs/", scenario,"/firm", i, "_profits(", scenario, ").png"))
    end

end
