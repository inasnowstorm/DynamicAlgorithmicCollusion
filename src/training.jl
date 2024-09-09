module training

    using Statistics

    export simulate_model

    #simulates the model
    function simulate_model(model::Main.structs.model)::Main.structs.model
        #iterates until max time is reached
        for t in 1:model.tmax
            a = get_actions(model) #provides the actions for that period
            p = Float64.(zeros(length(a))) #creates a blank price schedule
            for i in eachindex(p)
                p[i] = (model.firms[i]).A[a[i]] #replaces price schedule with actions
            end
            d, c_profit, c_prices = get_demand(model, p) #gets demand and the price each consumer paid, as well as their profit
            for n in eachindex(d)
                push!((model.consumers[n]).data, (c_prices[n], c_profit[n], d[n], model.consumers[n].location)) #saves consumer data
            end
            profits = get_profits(model, d, p) #gets the profits for firms given the consumer actions and prices firms chose
            for n in eachindex(model.firms)
                push!(model.firms[n].data, (p[n],profits[n])) #saves firm data
                (model.firms[n]).Q = update_Q(model, n, profits, a) #updates the Q matrix
            end
            push!(model.data, (mean(p),(sum(profits) + sum(c_profit)))) #saves model data
            #moves consumers if scenario is a scenario involving movement
            if model.simtype == 2
                model.consumers = loyal_move(model, d)
            elseif model.simtype == 3
                model.consumers = boycott1_move(model, p)
            elseif model.simtype == 4
                model.consumers = boycott2_move(model, p)
            elseif model.simtype == 5
                if model.cur_t != 1
                    model.consumers = boycott3_move(model)
                end
            end
            model.s = a #current actions are saved as previous actions
            model.cur_t += 1 #increase time period by 1
        end
        return model
    end

    # Gets the actions for an iteration, partially through random chance, partially through Q function
    function get_actions(model::Main.structs.model)::Array{Int64,1}
        """Get actions"""
        a = Int64.(zeros(length(model.firms))) #provides empty actions array
        for n in eachindex(a)
            pr_explore = exp(- model.cur_t * (model.firms)[n].beta) #probability to do a random action
            e = pr_explore > rand()
            if e
                a[n] = rand(1:(model.firms)[n].k) #chooses random action
            else
                other_s = Int64.(my_round(mean(model.s[1:end .!=n]))) #takes average of other firm previous choices
                a[n] = argmax(((model.firms[n]).Q)[model.s[n], other_s, :]) #uses Q matrix to provide new acton
            end
        end
        return a
    end

    # Gets the demands for an iteration given the prices of the firms and distance between consumers and firms
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

    #returns the profits that each firm gets 
    function get_profits(model::Main.structs.model, d::Array{Int64,1}, p::Array{Float64,1})::Array{Float64,1}
        profits = Float64.(zeros(length(p)))
        for i in eachindex(profits)
            profits[i] = count(==(i),d) * (p[i] - (model.firms[i]).mc)
        end
        return profits
    end

    #updates Q matrix
    function update_Q(model::Main.structs.model, n::Int64, profits::Array{Float64,1}, a::Array{Int64,1})::Array{Float64,3}
        other_s = Int64.(my_round(mean(model.s[1:end .!=n])))
        other_a = Int64.(my_round(mean(a[1:end .!=n])))
        old_value = (model.firms[n]).Q[model.s[n], other_s, a[n]]
        max_q = max((model.firms[n]).Q[a[n], other_a, :]...)
        new_value = profits[n] + (model.firms[n]).gamma * max_q
        (model.firms[n]).Q[model.s[n], other_s, a[n]] = (1 - (model.firms[n]).alpha) * old_value + (model.firms[n]).alpha * new_value
        return (model.firms[n]).Q
    end

    # different types of movement
    # for brand loyalty scenario, move consumers closer to their chosen firm
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

    # for boycotting1 scenario, moves consumers away from firm with highest price.
    function boycott1_move(model::Main.structs.model, p::Array{Float64,1})::Array{Main.structs.consumer,1}
        max_p = findmax(p)
        if count(==(max_p[1]),p) != 1
            return model.consumers
        end
        if model.firms[max_p[2]].location >= 0.5
            l2 = model.firms[max_p[2]].location - 0.5
        else
            l2 = model.firms[max_p[2]].location + 0.5
        end
        for c in model.consumers
            l1 = c.location
            dist1 = abs(l1 - l2)
            dist2 = 1 - abs(l1 - l2)
            if dist1 > dist2 && l1 > l2
                c.location = (l1 * (1-model.move)) + (dist2 * model.move)
            elseif dist1 > dist2 && l1 < l2
                c.location = (l1 * (1-model.move)) - (dist2 * model.move)
            elseif dist1 < dist2 && l1 > l2
                c.location = (l1 * (1-model.move)) - (dist1 * model.move)
            elseif dist1 < dist2 && l1 > l2
                c.location = (l1 * (1-model.move)) + (dist1 * model.move)
            else
                e = rand() > 0.5
                if e
                    c.location = (l1 * (1-model.move)) + (dist1 * model.move)
                else
                    c.location = (l1 * (1-model.move)) - (dist1 * model.move)
                end
            end
            if c.location < 0
                c.location = c.location + 1
            elseif c.location > 1
                c.location = c.location - 1
            end
        end
        return model.consumers
    end

    # for boycotting2 scenario, moves away from firm with the largest price hike
    function boycott2_move(model::Main.structs.model, p2::Array{Float64,1})::Array{Main.structs.consumer,1}
        p1 = Float64.(zeros(length(p2)))
        for i in eachindex(p1)
            p1[i] = (model.firms[i]).A[model.s[i]]
        end
        p = p2 .- p1
        max_p = findmax(p)
        if count(==(max_p[1]),p) != 1
            return model.consumers
        end
        if model.firms[max_p[2]].location >= 0.5
            l2 = model.firms[max_p[2]].location - 0.5
        else
            l2 = model.firms[max_p[2]].location + 0.5
        end
        for c in model.consumers
            l1 = c.location
            dist1 = abs(l1 - l2)
            dist2 = 1 - abs(l1 - l2)
            if dist1 > dist2 && l1 > l2
                c.location = (l1 * (1-model.move)) + (dist2 * model.move)
            elseif dist1 > dist2 && l1 < l2
                c.location = (l1 * (1-model.move)) - (dist2 * model.move)
            elseif dist1 < dist2 && l1 > l2
                c.location = (l1 * (1-model.move)) - (dist1 * model.move)
            elseif dist1 < dist2 && l1 > l2
                c.location = (l1 * (1-model.move)) + (dist1 * model.move)
            else
                e = rand() > 0.5
                if e
                    c.location = (l1 * (1-model.move)) + (dist1 * model.move)
                else
                    c.location = (l1 * (1-model.move)) - (dist1 * model.move)
                end
            end
            if c.location < 0
                c.location = c.location + 1
            elseif c.location > 1
                c.location = c.location - 1
            end
        end
        return model.consumers
    end

    # for boycotting3 scenario, moves away from firm if their price is larger than the previous price the consumer bought from
    function boycott3_move(model::Main.structs.model)::Array{Main.structs.consumer,1}
        for c in model.consumers
            p1 = c.data.prices[size(c.data)[1]-1]
            p2 = c.data.prices[size(c.data)[1]]
            if p2 > p1
                l1 = c.location
                f = c.data.firm[size(c.data)[1]]
                if model.firms[f].location >= 0.5
                    l2 = model.firms[f].location - 0.5
                else
                    l2 = model.firms[f].location + 0.5
                end
                dist1 = abs(l1 - l2)
                dist2 = 1 - abs(l1 - l2)
                if dist1 > dist2 && l1 > l2
                    c.location = (l1 * (1-model.move)) + (dist2 * model.move)
                elseif dist1 > dist2 && l1 < l2
                    c.location = (l1 * (1-model.move)) - (dist2 * model.move)
                elseif dist1 < dist2 && l1 > l2
                    c.location = (l1 * (1-model.move)) - (dist1 * model.move)
                elseif dist1 < dist2 && l1 > l2
                    c.location = (l1 * (1-model.move)) + (dist1 * model.move)
                else
                    e = rand() > 0.5
                    if e
                        c.location = (l1 * (1-model.move)) + (dist1 * model.move)
                    else
                        c.location = (l1 * (1-model.move)) - (dist1 * model.move)
                    end
                end
                if c.location < 0
                    c.location = c.location + 1
                elseif c.location > 1
                    c.location = c.location - 1
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