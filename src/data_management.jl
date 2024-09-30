module data_management

    using CSV, DataFrames, Statistics, StatsBase

    export iterated_write, average_data

    function iterated_write(model::Main.structs.model, directory)
        for i in 1:10:length(model.consumers) #only tracking every 10th to save on space
            CSV.write(string("data/", directory,"/consumer_data", i, ".csv"), model.consumers[i].data)
        end
        for i in 1:length(model.firms)
            
            CSV.write(string("data/", directory,"/firm_data", i, ".csv"), model.firms[i].data)
        end
        CSV.write(string("data/", directory,"/world_data.csv"), model.data)
    end

    function average_data(model::Main.structs.model, bins::Vector{Int64})::Main.structs.model
        for i in 1:length(model.consumers)
            new_data = DataFrame(prices = [], profits = [], firm = [], location = [])
            for j in 1:(length(bins)/2)
                push!(new_data,(mean(model.consumers[i].data.prices[bins[Int64(2j-1)]:bins[Int64(2j)]]),mean(model.consumers[i].data.profits[bins[Int64(2j-1)]:bins[Int64(2j)]]),mode(model.consumers[i].data.firm[bins[Int64(2j-1)]:bins[Int64(2j)]]),mean(model.consumers[i].data.location[bins[Int64(2j-1)]:bins[Int64(2j)]])))
            end
            model.consumers[i].data = new_data
        end
        for i in 1:length(model.firms)
            new_data = DataFrame(prices = [], profits = [])
            for j in 1:(length(bins)/2)
                push!(new_data,(mean(model.firms[i].data.prices[bins[Int64(2j-1)]:bins[Int64(2j)]]),mean(model.firms[i].data.profits[bins[Int64(2j-1)]:bins[Int64(2j)]])))
            end
            model.firms[i].data = new_data
        end
        new_data = DataFrame(average_prices = [], total_profits = [])
        for j in 1:(length(bins)/2)
            push!(new_data,(mean(model.data.average_prices[bins[Int64(2j-1)]:bins[Int64(2j)]]),mean(model.data.total_profits[bins[Int64(2j-1)]:bins[Int64(2j)]])))
        end
        model.data = new_data
        return model
    end

end