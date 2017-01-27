
## Test implicit weights of currency baskets
## SDR is the numeraire

#Load library
library(xts)
library(tseries)

rate<-read.csv("data/sdr.csv",sep=",")
## Convert to SDR
eur<-rate$eurusd/rate$xdrusd
usd<-1/(rate$xdrusd)
vnd<-1/(rate$usdvnd*rate$xdrusd)
others<-1/(rate[,-c(1,2,3,ncol(rate))]*rate$xdrusd)
sdr<-data.frame(rate$date,vnd,usd,eur,others)
colnames(sdr)<-c("date","vnd","usd","eur","cny","jpy","krw","sgd","twd","thb")

sdr$date<-as.Date(sdr$date,format="%Y-%m-%d")
data<-xts(sdr[,-c(1)],sdr$date)
data<-diff(log(data))
data<-na.omit(data)

rate.2016<-window(data,start=as.Date("01-01-2016",format="%d-%m-%Y"),end=as.Date("31-12-2016",format="%d-%m-%Y"))

library(tseries)

fit.2016<-lm(vnd~.,data=rate.2016)
summary(fit.2016)