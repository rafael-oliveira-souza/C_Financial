//+------------------------------------------------------------------+
//|                                                        Media.mq5 |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include "MainFunctionBackup.mqh"

input  ENUM_MA_METHOD MODE_AVERAGES = MODE_SMA;

double averageML[], averageMH[], averageMD[], averageMDD[];
int handleMh, handleMl, handleMd, handleMdd, countAverage = 3;
ORIENTATION orientationMacroMedia = MEDIUM;
datetime startedDatetimeMediaRobot = 0;
ResultOperation resultDealsRobotMedia;
double valueDealEntryPriceMedia = 0;
int waitNewCandleMedia = 0;
bool waitSecondClose = false;
int lastDayMediaRobot = 0;
ulong numBarsMedia = 0;
bool achievedGain = false;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
     resultDealsRobotMedia.total = 0;
     startedDatetimeMediaRobot = TimeCurrent();
     //handleMh = iMA(_Symbol,PERIOD_CURRENT,PERIOD,0,MODE_AVERAGES,PRICE_HIGH);
     //handleMl = iMA(_Symbol,PERIOD_CURRENT,PERIOD,0,MODE_AVERAGES,PRICE_LOW);
     handleMd = iMA(_Symbol,PERIOD_CURRENT,PERIOD/2,0,MODE_AVERAGES,PRICE_CLOSE);
     handleMdd = iMA(_Symbol,PERIOD_CURRENT,PERIOD/2,2,MODE_AVERAGES,PRICE_CLOSE);
  //---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
  


//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick(){
   
   if(verifyTimeToProtection()){
      if(hasNewCandle()){
         waitNewCandleMedia--;
      }else{
         if(waitNewCandleMedia < 0){
            orientationMacroMedia = startMediaRobot();
         }
         Print("");
      }
   }
}

ORIENTATION startMediaRobot(){
   int copiedPrice = CopyRates(_Symbol,_Period,0,2,candles);
   if(copiedPrice == 2){
      if(hasPositionOpen() == false){
         if( CopyBuffer(handleMd,0,0,3,averageMD) == 3 && CopyBuffer(handleMdd,0,0,3,averageMDD) == 3){
            orientationMacroMedia = verifyAverage(averageMD[0], averageMD[1]);
            ORIENTATION orientMediaAux = verifyAverage(averageMDD[0], averageMDD[1]);
            if(hasPositionOpen() == false){
               datetime actualTime = TimeCurrent();
            }else{
               datetime actualTime = TimeCurrent();
               if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL ){
                  if(orientationMacroMedia != orientMediaAux){
                     if(averageMD[0] > averageMDD[0]){
                        closeBuyOrSell(0);
                        if(verifyResultTrade()){
                         drawVerticalLine(actualTime, "close" + IntegerToString(actualTime), clrAquamarine);
                        }
                     }
                  }
                  
               }else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ){
                  if(orientationMacroMedia != orientMediaAux){
                     if(averageMD[0] < averageMDD[0]){
                        closeBuyOrSell(0);
                        if(verifyResultTrade()){
                         drawVerticalLine(actualTime, "close" + IntegerToString(actualTime), clrAquamarine);
                        }
                     }
                  }
               }
            }
         }
      }
   }
   
   return MEDIUM;
}

void toBuyOrToSellMediaRobot(ORIENTATION orient, double stopLoss, double takeProfit){
  toBuyOrToSell(orient,ACTIVE_VOLUME,stopLoss,takeProfit);
  if(verifyResultTrade()){
     valueDealEntryPriceMedia = 0;
     waitNewCandleMedia = 0;
     numBarsMedia = SeriesInfoInteger(Symbol(),Period(),SERIES_BARS_COUNT);
  }
}
//+------------------------------------------------------------------+

ORIENTATION verifyAverage(double prevAv, double actualAv){
   if(prevAv > actualAv){
      return DOWN;
   }else if(prevAv < actualAv) {
      return UP;
   } else{
      return MEDIUM;
   }
   
}

void verifyIfOpenDealAgainst(ORIENTATION orient, double price, double entryDeal, double& averMD[], double& averMDD[], double& averMDA[]){
   if( entryDeal != 0){
      datetime actualTime = TimeCurrent();
      ORIENTATION or1 = verifyAverage(averMD[0], averMD[1]); 
      ORIENTATION or2 = verifyAverage(averMD[1], averMD[2]); 
      if(orient == UP){
         closeBuyOrSell(0);
         if(price < entryDeal){
             drawVerticalLine(actualTime, "inversion" + IntegerToString(actualTime), clrWhite);
             if(AGAINST_CURRENT == ON){  
                 if((or1 == DOWN && or2 == UP) || (or2 == DOWN && or1 == UP)){
                      toBuyOrToSellMediaRobot(DOWN, STOP_LOSS, TAKE_PROFIT);
                 }
             }
             waitNewCandleMedia = WAIT_CANDLES;
         }
         /**/
      }else if(orient == DOWN){
         closeBuyOrSell(0);
         if(price > entryDeal){
             drawVerticalLine(actualTime, "inversion" + IntegerToString(actualTime), clrWhite);
             if(AGAINST_CURRENT == ON){
                  if((or1 == DOWN && or2 == UP) || (or2 == DOWN && or1 == UP)){
                      toBuyOrToSellMediaRobot(UP, STOP_LOSS, TAKE_PROFIT);
                 }
             }
             waitNewCandleMedia = WAIT_CANDLES;
         }
         /**/
      } 
   }
}
