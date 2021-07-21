//+------------------------------------------------------------------+
//|                                                        Teste.mq5 |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include "MainFunctionBackup.mqh"
 MqlTick last_tick;
BordersOperation bordersTicks;
BordersOperation bordersTicksTest;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
//---
 bordersTicks.max = 0;
 bordersTicks.min = 100;

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
   if(hasNewCandle()){
       resetTicks();
   }else{
      if(hasPositionOpen() == false){
         if(SymbolInfoTick(Symbol(),last_tick)){
            int copiedPrice = CopyRates(_Symbol,_Period,0,1,candles);
            if(copiedPrice == 1){
               if(candles[0].close > bordersTicks.max){
                  bordersTicks.max = candles[0].close;
               }
               
               if(candles[0].close < bordersTicks.min){
                  bordersTicks.min = candles[0].close;
               }
               
               
               double media = (last_tick.bid + last_tick.ask) / 2;
               double pointsMax = MathAbs(bordersTicks.max - media) / _Point;
               double pointsMin = MathAbs(bordersTicks.min - media) / _Point;
               if(pointsMax > pointsMin && (pointsMax - pointsMin) > PONTUATION_ESTIMATE){
                  bordersTicksTest.max = pointsMax;
                  bordersTicksTest.min = pointsMin;
                  toBuyOrToSellTesteRobot(UP,STOP_LOSS, TAKE_PROFIT);
               }
               if(pointsMin > pointsMax && (pointsMin - pointsMax) > PONTUATION_ESTIMATE){
                  bordersTicksTest.max = pointsMax;
                  bordersTicksTest.min = pointsMin;
                  toBuyOrToSellTesteRobot(DOWN,STOP_LOSS, TAKE_PROFIT);
               }   
            }
         }
      }else{
         if(bordersTicksTest.max >50 || bordersTicksTest.min > 50){
            resetTicks();
         }
      }
   }
}
//+------------------------------------------------------------------+

void resetTicks(){
 closeBuyOrSell(0);
 bordersTicks.max = 0;
 bordersTicks.min = 100;
 bordersTicksTest.max = 0;
 bordersTicksTest.min = 0;
}

void toBuyOrToSellTesteRobot(ORIENTATION orient, double stopLoss, double takeProfit){
  toBuyOrToSell(orient,ACTIVE_VOLUME,stopLoss,takeProfit);
  if(verifyResultTrade()){
  }
}