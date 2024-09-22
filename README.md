# DynamicAlgorithmicCollusion

Replication of "Artificial Intelligence, Algorithmic Pricing, and Collusion" by Calvano, Calzolari, Denicolò, Pastorello (2020) in Julia with significant changes to change the model for consumers and allow for brand loyalty and boycotting scenarios.

Based on code uploaded by Matteo Courthoud (2021) URL: https://github.com/matteocourthoud/Algorithmic-Collusion-Replication

Agents now have their decisions made independently of each other and consumers move according to specific rules, depending on the scenario.

To run, simply open julia the main directory and run 'include("main.jl")'

Ensure you make directories of the following style to allow for figures and data to be written:\
figs/*scenarioname*/\
data/*scenarioname*/
