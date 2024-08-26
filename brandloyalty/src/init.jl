module init

    using DataFrames, Distributions

    export def_model
    
    # define model, n is number of firms, d is number of consumers, tmax is when itertion ends
    function def_model(n::Int64, d::Int64, firms::Main.structs.firm, consumers::Main.structs.consumer, sd::Float64, tmax::Int64, move::Float64)::Main.structs.model
        model_firms = init_firms(firms, n, consumers.v)
        model_consumers = init_consumers(consumers, d, sd)
        world = Main.structs.model(
            model_firms,
            model_consumers,
            tmax,
            move,
            1,
            DataFrame(average_prices = [], total_profits = []),
            Int64.(ones(n)))
        return world
    end

    # initialises matrices for firms and places them around a circle with cirumference 1
    function init_firms(firms::Main.structs.firm, n::Int64, v::Float64)::Array{Main.structs.firm,1}
        model_firms = Array{Main.structs.firm,1}()
        firms.A = range(firms.c, v, length = firms.k)
        firms.Q = zeros(firms.k, firms.k, firms.k)
        for i in 0:(1/n):(1-1/n)
            firms.location = i
            push!(model_firms,deepcopy(firms))
        end
        return model_firms
    end

    # places d consumers around a circle with cirumference 1 and initialises their value of product using normal distribution
    function init_consumers(consumers::Main.structs.consumer, d::Int64, sd::Float64)::Array{Main.structs.consumer,1}
        model_consumers = Array{Main.structs.consumer,1}()
        dist = Normal(consumers.v, sd)
        for i in 0:(1/d):(1-1/d)
            consumers.location = i
            consumers.v = rand(dist)
            push!(model_consumers,deepcopy(consumers))
        end
        return model_consumers
    end

end