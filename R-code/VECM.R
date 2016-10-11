##################################################################################
## This project is for macroeconomic forecast in my company
## Goals: Forecast GDP, Inflation, Credit growth, interest rate and exchange rate.
## Reference paper: Inflation dynamics in Vietnam IMF paper 2013 <https://www.imf.org/external/pubs/ft/wp/2013/wp13155.pdf>
## The paper used VAR model for explanation of infaltion in Vietnam. I took the same variable, but found cointegration among variables.
## Therefore I switched to VECM model which provides better fit and forecasting power in my case.
## I used 2 more variables which are deposit rate and oil spot price.
##
###################################################################################

# Load library
library(zoo)
library(xts)
library(ggplot2)
library(quantmod)
library(imputeTS)
library(vars)
library(urca)

# Oil monthly data
oil<-read.csv("oilprice.csv",header=T)
month<-as.yearmon(oil[,1],"%Y M%m")
oil<-xts(oil[,2],order.by=month)

## Convert to quarterly data
q<-rep(0,length(seq(1,length(oil),by=3)))
j=0
for (i in seq(1,length(oil),by=3)) {
      j=j+1
      q[j]<-mean(oil[i:(i+2)])}

quarter<-seq(as.Date(head(index(oil),1)),as.Date(tail(index(oil),1)),by="quarters")
quarter<-as.yearqtr(quarter,format="%Y-%m-%d")
oil<-xts(q,quarter)
oil<-oil[index(oil)>="2000 Q1"]


# Macroeconomic data
data<-read.csv("MacroData.csv",header=T)
date<-as.yearqtr(data[,1],format="%YQ%q")
data<-apply(data[,-c(1)],2,as.numeric)
data<-xts(data,date)
data[,8]<-data[,8]/data[,1]*100

# Fill missing data in credit variable
credit<-na.kalman(as.numeric(data$Credit),model="StructTS",smooth=T,nit=-1)

# Final dataset
data[,4]<-credit
d<-merge(data,oil,all=T)
d.clean<-d[,-c(2,8)]
d.clean<-log(d.clean)


# Test for stationary
 adf.matrix<-matrix(0,7,2)
 adf<-data.frame(names(d.season),adf.matrix) 
 names(adf)<-c("Variable","ADF","p-value")

 for (i in 1:7){
   t<-adf.test(d.season[,i])
   adf[i,2]<-t$statistic
   adf[i,3]<-t$p.value}
 adf

# Order selection AIC criteria
order<-VARselect(d.clean,lag.max=4,type="both",season=4)
order.select<-as.numeric(order$selection[1])

# Cointegration test and chose cointegration rank
vecm<-ca.jo(d.clean,type="trace",K=4,season=4,ecdet="trend",spec="transitory")
vecm.r2<-cajorls(vecm,r=4)
vecm.level<-vec2var(vecm,r=4)

# Get t-stats of alpha and beta of VECM
alpha<-coef(vecm.r2$rlm)[1,]
beta<-vecm.r2$beta
resids<-resid(vecm.r2$rlm)
N<-nrow(resids)
sigma<-crossprod(resids)/N
##t-stat for alpha
alpha.se<-sqrt(solve(crossprod(
                cbind(vecm@ZK %*% beta,vecm@Z1)))
                [1,1]*diag(sigma))
alpha.t<-alpha/alpha.se
##t-stats for beta
beta.se<-sqrt(diag(kronecker(solve(
              crossprod(vecm@RK[,-1])),
              solve(t(alpha) %*% solve(sigma)
              %*% alpha))))
beta.t<-c(NA,beta[-1]/beta.se)


#Diagnostic testing

##Test heteroscedasticity
var.arch<-arch.test(vecm.level,lags.multi=5,multivariate.only=T)

##Testing for normality
var.norm<-normality.test(vecm.level,multivariate.only=F)

##Testing serial correlation
var.serial<-serial.test(vecm.level,lags.pt=20,type="PT.asymptotic")

#Impulse response function
vecm.irf<-irf(vecm.level,impulse="Deposit_rate",response="Lending_rate",n.ahead=8,boot=T)

# Forecast
## Forecast horizon
horizon=1
x<-c(1:horizon)
for (i in 1:horizon){
  if (horizon==1){x[1]<-max(date)+0.25}
  else {x[1]<-max(date)+0.25
  x[i]<-max(x)+0.25}
}
x<-as.yearqtr(x)

## Forecast
p<-predict(vecm.level,n.ahead=horizon)
forecast<-p$fcst

## Create forecast matrices for each variable
variable<-names(d.clean)
f.list<-list()
for (i in 1:length(variable)){
value<-cbind(d.clean[,i],lower=d.clean[,i],upper=d.clean[,i])
f<-as.data.frame(forecast[i])
f<-data.frame(f[,1:3])
f<-xts(f,x)
f<-rbind(value,f)
f<-exp(f)
f.list[[i]]<-assign(as.character(variable[i]),f)
}


# Plot
## GDP plot
gdp.growth<-apply(GDP,2,function(x) Delt(x,k=4,type="arithmetic"))
gdp.growth<-data.frame(date=as.Date(as.yearqtr(index(GDP)),frac=1),gdp.growth)
gdp.growth<-na.omit(gdp.growth)
gdp.gvis<-gvisLineChart(gdp.growth,xvar="date",yvar=c("GDP","GDP.1","GDP.2"),options=list(
                        series="[{color:'purple'}]",
                        intervals="{'style':'boxes'}",
                        title="GDP forecast"))
plot(gdp.gvis)
