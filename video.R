# Script recorded for the Indiana R Hector workshop video series 

## Set Up #######################################################
# Install the packages that will be used in the workshop, they only need to be installed
# once. 
install.packages("remotes")
install.packages("ggplot2")

# Load the packages 
library("remotes")
library("ggplot2")

# Use install_github (a remotes) function to download, install, and compile 
# R hector from github. This will only need to be done once. 
install_github("JGCRI/hector")

# Load the hector pacakges.
library("hector")

## Example: Run RCP45 #######################################################
# List all of the ini files that are included in the Hector package. 
list.files(system.file("input", package = "hector"))

# Select an ini file to use to set up a hector core. 
ini_file = system.file("input/hector_rcp45.ini", package = "hector")
ini_file

# Set up a hector core with the ini file. 
hcore = newcore(inifile = ini_file, name = "default rcp45")
hcore

# Run hector! 
run(core = hcore)
hcore

# Query the results 
dates = 1850:2100 # define the dates of data we want
dates

var = GLOBAL_TEMP() # define the variable/s we want to look at. 
var

data1 = fetchvars(core = hcore, dates = dates, var = var) 
data1

# plot the data 
ggplot(data = data1) + 
  geom_line(aes(year, value, color = scenario)) + 
  labs(title = "Hector Global Mean Temp", 
       y = "deg C")

# Shut down the core. 
shutdown(core = hcore)
hcore


## Example: Change a parameter  #######################################################
ini_file = system.file("input/hector_rcp45.ini", package = "hector")
ini_file

hcore = newcore(inifile = ini_file, name = "ECS x 2 rcp45")
hcore

default_ECS = fetchvars(hcore, dates = NA, vars = ECS())
default_ECS

doubble_ECS = default_ECS$value * 2
doubble_ECS

ECS_units = getunits(ECS())
ECS_units

setvar(core = hcore, dates = NA, var = ECS(), values = doubble_ECS, 
       unit = ECS_units)
hcore

run(hcore)

data2 = fetchvars(core = hcore, dates = dates, vars = GLOBAL_TEMP())
data2

single_df = rbind(data1, data2)

ggplot(data = single_df) + 
  geom_line(aes(year, value, color = scenario)) + 
  labs(title = "Hector Global Mean Temp", 
       y = "deg C")


## R Documentation  #######################################################
help("hector")
help("ECS")



## R Application  #######################################################
# Example of how to write a basic function 
name <- function(input){
  out = input + input
  return(out)
}

name(2)
name(8)

# Set up a Hector core with a new ECS value, run, and fetch results 
# Args 
#   core: core created by the newcore functionn
#   value: a value to use for ECS
# Return: a data frame of Hector results
run_with_param <- function(core, value){
  # reset Hector core with some ECS value
  setvar(core = core, dates = NA, var = ECS(), value = value, 
         unit = getunits(ECS()))
  
  # run
  run(core = core)
  
  # query results 
  result = fetchvars(core = core, dates = 1850:2100,
                     vars = c(GLOBAL_TEMP(), OCEAN_SURFACE_TEMP(), NPP()))

  # add the ECS value 
  result$ECS = as.character(round(x = value, digits = 3))
  
  # return the output 
  return(result)
  }

# test out run_with_param
ini_file = system.file("input/hector_rcp85.ini", package = "hector")
hector_rcp85 = newcore(inifile = ini_file)

# run hector with some new ECS value 
data = run_with_param(core = hector_rcp85, value = 4)
head(data)

# Run Hector mulitple times with different values 
# Args 
#   core: core created by the newcore functionn
#   value: a vector of values to use as values for ECS
# Return: a single data frame that of results 
run_with_param_range <- function(core, values){
  
  # lapply is a way to apply a function to a vector, run
  # multiple times without having to use a  for loop. 
  list <- lapply(values, run_with_param, core = core)
  
  # combine all the results returned by the lapply into 
  # a single data frame.
  out <- do.call("rbind", list)
  
  # return the output
  return(out)
  
}

# run_with_param_range()
ECS_values = seq(from = 1.5, to = 4.5, length.out = 10)
ECS_values

data_rcp85 = run_with_param_range(core = hector_rcp85, values = ECS_values)

# repeate for the rcp 26 scenario
ini_file = system.file("input/hector_rcp26.ini", package = "hector")
hector_rcp26 = newcore(inifile = ini_file)
data_rcp26 = run_with_param_range(hector_rcp26, values = ECS_values)

# modify the scenario names
data_rcp26$scenario = "rcp26"
data_rcp85$scenario = "rcp85"

# combine into a single data frame
data = rbind(data_rcp26, data_rcp85)

# plot
ggplot(data = data) + 
  geom_line(aes(year, value, color = ECS, linetype = scenario)) +
  facet_wrap("variable", scales = "free")


