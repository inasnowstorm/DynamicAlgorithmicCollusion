using DataFrames, Plots

include("src/structs.jl")
include("src/init.jl")
include("src/training.jl")
include("src/data_management.jl")

t = Int64(1e6)

firms = Main.structs.firm(
    1, #id
    0.15, #alpha
    2e-6, #beta
    0.95, #gamma
    1.0, #c
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
    3, #number of firms
    50, #number of consumers
    firms, #base firm
    consumers, #base consumer
    0.2, #standard deviation for normal distribution of value
    t #number of iterations simulation runs for
)

world = training.simulate_model(world)
data_management.iterated_write(world)

bin_nums = 1000
divider = t/bin_nums

bins = Vector{Int64}(undef,0)
for i in 0:((t/divider)-1)
    push!(bins, Int64((i*divider)+1))
    push!(bins, Int64((i+1)*divider))
end

world = data_management.average_data(world,bins)

bins = Vector{Int64}(undef,0)
for i in 0:((t/divider)-1)
    push!(bins, Int64((i+1)*divider))
end

x = bins
y = world.data.average_prices
plot(x,y,title="average price (default)", xlabel="t", ylabel="average price")
savefig("figs/average_price(default).png")

y = world.firms[1].data.prices
plot(x,y,title="firm 1 prices", xlabel="t", ylabel="average price")
savefig("figs/firm1_price(default).png")

y = world.firms[1].data.profits
plot(x,y,title="firm 1 profit", xlabel="t", ylabel="average profit")
savefig("figs/firm1_profit(default).png")

y = world.firms[2].data.prices
plot(x,y,title="firm 2 prices", xlabel="t", ylabel="average price")
savefig("figs/firm2_price(default).png")

y = world.firms[2].data.profits
plot(x,y,title="firm 2 profit", xlabel="t", ylabel="average profit")
savefig("figs/firm2_profit(default).png")

y = world.firms[3].data.prices
plot(x,y,title="firm 3 prices", xlabel="t", ylabel="average price")
savefig("figs/firm3_price(default).png")

y = world.firms[3].data.profits
plot(x,y,title="firm 3 profit", xlabel="t", ylabel="average profit")
savefig("figs/firm3_profit(default).png")
