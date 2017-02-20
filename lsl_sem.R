rm(list=ls())
set.seed=4869
library(dplyr);library(gtools)

source('/Volumes/phaksie/Dropbox/lsl2_beta/lsl_tool.R')
source('/Volumes/phaksie/Dropbox/lsl2_beta/lsl_functions.R')

model.cfa<-'
F1=~0.8*x1+0.8*x2+0.8*x3
F2=~0.8*x4+0.8*x5+0.8*x6
F3=~0.8*x7+0.8*x8+0.8*x9
x1~~(1-0.8^2)*x1
x2~~(1-0.8^2)*x2
x3~~(1-0.8^2)*x3
x4~~(1-0.8^2)*x4
x5~~(1-0.8^2)*x5
x6~~(1-0.8^2)*x6
x7~~(1-0.8^2)*x7
x8~~(1-0.8^2)*x8
x9~~(1-0.8^2)*x9
F2~~1*F2
F3~~1*F3
F1~~1*F1
F1~~0.4*F2
F1~~0.4*F3
F2~~0.4*F3
'

dta       <- lavaan::simulateData(model.cfa,sample.nobs = 10000L) #%>% cbind(.,sample(c(1,2),size=nrow(.),rep=T))


#dta       <- lavaan::HolzingerSwineford1939[7:15]

n_gps     <- 2
n_obs     <- ncol(dta)
n_lat     <- 3
M         <- n_obs + n_lat
Sigma     <- t(dta) %>% as.data.frame %>% lapply(tcrossprod) %>% simplify2array %>% apply(1:2,mean)
e_v       <- sapply(dta,mean)[1:n_obs]
nm<-c(paste0("v",1:n_obs),paste0("f",1:n_lat))

lambda <- matrix(NA, 9, 3)
lambda[c(1,2,3), 1] <- lambda[c(4,5,6), 2] <- lambda[c(7,8,9), 3] <- 1

Beta_p    <- matrix(0, ncol = M, nrow = M) %>% `colnames<-`(nm) %>% `rownames<-`(nm)
Beta_p[c(1,2,3), 10] <- Beta_p[c(4,5,6), 11] <- Beta_p[c(7,8,9), 12] <- 1  
Beta      <- Beta <- 0.8*.is_one(Beta_p) #starting value of Beta
Beta[c(2,3), 10] <- Beta[c(5,6), 11] <- Beta[c(8,9), 12] <- 1  

# Phi_p     <- matrix(0,M,M)
# Phi       <- matrix(0,M,M)
# Phi[(n_obs+1):M,(n_obs+1):M] <- 0.4
# diag(Phi) <- 1-0.8^2
# Phi[10,10]<-Phi[11,11]<-Phi[12,12]<-1

mat       <- matgen(lambda=lambda,Beta = Beta,scale=T)

#mat       <- matgen(lambda=lambda)

eta       <- vector(mode = "numeric",M)   %>%`names<-`(nm)
zeta      <- vector(mode = "numeric",M)   %>%`names<-`(nm)
ide       <- diag(1, ncol = M, nrow = M)  %>% `colnames<-`(nm) %>% `rownames<-`(nm) 
G_obs     <- c(rep(T,n_obs),rep(F,n_lat)) %>%`names<-`(nm)
v         <- subset(eta,G_obs)

#ECM

#ecm       <- function(mat=mat,ide=ide,G_obs=G_obs){
            alpha_p   <- mat$pattern$alpha_p
            Beta_p    <- mat$pattern$Beta_p
            Phi_p     <- mat$pattern$Phi_p
            alpha     <- mat$value$alpha
            Beta      <- mat$value$Beta
            Phi       <- mat$value$Phi
            #model-implied matrix
            
            IBinv     <- solve(ide-Beta)
            mu_eta    <- IBinv%*%alpha
            Sigma_etaeta<-IBinv%*%Phi%*%t(IBinv)
            
            w_g       <- 1
            alpha_g   <- vector(mode = "numeric",M)
            JK        <- expand.grid(1:M,1:M)[2:1]
            JLK       <- expand.grid(1:(M-1),1:M)[2:1]
            Beta_g    <- matrix(0, M, M)
            Phi_g     <- matrix(0, M, M)
            
            ini       <- list(IBinv=IBinv,mu_eta=mu_eta,Sigma_etaeta=Sigma_etaeta,Sigma=Sigma,G_obs=G_obs,e_v=e_v,mat=mat)
 
            for (it in 1:500){
              e_step    <- estep(ini)
              cm_step   <- cmstep(w_g=w_g,JK=JK,JLK=JLK,alpha_g=alpha_g,Beta_g=Beta_g,Phi_g=Phi_g,mat=ini$mat,e_step=e_step,type="MCP")
              ini$IBinv          <- solve(ide-cm_step$Beta)
              ini$mu_eta         <- ini$IBinv%*%cm_step$alpha
              ini$Sigma_etaeta   <- ini$IBinv%*%cm_step$Phi%*%t(ini$IBinv)
              ini$mat$value$Beta <- cm_step$Beta
              ini$mat$value$alpha<- cm_step$alpha
              ini$mat$value$Phi  <- cm_step$Phi
              
            }
            
            theta     <- c(cm_step$alpha[.is_est(ini$mat$pattern$alpha_p)],cm_step$Beta[.is_est(ini$mat$pattern$Beta_p)],cm_step$Phi[.is_est(ini$mat$pattern$Phi_p)])
            length(theta)
            
            dml_cal(Sigma=Sigma,e_v=e_v,Sigma_vv=subset(ini$Sigma_etaeta,G_obs,G_obs),mu_v=subset(ini$mu_eta,G_obs))
            
          
#}


# increment components weights
w_alpha_u <- sapply(c(1:M), function(j) {1/w_g*phi[j,j]})
w_beta_u  <- mapply(function(j,k) 1/(w_g*solve(Phi[j,j])*C_etaeta[k,k]), j=JK[,1], k=JK[,2] ,SIMPLIFY = T) %>% matrix(nrow=M,byrow=T)
diag(w_beta_u)<-0
w_phi_u   <- matrix(0, M, M)
w_phiq_u  <- mapply(function(j,lk) 1/((w_g/varphi[j])*C_zetatildazetatilda[[j]][lk,lk]),j=JLK[,1],lk=JLK[,2],SIMPLIFY = "matrix") %>% matrix(nrow=M,byrow=T)
w_phi_u[upper.tri(w_phi_u)]<-w_phiq_u[upper.tri(w_phiq_u,diag=T)]
w_phi_u[lower.tri(w_phi_u)]<-w_phiq_u[lower.tri(w_phiq_u)]

# increment components updating

