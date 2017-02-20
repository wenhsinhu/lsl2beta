betagen   <- function(lambda){
  
  Beta_p                          <- matrix(0, ncol = M, nrow = M)
  Beta_p[(1:n_obs),(n_obs+1):M]   <- lambda
  #Beta_p[(n_obs+1):M,(n_obs+1):M] <- diag(1,n_lat,n_lat)
  return(Beta_p)
  
}

matgen    <- function(alpha_p,Beta_p,Phi_p,alpha,Beta,Phi,lambda,scale=T){
  
  #pattern matarices generation
  #only 3 matrices have pattern matrix, including alpha, beta, Phi
    
  if (missing(alpha_p)) {   alpha_p <- c(rep(1,n_obs),rep(0,n_lat)) %>% `names<-`(nm) }
  if (missing(Beta_p))  {
    if (missing(lambda)) { 
      stop("lambda matrix is not specified")
    } else { 
      Beta_p                        <- betagen(lambda) 
    }
  }
  if (missing(Phi_p)) {
    Phi_p                           <- matrix(diag(1,M,M), ncol = M, nrow = M)
    Phi_p[(n_obs+1):M,(n_obs+1):M]  <- 1
    colnames(Phi_p)                 <- nm
    rownames(Phi_p)                 <- nm
  }
  
  #matrices generation
  
  if (missing(alpha)) {
    alpha <- c(sapply(dta,mean)[1:n_obs],rep(0,n_lat)) %>% `names<-`(nm)}
  if (missing(Beta))  {
    Beta  <- 1 *.is_est(Beta_p)
    colnames(Beta)  <- nm
    rownames(Beta)  <- nm
    }
  if (missing(Phi))   {
    Phi   <- matrix(diag(c(rep(0.1,n_obs,n_obs),rep(1,n_lat,n_lat))), ncol = M, nrow = M)
    colnames(Phi)   <- nm
    rownames(Phi)   <- nm
    }
  if (scale) {Beta_p[apply(Beta_p[(1:n_obs),(n_obs+1):M] == 1, 2, function(x) min(which(x))) %>% cbind((n_obs+1):M)] <- 0}　
  
  
  return(list(pattern=list(alpha_p=alpha_p,Beta_p=Beta_p,Phi_p=Phi_p),value=list(alpha=alpha,Beta=Beta,Phi=Phi)))
  
}

threshold <- function(theta,gma){
   sign(theta)*max(abs(theta)-gma,0) 
}

varphi    <- function(m,Phi) {diag(Phi)[m]-Phi[m,-m]%*%solve(Phi[-m,-m])%*%Phi[-m,m]}

penalty   <- function(theta,gamma,cth,w,delta,type){
  if (type == "l1") {
    theta <- threshold(theta, gamma * cth * w)
  } else if (type == "SCAD") {
    if (abs(theta) <= gamma * (1 + cth * w)) {
      theta <- threshold(theta, cth * w * gamma)
    } else if (gamma * (1 + cth * w) < abs(theta) & abs(theta) <= gamma * delta) {
      theta <- threshold(theta, (cth * w * gamma * delta) / (delta - 1)) / (1 - ((cth * w) / (delta - 1)))
    } else { }
  } else if (type == "MCP") {
    if (abs(theta) <= gamma * delta) {
      theta <- threshold(theta, cth * w * gamma) / (1 - ((cth * w) / delta))
    } else { }
  }
  return(theta)
}

estep     <- function(ini){
  mu_v      <- subset(ini$mu_eta,ini$G_obs)
  Sigma_veta<- subset(ini$Sigma_etaeta,ini$G_obs)
  Sigma_etav<- t(Sigma_veta)
  Sigma_vv  <- subset(ini$Sigma_etaeta,ini$G_obs,ini$G_obs)
  J         <- ini$mu_eta - Sigma_etav %*% solve(Sigma_vv) %*% mu_v
  K         <- Sigma_etav %*% solve(Sigma_vv)
  C_vv      <- ini$Sigma
  e_eta     <- J+K%*%ini$e_v
  C_etaeta  <- ini$Sigma_etaeta - Sigma_etav %*% solve(Sigma_vv) %*% Sigma_veta +
    J %*% t(J) + J %*% t(ini$e_v) %*% t(K) + K %*% ini$e_v %*% t(J) + K %*% C_vv %*% t(K)
  
  return(list(e_eta=e_eta, C_etaeta=C_etaeta))
}

