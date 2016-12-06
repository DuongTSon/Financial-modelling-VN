
###################################################
# This model would forecast overnight interest rate
# I use ARFIMA instead of ARIMA because the long memory property of interbank interest rate.
# I test for long memory by function acf()
# Some of my code was from Quantstart.com
###################################################

#import library
library(rugarch)
library(reshape2)
library(ggplot2)
library(xts)
library(scales)


#Import data
data<-read.csv("../Data/Interbankrate.csv",header=T)
date<-as.Date(data[,1],"%d-%b-%y")
on<-as.numeric(data[,2])
on.data<-xts(on,date)

#Forecast horizon
x<-seq(as.Date(max(date)+1),as.Date(max(date)+31),"days")
x<-x[!weekdays(x)%in%c("Saturday","Sunday")]
horizon<-length(x)

# fit the ARIMA model
	final.aic<-Inf
	final.order<-c(0,0,0)

	for (p in 0:5) for (q in 0:5){
	if (p==0&&q==0){
	next
	}
	arimaFit<-tryCatch(arima(on.data,order=c(p,0,q)),
				error=function(err) FALSE,
				warning=function(err) FALSE)
	if (!is.logical(arimaFit)){
	current.aic<-AIC(arimaFit)
	if(current.aic<final.aic){
		final.aic<-current.aic
		final.order<-c(p,0,q)
		final.arima<-arima(on.data,order=final.order)
		}
	}else {
		next
			}
	}

#specify and fit the Garch
spec<-ugarchspec(
	variance.model=list(model="sGARCH",garchOrder=c(1,1)),
	mean.model=list(armaOrder=c(final.order[1],final.order[3]),include.mean=TRUE,arfima=T),
	distribution.model="norm"
)

#Fit garch model
fit<-ugarchfit(spec,on.data,solver="hybrid")

##Forecast
fore<-ugarchforecast(fit,n.ahead=horizon)

#Convert xts format to data frame
on.data<-data.frame(date=index(on.data),on=as.numeric(on.data))

#Fitted values
fitted.on<-as.numeric(fitted(fit))
fitted.on<-data.frame(date=on.data[,1],fitted.on=fitted.on)

fitted.sigma<-as.numeric(sigma(fit))
fitted.sigma<-data.frame(date=on.data[,1],fitted.sigma=fitted.sigma)

#Actual data
actual<-data.frame(on.data)

#Forecast data
forecast.on<-as.numeric(fitted(fore))
forecast.sigma<-as.numeric(sigma(fore))
forecast<-data.frame(date=x,forecast.on,forecast.sigma)

#Data set for plot
graphset<-merge(actual,fitted.on,by="date",all=T)
graphset<-merge(graphset,fitted.sigma,by="date",all=T)
graphset<-merge(graphset,forecast,by="date",all=T)
graphset[is.na(graphset$forecast.sigma),]$forecast.sigma<-0

#Combine fitted vector
graphset$fitted.on<-c(rep(NA,0),fitted.on$fitted.on,forecast$forecast.on)
graphset$fitted.sigma<-c(rep(NA,0),fitted.sigma$fitted.sigma,forecast$forecast.sigma)

i<-which(graphset$date==as.Date("2016-01-04",format="%Y-%m-%d"),arr.ind=T)
graphsetcut<-graphset[c(i:length(graphset[,1])),]
on.graphset.melt<-melt(graphsetcut[,c("date","on","fitted.on")],id="date")
sigma.graphset.melt<-melt(graphsetcut[,c("date","fitted.sigma")],id="date")

#Rate prediction plot
meanplot<-ggplot(on.graphset.melt,aes(x=date,y=value))+
	geom_ribbon(data=graphsetcut,aes(x=date,y=fitted.on,ymin=fitted.on-2*forecast.sigma,ymax=fitted.on+2*forecast.sigma),alpha=0.2,fill="green")+
	geom_ribbon(data=graphsetcut,aes(x=date,y=fitted.on,ymin=fitted.on-1*forecast.sigma,ymax=fitted.on+1*forecast.sigma),alpha=0.5,fill="green")+
	geom_line(aes(colour=variable),size=1)+
	geom_vline(xintercept=as.numeric(max(actual[,1])),linetype="longdash")+
	xlab("Date")+ylab("Percent")+
	theme(legend.position="bottom",legend.title=element_blank())+
	scale_color_manual(values= c("#009E73", "#D55E00"),labels=c("Overnight rate","Model's forecast"))+
	ggtitle("Overnight lending rate forecast\nARFIMA(4,q,4)")+
	scale_x_date(date_breaks="1 month",
			labels=date_format("%b"),
			limits=as.Date(c(min(graphsetcut$date),max(graphsetcut$date))))+
	annotate("text",x=max(graphsetcut$date)-5,y=1.5,label="Forecast",colour="#CC79A7",fontface=2)

#Volatility plot
Volplot<-ggplot(sigma.graphset.melt,aes(x=date,y=value))+
	geom_line(aes(colour=value),size=2)+
	scale_colour_gradient(low="green",high="red"
	,name="Risk level"
	,breaks=c(min(graphsetcut$fitted.sigma),(min(graphsetcut$fitted.sigma)+max(graphsetcut$fitted.sigma))/2,max(graphsetcut$fitted.sigma))
	,labels=c("Low","Medium","High")
	,limits=c(min(graphsetcut$fitted.sigma),max(graphsetcut$fitted.sigma)))+
	geom_vline(xintercept=as.numeric(max(actual[,1])),linetype="longdash")+
	theme(legend.title=element_text(colour="red",size=12,face="bold"),legend.position="bottom")+
	scale_x_date(date_breaks="1 month",
			labels=date_format("%b"),
			limits=as.Date(c(min(graphsetcut$date),max(graphsetcut$date))))+
	xlab("Date")+ylab("Percent")+
	ggtitle("Risk forecast\nGARCH(1,1)")+
	guides(colour=guide_colorbar(title.position="top"))+
	annotate("text",x=max(graphsetcut$date)-5,y=0.3,label="Forecast",colour="#CC79A7",fontface=2)
