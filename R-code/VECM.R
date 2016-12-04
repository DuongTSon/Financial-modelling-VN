##################################################################################
## This project is for macroeconomic forecasting
## Goals: Forecast GDP, Inflation, Credit growth, interest rate and exchange rate.
## Reference paper: Inflation dynamics in Vietnam IMF paper 2013 <https://www.imf.org/external/pubs/ft/wp/2013/wp13155.pdf>
## The paper used VAR model for explanation of infaltion in Vietnam. I took the same variable, but found cointegration among variables.
## Therefore I switched to VECM model which provides better fit and forecasting power.
## I used 2 more variables which are deposit rate and oil spot price.
##
###################################################################################

#Load library
library(zoo)
library(xts)
library(ggplot2)
library(vars)
library(tseries)
library(urca)
library(gridExtra)
library(knitr)
library(quantmod)
library(forecast)

# Oil monthly data
d<-read.csv("../Data/VECM_data.csv",header=TRUE,sep=",")
quarter<-as.yearqtr(d[,1],format="%Y Q%q")
d<-xts(d[,-c(1)],order.by=quarter)

# Split the data into two set
##Actual set
actual<-log(d)
## Training set
training<-window(actual,start=as.yearqtr("2000 Q1",format="%Y Q%q"),end=as.yearqtr("2015 Q3",format="%Y Q%q"))

data<-actual

# Test for stationary
data<-actual

adf.matrix<-matrix(0,7,2)
adf<-data.frame(names(data),adf.matrix)

names(adf)<-c("Variable","ADF","p-value")

for (i in 1:7){
  t<-adf.test(data[,i])
  adf[i,2]<-t$statistic
  adf[i,3]<-t$p.value}

#Order selection AIC criteria
order<-VARselect(data,lag.max=4,type="both",season=4)
order.select<-as.numeric(order$selection[1])

#Cointegration test
vecm<-ca.jo(data,type="trace",K=order.select,season=4,ecdet="trend",spec="transitory")
rank.test<-cbind(test=vecm@teststat,vecm@cval)
coint.rank=2
vecm.r2<-cajorls(vecm,r=4)
vecm.level<-vec2var(vecm,r=4)

#Diagnostic testing
##Test heteroscedasticity
var.arch<-arch.test(vecm.level,lags.multi=5,multivariate.only=T)

##Testing for normality
var.norm<-normality.test(vecm.level,multivariate.only=T)

##Testing serial correlation
var.serial<-serial.test(vecm.level,lags.pt=20,type="PT.asymptotic")

#Impulse response function
irf.deposit.lending<-irf(vecm.level,impulse="Deposit_rate",response="Lending_rate",n.ahead=12,boot=T)
irf.oil.cpi<-irf(vecm.level,impulse="oil",response="CPI",n.ahead=12,boot=T)

#Forecast
## Forecast horizon
horizon=4

x<-c(1:horizon)
for (i in 1:horizon){
  if (horizon==1){x[1]<-max(quarter)+0.25}
  else {x[1]<-max(quarter)+0.25
  x[i]<-max(x)+0.25}
}
x<-as.yearqtr(x)

## Forecast
p<-predict(vecm.level,n.ahead=horizon)
forecast<-p$fcst

##Create forecast matrices for each variable
variable<-names(data)
f.list<-list()

for (i in 1:length(variable)){
  value<-cbind(data[,i],lower=data[,i],upper=data[,i])
  f<-as.data.frame(forecast[i])
  f<-data.frame(f[,1:3])
  f<-xts(f,x)
  f<-rbind(value,f)
  f<-exp(f)
  f.list[[i]]<-assign(as.character(variable[i]),f)
}

output.var<-c("GDP (%YoY)","Inflation (%YoY)","Credit growth (%YoY)","Lending rate (%)","NEER")
output.matrix<-matrix(0,nrow=5,ncol=horizon)
output.table<-data.frame(output.var,output.matrix)
length<-length(index(f.list[[1]]))
names(output.table)<-c("Indicators",as.character(index(f.list[[1]][(length-horizon+1):length])))

date<-index(f.list[[1]])

# Convert GDP forecast
gdp.growth<-Delt(as.numeric(GDP[,1]),k=4,type="arithmetic")*100
# Inflation forecast
cpi.growth<-Delt(as.numeric(CPI[,1]),k=4,type="arithmetic")*100
# Credit growth forecast
credit.growth<-Delt(as.numeric(Credit[,1]),k=4,type="arithmetic")*100
# Lending rate forecast
lending<-as.numeric(Lending_rate[,1])
# Exchange rate
exrate<-as.numeric(Exchange_rate[,1])

output<-data.frame(gdp.growth,cpi.growth,credit.growth,lending,exrate)
output<-xts(output,date)
output<-window(output,start=index(f.list[[1]][(length-horizon+1)]))

output.table[,2:ncol(output.table)]<-as.numeric(t(output))

kable(output.table,digits=2,format="markdown")




