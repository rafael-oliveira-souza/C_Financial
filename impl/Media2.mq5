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

double averageML[], averageMH[], averageMD[];
int handleMh, handleMl, handleMd, countAverage = 3;
ORIENTATION orientationMacroMedia = MEDIUM;
datetime startedDatetimeMediaRobot = 0;
ResultOperation resultDealsRobotMedia;
double valueDealEntryPriceMedia = 0;
bool waitNewCandleMedia = false;
int reachedAverage = false;
ulong numBarsMedia = 0;
int lastDayMediaRobot = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
     resultDealsRobotMedia.total = 0;
     startedDatetimeMediaRobot = TimeCurrent();
     handleMh = iMA(_Symbol,PERIOD_CURRENT,PERIOD,0,MODE_AVERAGES,PRICE_HIGH);
     handleMl = iMA(_Symbol,PERIOD_CURRENT,PERIOD,0,MODE_AVERAGES,PRICE_LOW);
     handleMd = iMA(_Symbol,PERIOD_CURRENT,2,0,MODE_AVERAGES,PRICE_CLOSE);
     handleMdd = iMA(_Symbol,PERIOD_CURRENT,2,-2,MODE_AVERAGES,PRICE_CLOSE);
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
  

void OnTradeTransaction(const MqlTradeTransaction & trans,
                        const MqlTradeRequest & request,
                        const MqlTradeResult & result)
  {
   if(trans.order_state == ORDER_STATE_FILLED){
   }   
  
   ResetLastError(); 
} /**/
 
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick(){
   bool resultAchieved = false;
   int actDay = getActualDay(startedDatetimeMediaRobot);
   if(lastDayMediaRobot == actDay){
       resultAchieved = verifyResultPerDay(calcTotal());
   }else{
       lastDayMediaRobot = actDay;
       startedDatetimeMediaRobot = TimeCurrent() ;
       resultDealsRobotMedia.total = 0;
   }
   
   if(verifyTimeToProtection() && !resultAchieved){
      if(hasNewCandle()){
         waitNewCandleMedia = false;
         countAverage < 0 ? 0 : countAverage--;  
           /*  if(hasPositionOpen()){
               if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL ){ 
                  if(recoveryOrientation() == UP){
                     closeBuyOrSell(0);
                  }
               }
               if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ){ 
                  if(recoveryOrientation() == DOWN){
                     closeBuyOrSell(0);
                  }
               }
            closeBuyOrSell(0); 
            }*/
      }else{
         if(countAverage <= 0){
            if(waitNewCandleMedia == false){
               orientationMacroMedia = startMediaRobot();
            }
            if(hasPositionOpen()){
               int copiedPrice = CopyRates(_Symbol,_Period,0,2,candles);
               if(copiedPrice == 2){
                  ulong numBars = SeriesInfoInteger(Symbol(),Period(),SERIES_BARS_COUNT);
                  if(numBars > numBarsMedia + PERIOD){
                     double entryDeal = PositionGetDouble(POSITION_PRICE_OPEN);
                     double point = MathAbs(entryDeal - candles[0].close) / _Point;
                     if(point > PONTUATION_ESTIMATE){
                        if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL ){ 
                           closeBuyOrSell(0);
                           //toBuyOrToSellMediaRobot(DOWN, STOP_LOSS, TAKE_PROFIT); 
                        }else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ){ 
                           closeBuyOrSell(0);
                           //toBuyOrToSellMediaRobot(UP, STOP_LOSS, TAKE_PROFIT); 
                        }
                        
                     }
                  }
               }else{
                  if(copiedPrice == 2){
                     if(CopyBuffer(handleMd,0,0,3,averageMD) == 3){
                        double margH =  averageMH[0];
                        double margL =  averageML[0];
                        ORIENTATION or1 = verifyAverage(averageMD[0], averageMD[1]); 
                        ORIENTATION or2 = verifyAverage(averageMD[1], averageMD[2]); 
                        double entryDeal = PositionGetDouble(POSITION_PRICE_OPEN);
                        if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL ){ 
                           if(recoveryOrientation(2) == UP){
                              //if(entryDeal > candles[1].close){
                                 closeBuyOrSell(0); 
                             // }
                           }else{
                              if(candles[0].close < averageML[0] && 
                               (averageMD[0] < averageML[0] || averageMD[1] < averageML[0]) &&
                               averageMD[2] >= averageML[0]){
                                 closeBuyOrSell(0); 
                              }
                           }
                        }else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ){
                           if(recoveryOrientation(2) == DOWN){
                             // if(entryDeal < candles[1].close){
                                 closeBuyOrSell(0); 
                             // }
                               //toBuyOrToSellMediaRobot(DOWN, STOP_LOSS, TAKE_PROFIT); 
                           }else{
                              if(candles[0].close > averageMH[0] &&
                               (averageMD[0] > averageMH[0] || averageMD[1] > averageMH[0]) && 
                                averageMD[2] < averageMH[0]){
                                 closeBuyOrSell(0);
                              }
                           }
                        }
                     }
                  }
               }
            }
         }
     }
  }else{
      if(resultAchieved){
         Print("Lucro do dia atingido");
      }
      
      closeBuyOrSell(0);
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
  toBuyOrToSell(orient,ACTIVE_VOLUME,stopLoss,takeProfit);
  if(verifyResultTrade()){
     valueDealEntryPriceMedia = 0;
     waitNewCandleMedia = true;
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

ORIENTATION recoveryOrientation(int max){
   int copiedPrice = CopyRates(_Symbol,_Period,0,max,candles);
   int up = 0, down = 0;
   if(copiedPrice == max){
      for(int i = 0; i < max-1; i++){
         if(candles[i].open <= candles[i+1].open && candles[i].close <= candles[i+1].close){
            up++;
         }else{
            if(candles[i].open >= candles[i+1].open && candles[i].close >= candles[i+1].close){
               down++;
            }
         }
         
       /* if(i > 0){
           if(candles[0].open <= candles[i+1].open && candles[0].close <= candles[i+1].close){
              up++;
           }else{
               if(candles[0].open >= candles[i+1].open && candles[0].close >= candles[i+1].close){
               down++;
              }
           }
         }*/
      }
   }
   
   if(down >= (max)){
      return DOWN;
   }
   else if(up > (max )){
      return UP;
   }
   
   return MEDIUM;
}