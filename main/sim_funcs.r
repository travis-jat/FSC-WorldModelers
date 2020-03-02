# Main simulation loop to implement food shock cascade
#  dP: vector of initial change in production (must be negative) by country
#  rfrac: fraction of actual reserves to use
#  cfrac: fraction of shortage absorbed by domestic production before modifying trade
#  kmax: maximum number of iterations
sim_cascade_v2 <- function(food_net, dP, rfrac = 0.5, cfrac = 0, kmax = 50) {
    # Initial shock and available reserves
    food_net$P <- food_net$P + dP
    food_net$shortage <- -dP 
    food_net$R <- rfrac * food_net$R
    
    # Iterating
    for (k in 1:kmax) {
        # Sequence of steps for each iteration
        new_food_net <- food_net %>%
            draw_reserves() %>%  
            cut_consumption(., amount = cfrac * .$shortage) %>%
            absorb_tiny_shortages() %>%
            realloc_trade_prop_link()
        # Stop if trade matrix is same from previous iteration
        if(all.equal(food_net$E, new_food_net$E) == TRUE) {
            food_net <- new_food_net
            break
        } else if (k == kmax) {
            warning("No equilibrium reached after maximum number of iterations")
        }
        food_net <- new_food_net
    }
    # Final update of consumption to match supply
    food_net$C <- get_supply(food_net)
    food_net
}


# Simulation with new mechanism to reallocate trade
#  (first reduce exports, then incrase imports based on exporters' available reserves)
#  dP: vector of initial change in production (must be negative) by country
#  rfrac: fraction of actual reserves to use
#  rexp: fraction of useable reserves available to increase exports at each iteration
#  cfrac: fraction of shortage absorbed by domestic production before modifying trade
#  kmax: maximum number of iterations
sim_cascade_new <- function(food_net, dP, rfrac = 0.5, rexp = 0.2, cfrac = 0, kmax = 50) {
    # Initial shock and available reserves
    food_net$P <- food_net$P + dP
    food_net$shortage <- -dP 
    food_net$R <- rfrac * food_net$R
    
    # Iterating
    for (k in 1:kmax) {
        # Sequence of steps for each iteration
        new_food_net <- food_net %>%
            draw_reserves() %>%  
            cut_consumption(., amount = cfrac * .$shortage) %>%
            absorb_tiny_shortages() %>%
            reduce_exp_prop_link() %>%
            draw_reserves() %>%  
            cut_consumption(., amount = cfrac * .$shortage) %>%
            absorb_tiny_shortages() %>%
            increase_imp_prop_resv(., avail = rexp * .$R)
        # Stop if trade matrix is same from previous iteration
        if(all.equal(food_net$E, new_food_net$E) == TRUE) {
            food_net <- new_food_net
            break
        } else if (k == kmax) {
            warning("No equilibrium reached after maximum number of iterations")
        }
        food_net <- new_food_net
    }
    # Final update of consumption to match supply
    food_net$C <- get_supply(food_net)
    food_net
}

