module training

    using Statistics

    export simulate_model

    # Simulates the model
    function simulate_model(model::Main.structs.model)::Main.structs.model
        # Iterate until convergence
        for t in 1:model.tmax
            a = get_actions(model)
            p = Float64.(zeros(length(a)))
            for i in eachindex(p)
                p[i] = (model.firms[i]).A[a[i]]
            end
            d, c_profit, c_prices = get_demand(model, p)
            for n in eachindex(d)
                push!((model.consumers[n]).data, (c_prices[n], c_profit[n], d[n]))
            end
            profits = get_profits(model, d, p)
            for n in eachindex(model.firms)
                push!(model.firms[n].data, (p[n],profits[n]))
                (model.firms[n]).Q = update_Q(model, n, profits, a)
            end
            push!(model.data, (mean(p),(sum(profits) + sum(c_profit))))
            model.consumers = loyal_move(model, d)
            model.s = a
            model.t += 1
        end
        return model
    end

    # Gets the actions for an iteration, partially through random chance, partially through Q function
    function get_actions(model::Main.structs.model)::Array{Int64,1}
        """Get actions"""
        a = Int64.(zeros(length(model.firms)))
        for n in eachindex(a)
            pr_explore = exp(- model.t * (model.firms)[n].beta)
            e = pr_explore > rand()
            if e
                a[n] = rand(1:(model.firms)[n].k)
            else
                other_s = Int64.(my_round(mean(model.s[1:end .!=n])))
                a[n] = argmax(((model.firms[n]).Q)[model.s[n], other_s, :])
            end
        end
        return a
    end

    # Gets the demands for an iteration given the prices of the firms
    function get_demand(model::Main.structs.model, p::Array{Float64,1})::Tuple{Array{Int64,1}, Array{Float64,1}, Array{Float64,1}}
        n = length(model.firms)
        d = Int64.(zeros(length(model.consumers)))
        c_profit = Float64.(zeros(length(model.consumers)))
        c_prices = Float64.(zeros(length(model.consumers)))
        for c in eachindex(d)
            dist = zeros(n)
            for i in 1:n
                dist[i] = min(abs((model.consumers[c]).location - (model.firms[i]).location), 1 - abs((model.consumers[c]).location - (model.firms[i]).location))
            end
            profit = (model.consumers[c]).v .- p .- ((model.consumers[c]).mu * dist)
            if maximum(profit) >= 0
                d[c] = findmax(profit)[2]
                c_profit[c] = maximum(profit)
                c_prices[c] = p[d[c]]
            end
        end
        return d, c_profit, c_prices
    end

    # Returns the profits that each firm gets 
    function get_profits(model::Main.structs.model, d::Array{Int64,1}, p::Array{Float64,1})::Array{Float64,1}
        profits = Float64.(zeros(length(p)))
        for i in eachindex(profits)
            profits[i] = count(==(i),d) * (p[i] - (model.firms[i]).c)
        end
        return profits
    end

    function update_Q(model::Main.structs.model, n::Int64, profits::Array{Float64,1}, a::Array{Int64,1})::Array{Float64,3}
        """Update Q function"""
        other_s = Int64.(my_round(mean(model.s[1:end .!=n])))
        other_a = Int64.(my_round(mean(a[1:end .!=n])))
        old_value = (model.firms[n]).Q[model.s[n], other_s, a[n]]
        max_q = max((model.firms[n]).Q[a[n], other_a, :]...)
        new_value = profits[n] + (model.firms[n]).gamma * max_q
        (model.firms[n]).Q[model.s[n], other_s, a[n]] = (1 - (model.firms[n]).alpha) * old_value + (model.firms[n]).alpha * new_value
        return (model.firms[n]).Q
    end

    function loyal_move(model::Main.structs.model, d::Array{Int64,1})::Array{Main.structs.consumer,1}
        for i in eachindex(d)
            if d[i] != 0
                l1 = model.consumers[i].location
                l2 = model.firms[d[i]].location
                dist1 = abs(l1 - l2)
                dist2 = 1 - abs(l1 - l2)
                if dist1 > dist2 && l1 > l2
                    model.consumers[i].location = (l1 * (1-model.move)) + (dist2 * model.move)
                elseif dist1 > dist2 && l1 < l2
                    model.consumers[i].location = (l1 * (1-model.move)) - (dist2 * model.move)
                elseif dist1 < dist2 && l1 > l2
                    model.consumers[i].location = (l1 * (1-model.move)) - (dist1 * model.move)
                elseif dist1 < dist2 && l1 > l2
                    model.consumers[i].location = (l1 * (1-model.move)) + (dist1 * model.move)
                else
                    e = rand() > 0.5
                    if e
                        model.consumers[i].location = (l1 * (1-model.move)) + (dist1 * model.move)
                    else
                        model.consumers[i].location = (l1 * (1-model.move)) - (dist1 * model.move)
                    end
                end
                if model.consumers[i].location < 0
                    model.consumers[i].location = model.consumers[i].location + 1
                elseif model.consumers[i].location > 1
                    model.consumers[i].location = model.consumers[i].location - 1
                end
            end
        end
        return model.consumers
    end

    # Rounding function needed as inbuilt round function would lead to situations where round(4.5)=4
    function my_round(n::Float64)::Float64
        if n >= floor(n)+0.5
            return floor(n)+1
        else
            return floor(n)
        end
    end

end