cmstep    <- function(w_g=w_g,JK=JK,JLK=JLK,alpha_g=alpha_g,Beta_g=Beta_g,Phi_g=Phi_g,mat=ini$mat,e_step=e_step,type=type){
  if (missing(type)) {type<-"l1"}
  
  e_eta     <- e_step$e_eta
  C_etaeta  <- e_step$C_etaeta
  Phi_u       <- mat$value$Phi
  Beta_u      <- mat$value$Beta
  alpha_u     <- mat$value$alpha
  phi       <- solve(Phi_u) # for alpha and Beta
  M         <- length(mat$pattern$alpha_p)

  ## reference components updating

  # alpha
  
  w_alpha_u   <- sapply(c(1:M), function(j) {1/(w_g*phi[j,j])})
  for (j in which(.is_est(mat$pattern$alpha_p))){
    alpha_u[j]   <- w_alpha_u[j] * ( w_g * phi[j,j] * (e_eta[j] - alpha_g[j] - Beta[j,] %*% e_eta) +
                                   w_g * phi[j,-j] %*% (e_eta - (alpha_u + alpha_g) - Beta %*% e_eta)[-j])
  }

  # Beta
  
  #ww<-matrix(0,M,M)
  for (i in which(.is_est(mat$pattern$Beta_p))){
    k      <- ceiling(i/M)
    j      <- i-(k-1)*M
    w_beta_u <-  1/(w_g*phi[j,j]*C_etaeta[k,k])
    bet_u    <- w_beta_u * (w_g * phi[j,j] * (C_etaeta[j,k] - e_eta[k] * alpha[j] - Beta_u[j,-k] %*% C_etaeta[-k,k] - Beta_g[j,] %*% C_etaeta[,k])+
                                 w_g * phi[j,-j] %*% (C_etaeta[-j,k] - e_eta[k] * alpha[-j] - (Beta_u[-j,] + Beta_g[-j,]) %*% C_etaeta[,k]))
    
    cth<-is.na(mat$pattern$Beta_p[i])
    Beta_u[j,k]<-penalty(theta=bet_u,gamma=0.075,cth=cth,w=w_beta_u,delta=2.5,type=type)
    #ww[j,k]<-w_beta
  }
  
  # Phi
  
  alpha<- alpha_u
  Beta <- Beta_u
  Phi  <- Phi_u
  
  C_zetazeta<- C_etaeta - e_eta%*%alpha -  C_etaeta %*% t(Beta) - alpha %*% t(e_eta) +
    alpha %*% t(alpha) + alpha %*% t(e_eta) %*% t(Beta) - Beta %*% t(C_etaeta) + 
    Beta %*% e_eta %*% t(alpha) + Beta %*% C_etaeta %*% t(Beta)
  
  for (i in which(.is_est(mat$pattern$Phi_p))){
    k      <- ceiling(i/M)
    j      <- i-(k-1)*M
    if (j<=k) {} else {
      lk<-k
      
      C_zetatildazeta     <- solve(Phi_u[-j,-j])%*%C_zetazeta[-j,]
      C_zetatildazetatilda<- solve(Phi_u[-j,-j])%*%C_zetazeta[-j,-j]%*%solve(Phi_u[-j,-j])
      var_phi   <- sapply(c(1:M), varphi, Phi_u)
      w_phi_u     <- 1/((w_g/var_phi[j])*C_zetatildazetatilda[lk,lk])
      
      Phi_u[j,k]<- w_phi_u * (w_g / var_phi[j]) * (C_zetatildazeta[lk,j] - Phi_u[j,-c(j,k)] %*% matrix(C_zetatildazetatilda[-lk,lk]) - 
                                                 Phi_g[j,-j] %*% C_zetatildazetatilda[,lk])
    }
  }
  Phi_u[upper.tri(Phi_u)]<-t(Phi_u)[upper.tri(Phi_u)]


  for (j in 1:M){
    C_zetatildazeta<- solve(Phi_u[-j,-j])%*%C_zetazeta[-j,]
    C_zetatildazetatilda<- solve(Phi_u[-j,-j])%*%C_zetazeta[-j,-j]%*%solve(Phi_u[-j,-j])
    Phi_u[j,j] <- w_g * (C_zetazeta[j,j] - 2 * (Phi_u[j,-j]+Phi_g[j,-j]) %*% C_zetatildazeta[,j] + (Phi_u[j,-j]+Phi_g[j,-j]) %*% C_zetatildazetatilda %*% (Phi_u[-j,j]+Phi_g[-j,j])) +
      Phi[j,-j] %*% solve(Phi[-j,-j]) %*% Phi[-j,j]
  }

  ## increment components updating
  #alpha
  w_alpha_g <- sapply(c(1:M), function(j) {1/w_g*phi[j,j]})
  for (j in which(.is_est(mat$pattern$alpha_p))){
    alpha_g[j]   <- w_alpha_u[j] * ( w_g * phi[j,j] * (e_eta[j] - (alpha[j]+alpha_u[j]) - (Beta[j,]+Beta_u[j,]) %*% e_eta) +
                                   w_g * phi[j,-j] %*% (e_eta - alpha - alpha_u - Beta %*% e_eta)[-j])
  }
  
  
  return(list(alpha=alpha_u,
              Beta=Beta_u,
              Phi=Phi_u))
} 

dml_cal   <- function(Sigma=Sigma,e_v=e_v,Sigma_vv=subset(ini$Sigma_etaeta,G_obs,G_obs),mu_v=subset(ini$mu_eta,G_obs)){
  Sigma_vv_iv <- solve(Sigma_vv)
  dml <- -log(det(Sigma_vv_iv %*% Sigma)) + sum(diag(Sigma_vv_iv%*%Sigma)) - dim(Sigma_vv)[1] + t(e_v-mu_v) %*% Sigma_vv_iv %*% (e_v-mu_v)
  return(dml)
  }