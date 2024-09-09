module structs

    using DataFrames

    mutable struct firm
        """set properties"""
        id::Int64                               # Identity number to keep track of individual firms
        alpha::Float64                          # Learning parameter
        beta::Float64                           # Randomisation parameter
        gamma::Float64                          # Discount factor
        mc::Float64                              # Marginal cost
        k::Int64                                # Dimension of the price grid
        location::Float64                       # Location on circle hotelling model

        """derived properties"""
        A::Array{Float64,1}                     # Action space
        Q::Array{Float64,3}                     # Q-matrix of the firm

        """memory"""
        data::DataFrame                         # Saves data associated with the simulation
    end

    mutable struct consumer
        """set properties"""
        location::Float64                       # Location on circle hotelling model
        v::Float64                                # Value of the product
        mu::Float64                             # Product differentiation/travelling cost

        """memory"""
        data::DataFrame                         # Saves data associated with the simulation
    end

    mutable struct model
        """set properties"""
        firms::Array{firm,1}                    # array of firms
        consumers::Array{consumer,1}            # array of consumers
        tmax::Int64                             # Iterations the model runs for
        move::Float64                           # Movement parameter
        simtype::Int64                          # provides the type of simulation used
        # simulation type, 1 = default simulation, 2 = brand loyalty, 3 = boycotting1, 4 = boycotting2, 5 = boycotting3

        """memory"""
        cur_t::Int64                                # Keeps track of what the current period is
        data::DataFrame                         # Saves data associated with the simulation
        s::Array{Int64,1}                       # Previous actions
    end
end