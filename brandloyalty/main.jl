using DataFrames, Plots

include("src/structs.jl")
include("src/init.jl")
include("src/training.jl")
include("src/data_management.jl")

tmax = Int64(1e6)

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
    tmax, #number of iterations simulation runs for
    0.1 #movement parameter
)

world = training.simulate_model(world)
data_management.iterated_write(world)

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
plot(x,y,title="average price (brandloyalty)", xlabel="t", ylabel="average price")
savefig("figs/average_price(brandloyalty).png")

y = world.firms[1].data.prices
plot(x,y,title="firm 1 prices (brandloyalty)", xlabel="t", ylabel="average price")
savefig("figs/firm1_price(brandloyalty).png")

y = world.firms[1].data.profits
plot(x,y,title="firm 1 profit (brandloyalty)", xlabel="t", ylabel="average profit")
savefig("figs/firm1_profit(brandloyalty).png")

y = world.firms[2].data.prices
plot(x,y,title="firm 2 prices (brandloyalty)", xlabel="t", ylabel="average price")
savefig("figs/firm2_price(brandloyalty).png")

y = world.firms[2].data.profits
plot(x,y,title="firm 2 profit (brandloyalty)", xlabel="t", ylabel="average profit")
savefig("figs/firm2_profit(brandloyalty).png")

y = world.firms[3].data.prices
plot(x,y,title="firm 3 prices (brandloyalty)", xlabel="t", ylabel="average price")
savefig("figs/firm3_price(brandloyalty).png")

y = world.firms[3].data.profits
plot(x,y,title="firm 3 profit (brandloyalty)", xlabel="t", ylabel="average profit")
savefig("figs/firm3_profit(brandloyalty).png")
