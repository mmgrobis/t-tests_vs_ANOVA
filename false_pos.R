######################################################################################################
# Display distribution of p-values from multiple t-tests vs. ANOVA
# Author: Matt Grobis
#
# - Purpose: demonstrate flaws in multiple t-test comparisons
# - Requirements: 'scales' package
#
######################################################################################################
# Prerequisite: install 'scales' package if necessary
try(library(scales),
    outFile = install.packages('scales'))

#####################################################################################################
# The function
# - Summary:
#   o For each of n_groups, draw n_obs from a population that is normally distributed
#      x Because these groups are all drawn from the same distribution, they should not be
#        significantly different (i.e. p > 0.05)
#   o Perform all possible pairwise t-tests and record the lowest p-value
#   o Perform an ANOVA on all groups and record the p-value
#   o Do this n_iter times to form a distribution

false_pos <- function(n_groups = 3, n_obs = 10, n_iter = 1000, p.val = 0.05, verbose = T, 
                      figure = T, pretty = T){
   
   # Create empty variables to store data
   t_test_p_vals <- c()
   anova_p_vals <- c()
   groups <- list()
   
   # Run through the iterations
   for(i in 1:n_iter){
      
      # Create the samples
      for(j in 1:n_groups){
         
         groups[[j]] <- rnorm(n_obs)  # Default mean = 0, SD = 1
         
      }
      
      # Generate all pairwise comparisons
      combinations <- combn(n_groups, 2)
      
      # Run the comparisons
      p_vals <- c()
      
      for(k in 1:ncol(combinations)){
         p_vals[k] <- t.test(groups[[combinations[1, k]]],
                             groups[[combinations[2, k]]])$p.value
         
      }
      
      # Save the lowest p-value 
      t_test_p_vals[i] <- min(p_vals)
      
      # Convert list to data frame for ANOVA
      pops_df <- data.frame("values" = unlist(groups),  
                            "group" = sort(rep(1:n_groups, n_obs)))
      
      # Run the ANOVA and save p-value
      anova_p_vals[i] <- summary(aov(values ~ group, data = pops_df))[[1]][["Pr(>F)"]][1]
      
      # Print % completion every 10 iterations
      if(verbose == T){
         if(i %%10 == 0){
            cat(round(i / n_iter * 100, 2), "% complete \n")
         }
      }
   }
   
   # If figure = T, display it
   if(figure == T){
      
      # Ensure 'scales' library is installed
      try(library(scales), outFile = print("Please install 'scales' library first"))
      
      par(mfrow = c(1,1))
      hist(t_test_p_vals, main = "Distribution of p-values\n", xlab = "p-value", font.lab = 2, 
           font.axis = 2, las = 1, breaks = 25, col = alpha("black", 0.4), xlim = c(0,1), 
           cex.lab = 1.2, cex.axis = 1.1)
      hist(anova_p_vals, main = "ANOVA", add = T, border = "deepskyblue4", breaks = 25,
           col = alpha("deepskyblue4", 0.4))
      title(paste0("\nGroups: ", n_groups, " | Observations: ", n_obs, " | Iterations: ", n_iter),
            col.main = "gray40")
      par(font = 2)
      legend("topright", bty = 'n', pch = 19, c("Multiple t-tests", "ANOVA"),
             col = c(alpha("black", 0.4), alpha("deepskyblue4", 0.4)))
      
   }
   
   # Save summary stats of t-tests vs. ANOVAs otherwise
   if(pretty == T){
      
      # Display probability of false positives
      cat("\n")
      cat("% iterations below p =", p.val, "\nt-tests:", 
          round(sum(t_test_p_vals < p.val) / n_iter, 3) * 100, "| ANOVA:",
          round(sum(anova_p_vals < p.val) / n_iter, 3) * 100)
      cat("\n\n")
   }
   
   if(pretty == F){
      df <- data.frame("t-tests" = sum(t_test_p_vals < p.val) / n_iter,
                       "ANOVA" = sum(anova_p_vals < p.val) / n_iter)
      
      dists <- data.frame("stat" = names(summary(t_test_p_vals)),
                          "t-test" = as.vector(summary(t_test_p_vals)),
                          "ANOVA" = as.vector(summary(anova_p_vals)))
      
      L <- list(df, dists)
      names(L) <- c(paste0("Prop_iter_p<", p.val), "Full")
      
      cat("\n")
      return(L)
      
   }
   
}

######################################################################################################
# Demo

# Defaults
false_pos()

# 100x n_obs: negligible decrease in false positive rate
false_pos(n_obs = 1000)

# 3x n_pop: ~3x increase in false positive rate
false_pos(n_pop = 6, n_obs = 10)

# Competing effects: n_pop wins
false_pos(n_pop = 6, n_obs = 1000)

####################################################################################################
# Parameter scan

# Set values of interest for n_obs and n_groups
range_n_obs <- c(2, 5, 50, 100, 250, 500, 1000, 2500, 5000)
range_n_groups <- 3:10

