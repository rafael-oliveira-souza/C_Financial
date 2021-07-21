//+------------------------------------------------------------------+
//|                                                        Media.mq5 |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include "MainFunctionBackup.mqh"

double averageML[], averageMH[], averageMD[];
int handleMh, handleMl, handleMd, countAverage = 3;
ORIENTATION orientationMacroMedia = MEDIUM;
double valueDealEntryPriceMedia = 0;
bool waitNewCandleMedia = false;
bool crossedAverage = false;
int reachedAverage = false;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
     handleMh = iMA(_Symbol,PERIOD_CURRENT,PERIOD,0,MODE_SMA,PRICE_HIGH);
     handleMl = iMA(_Symbol,PERIOD_CURRENT,PERIOD,0,MODE_SMA,PRICE_LOW);
     handleMd = iMA(_Symbol,PERIOD_CURRENT,2,0,MODE_SMA,PRICE_CLOSE);
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
         waitNewCandleMedia = false;
         countAverage < 0 ? 0 : countAverage--;
      }else{
         if(countAverage <= 0){
            if(waitNewCandleMedia == false){
               orientationMacroMedia = startMediaRobot();
            }
               
            if(hasPositionOpen()){
               int copiedPrice = CopyRates(_Symbol,_Period,0,2,candles);
               if(copiedPrice == 2){
                  if(CopyBuffer(handleMd,0,0,3,averageMD) == 3){
                     double margH =  averageMH[0];
                     double margL =  averageML[0];
                     ORIENTATION or1 = verifyAverage(averageMD[0], averageMD[1]); 
                     ORIENTATION or2 = verifyAverage(averageMD[1], averageMD[2]); 
                     if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL ){ 
                        if(averageMD[2] > margL && candles[1].close < margL){
                           closeBuyOrSell(0);
                           //double points = (MathAbs(margH - margL) / 2) / _Point;
                           //toBuyOrToSellMediaRobot(DOWN, STOP_LOSS, TAKE_PROFIT); 
                           //waitNewCandleMedia = false;
                        }else{
                           if(candles[1].close < margL){
                              if((or1 == UP && or2 == DOWN) || (or2 == UP && or1 == DOWN)) {
                                 closeBuyOrSell(0);
                                 reachedAverage = false;
                              }
                           }
                        }
                     }else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ){
                        if(averageMD[2] < margH && candles[1].close > margH){
                           closeBuyOrSell(0);
                           //double points = (MathAbs(margH - margL) / 2) / _Point;
                           //toBuyOrToSellMediaRobot(DOWN, STOP_LOSS, TAKE_PROFIT); 
                           //waitNewCandleMedia = false;
                        }else{
                           if(candles[1].close > margH){
                              if((or1 == UP && or2 == DOWN) || (or2 == UP && or1 == DOWN)) {
                                 closeBuyOrSell(0);
                                 reachedAverage = false;
                              }
                           }
                        }
                     }
                     /* if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL ){ 
                        if(candles[1].close > margH){
                           closeBuyOrSell(0);
                        }else {
                           if((or1 == UP && or2 == DOWN) || (or2 == UP && or1 == DOWN)) {
                              closeBuyOrSell(0);
                              reachedAverage = false;
                           }
                           if(candles[1].close < margL){
                             // valueDealEntryPriceMedia = activeStopMovel(valueDealEntryPriceMedia, candles[1], 0, true);
                              if(reachedAverage == true){
                                 if((or1 == UP && or2 == DOWN) || (or2 == UP && or1 == DOWN)) {
                                    closeBuyOrSell(0);
                                    reachedAverage = false;
                                 }
                              }else{
                                 reachedAverage = true;
                                 closeBuyOrSell(0);
                                 double points = (MathAbs(margH - margL) / 2) / _Point;
                                 toBuyOrToSellMediaRobot(DOWN, points, TAKE_PROFIT); 
                              }
                           }
                        }   
                     }else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ){
                        if(candles[1].close < margL){
                           closeBuyOrSell(0);
                        }else{
                           if((or1 == UP && or2 == DOWN) || (or2 == UP && or1 == DOWN)) {
                              closeBuyOrSell(0);
                              reachedAverage = false;
                           }
                           if(candles[1].close > margH){
                             // valueDealEntryPriceMedia = activeStopMovel(valueDealEntryPriceMedia, candles[1], 0, true);
                               if(reachedAverage == true){
                                 if((or1 == UP && or2 == DOWN) || (or2 == UP && or1 == DOWN)) {
                                    closeBuyOrSell(0);
                                    reachedAverage = false;
                                 }
                              }else{
                                 reachedAverage = true;
                                 closeBuyOrSell(0);
                                 double points = (MathAbs(margH - margL) / 2) / _Point;
                                 toBuyOrToSellMediaRobot(UP, points, TAKE_PROFIT); 
                              }
                           }
                        }
                     }*/
                  }
              }
            }
         }
     }
   }
}

ORIENTATION startMediaRobot(){
   int copiedPrice = CopyRates(_Symbol,_Period,0,2,candles);
   if(copiedPrice == 2){
      if(hasPositionOpen() == false){
         if(CopyBuffer(handleMh,0,0,1,averageMH) == 1 &&  CopyBuffer(handleMl,0,0,1,averageML) == 1 &&  CopyBuffer(handleMd,0,0,2,averageMD) == 2){
            orientationMacroMedia = verifyAverage(averageMD[0], averageMD[1]);
            
            if(orientationMacroMedia == UP){
               if(averageMD[0] < averageML[0] && averageMD[1] >= averageML[0]){
                  toBuyOrToSellMediaRobot(UP, STOP_LOSS, TAKE_PROFIT); 
               }
            }else if(orientationMacroMedia == DOWN){
               if(averageMD[0] > averageMH[0] && averageMD[1] <= averageMH[0]){
                  toBuyOrToSellMediaRobot(DOWN, STOP_LOSS, TAKE_PROFIT); 
               }
            }
         }
      }
   }
   
   return MEDIUM;
}

void toBuyOrToSellMediaRobot(ORIENTATION orient, double stopLoss, double takeProfit){
  if(waitNewCandleMedia == false){
     toBuyOrToSell(orient,ACTIVE_VOLUME,stopLoss,takeProfit);
     if(verifyResultTrade()){
        valueDealEntryPriceMedia = 0;
        waitNewCandleMedia = true;
     }
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