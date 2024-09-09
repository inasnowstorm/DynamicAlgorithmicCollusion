module init

    using DataFrames, Distributions

    export def_model
    
    # define model, n is number of firms, d is number of consumers, tmax is when itertion ends
    function def_model(n::Int64, d::Int64, firms::Main.structs.firm, consumers::Main.structs.consumer, sd::Float64, tmax::Int64, move::Float64, kabove::Int64, simtype::Int64)::Main.structs.model
        model_consumers = init_consumers(consumers, d, sd)
        model_firms = init_firms(firms, n, consumers.v, d, consumers.mu, kabove)
        world = Main.structs.model(
            model_firms,
            model_consumers,
            tmax,
            move,
            simtype,
            1,
            DataFrame(average_prices = [], total_profits = []),
            Int64.(ones(n)))
        return world
    end

    # initialises matrices for firms and places them around a circle with cirumference 1
    function init_firms(firms::Main.structs.firm, n::Int64, v::Float64, d::Int64, mu::Float64, kabove::Int64)::Array{Main.structs.firm,1}
        model_firms = Array{Main.structs.firm,1}()
        firms.Q = zeros(firms.k, firms.k, firms.k)
        for i in 0:(1/n):(1-1/n)
            firms.location = i
            push!(model_firms,deepcopy(firms))
        end
        actions = init_actions(n, v, d, firms.mc, mu, firms.k, kabove)
        for i in model_firms
            i.A = actions
        end
        return model_firms
    end

    #produces the action schedule based on optimal price (where profits are maximised) and then goes slightly above that optimum
    function init_actions(n::Int64, v::Float64, d::Int64, mc::Float64, mu::Float64, k::Int64, kabove::Int64)::Array{Float64,1}
        distances = (1/d):(1/d):(floor(d/(2n))/d)
        max_prices = v .- (mu .* distances)
        prices = mc:((v-mc)/100):v
        profits = []
        for p in prices
            push!(profits, (p - mc) * 2 * count(i->(i>=p),max_prices))
        end
        max_k = prices[argmax(profits)]
        delta = (max_k-mc)/(k-kabove-1)
        actions = mc:delta:(max_k+2*delta)
        return actions
    end

    # places d consumers around a circle with cirumference 1 and initialises their value of product using normal distribution
    function init_consumers(consumers::Main.structs.consumer, d::Int64, sd::Float64)::Array{Main.structs.consumer,1}
        model_consumers = Array{Main.structs.consumer,1}()
        dist = Normal(consumers.v, sd) #creates a normally distributed value for consumers.
        for i in 0:(1/d):(1-1/d)
            consumers.location = i
            consumers.v = rand(dist)
            push!(model_consumers,deepcopy(consumers))
        end
        return model_consumers
    end

end