# Create empty matrices to store t-test and ANOVA p-values
t_test_vals <- anova_vals <- matrix(NA, nrow = length(range_n_groups), ncol = length(range_n_obs))

# Label the rows and columns
rownames(t_test_vals) <- rownames(anova_vals) <- range_n_groups
colnames(t_test_vals) <- colnames(anova_vals) <- range_n_obs

#-------------------------------------------------------------------------------------------
# For each number of groups
for(i in 1:length(range_n_groups)){
   
   # For each number of observations
   for(j in 1:length(range_n_obs)){
      
      # Print the values we're running
      cat("Processing: N groups =", range_n_groups[i], "| N observations =", range_n_obs[j])
      
      # Run the comparison
      values <- false_pos(n_groups = range_n_groups[i], n_obs = range_n_obs[j], p.val = 0.05,
                          verbose = F, figure = F, pretty = F)[['Prop_iter_p<0.05']]
      
      # Save the values
      t_test_vals[i, j] <- values$t.tests
      anova_vals[i, j] <- values$ANOVA
      
   }
   
}

#---------------------------------------------------------------------------------------------
#Now actually plot it
library(lattice)
library(RColorBrewer)
library(grid)
library(gridExtra)

# Set up color gradient with 10000 values between 0.0 and 0.7
# - Set bias in colorRampPalette so green values are below 0.05
breaks <- seq(0, 0.7, by=0.0001)
cols <- colorRampPalette(c("forestgreen", "yellow", "orange", 
                           "red", "brown", "black"), bias = 1.4)(length(breaks)-1)

# Save plots as variables
p1 <- levelplot(t_test_vals, at = breaks, col.regions = cols, xlab = " ", ylab = " ",
                main = "t-tests")

p2 <- levelplot(anova_vals, at=breaks, col.regions=cols, xlab = " ", ylab = " ",
                main = "ANOVA")

# Plot side-by-side comparison
grid.arrange(p1, p2, ncol = 2, 
             top = textGrob("Probability of false positive", 
                            gp = gpar(fontsize = 28, font = 2)),
             bottom = textGrob("Number of groups\n",
                               gp = gpar(fontsize = 16, font = 2)),
             left = textGrob("\nSample size",
                             gp = gpar(fontsize = 16, font = 2), rot = 90))

#----------------------------------------------------------------------------------------------
# ANOVA plots
par(mfrow=c(1,2))

# Density
plot(density(anova_vals), xlab = "False positive rate", font.axis = 2, font.lab = 2, cex.lab = 1.3,
     main = "Distribution of ANOVA\n false positive rates", col = "forestgreen", lwd = 3, cex.main = 1.4)
abline(v = 0.05, lty = 2, lwd = 2)

# Number of groups versus p-value
plot(NA, xlim = range(range_n_groups), ylim = c(0.045, 0.055), xlab = "Number of groups",
     ylab = "Mean false positive rate", cex.main = 1.4, cex.lab = 1.3, 
     main = "Number of groups vs.\n mean ANOVA false positive rate", 
      font.lab = 2, font.axis = 2)
abline(h = 0.05, lty = 2, lwd = 2)
points(range_n_groups, apply(anova_vals, 1, mean), cex = 2.5, pch = 19, col = "forestgreen")
points(range_n_groups, apply(anova_vals, 1, mean), cex = 2.5)

#################################################################################################
# p = 0.01 ANOVA visualization

# Set values of interest for n_obs and n_groups
range_n_obs2 <- c(5, 10, 25, 50, 100, 250, 500)
range_n_groups2 <- 3

# Create empty matrices to store t-test and ANOVA p-values
anova_vals2 <- matrix(NA, nrow = length(range_n_groups2), ncol = length(range_n_obs2))

# Label the rows and columns
rownames(anova_vals2) <- range_n_groups2
colnames(anova_vals2) <- range_n_obs2

#-------------------------------------------------------------------------------------------
# For each number of groups
for(i in 1:length(range_n_groups2)){
   
   # For each number of observations
   for(j in 1:length(range_n_obs2)){
      
      # Print the values we're running
      cat("Processing: N groups =", range_n_groups2[i], "| N observations =", range_n_obs2[j])
      
      # Run the comparison
      values <- false_pos(n_groups = range_n_groups2[i], n_obs = range_n_obs2[j], p.val = 0.01,
                          verbose = F, figure = F, pretty = F, n_iter = 10000)[['Prop_iter_p<0.01']]
      
      # Save the values
      anova_vals2[i, j] <- values$ANOVA
      
   }
   
}

# Plot it
plot(density(anova_vals2), col = "forestgreen", lwd = 3, xlab = "False positive rate", 
     font.lab = 2, main = "ANOVA false positive rate\np = 0.01", cex.main = 1.4, cex.lab = 1.3, 
     font.axis = 2)
abline(v = 0.01, lty = 2, lwd = 2)
