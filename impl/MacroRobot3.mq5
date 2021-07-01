//+------------------------------------------------------------------+
//|                                                        Media.mq5 |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

input string TIME_TO_START_AVALIATION = "10:30";

#include "MainFunctionBackup.mqh"

//input double INIT_POINT = 0;

double channelSize = PONTUATION_ESTIMATE;
double initPointMacro = 0;
double endPointMacro = 0;

BordersOperation bordersSupportAndResistanceMacro;
ORIENTATION orientationMacroRobot = MEDIUM;
datetime startedDatetimeMacroRobot = 0;
ResultOperation resultDealsRobotMedia;
double valueDealEntryPriceMacro = 0;
bool crossOverBorderMacro = false;
int waitNewCandleMacro = 0;
int lastDayMediaRobot = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
     resultDealsRobotMedia.total = 0;
     startedDatetimeMacroRobot = TimeCurrent();
     drawVerticalLine(startedDatetimeMacroRobot, "start day", clrRed);
     bordersSupportAndResistanceMacro.max = 0;
     bordersSupportAndResistanceMacro.min = 1000;
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
      int copiedPrice = CopyRates(_Symbol,_Period,0,4,candles);
      if(copiedPrice == 4){
         if(hasNewCandle()){
            if(isPossibleStartDeals(candles[3].close)){
               waitNewCandleMacro--;
               activeStopMovelPerPointsMacroRobot(candles[0], candles[1], candles[2]);
            }
         }else{
            if(isPossibleStartDeals(candles[3].close)){
               if(waitNewCandleMacro <= 0){
                  if(hasPositionOpen() == false){
                     if(!crossOverBorderMacro){
                        orientationMacroRobot = recoverOrientation(candles[3].close);
                        decideToBuyOrSellMacroRobot(orientationMacroRobot, candles[3].close);
                     }
                  }else{
                     //valueDealEntryPriceMacro = activeStopMovelPerPoints(channelSize, candles[1]);
                  }
               }
            }
        }
      }
  }else{
      closeBuyOrSell(0);
  }
}

void decideToBuyOrSellMacroRobot(ORIENTATION orient, double closePrice){
      
   if(orient != MEDIUM ){
      if(hasPositionOpen() == false){ 
         double neededPoints = 0;
         if(orient == UP){
            neededPoints = (initPointMacro + (channelSize * _Point));
            if( closePrice > neededPoints){
               double points = calcPoints(endPointMacro, closePrice);
               //neededPoints = (initPointMacro + (neededPoints * _Point));
               crossOverBorderMacro = true;
               toBuyOrToSellMediaRobot(orient, points, TAKE_PROFIT);
            }
         }else if(orient == DOWN){
            neededPoints = (endPointMacro - (channelSize * _Point));
            if( closePrice < neededPoints){
               double points = calcPoints(initPointMacro, closePrice);
               //neededPoints = (endPointMacro + (neededPoints * _Point));
               crossOverBorderMacro = true;
               toBuyOrToSellMediaRobot(orient, points, TAKE_PROFIT);
            }
         }
      }
   }
}

bool isPossibleStartDeals(double closePrice){
   if(isNewDay(startedDatetimeMacroRobot)){
      startedDatetimeMacroRobot = TimeCurrent();
      drawVerticalLine(startedDatetimeMacroRobot, "start day" + TimeToString(startedDatetimeMacroRobot), clrRed);
      bordersSupportAndResistanceMacro.min = 1000;
      bordersSupportAndResistanceMacro.max = 0;
      crossOverBorderMacro = false;
      initPointMacro = 0;
      endPointMacro = 0;
      closeBuyOrSell(0);
   }
   
   if(initPointMacro == 0 || endPointMacro == 0){
      // verificar se ja existe a borda de suporte
      datetime timeLocal = TimeCurrent();
      datetime start = StringToTime(TIME_TO_START_AVALIATION);
      if(timeLocal > start){
         initPointMacro = bordersSupportAndResistanceMacro.max;
         endPointMacro = bordersSupportAndResistanceMacro.min;
         drawHorizontalLine(endPointMacro, TimeCurrent(), "support border", clrYellow);
         drawHorizontalLine(initPointMacro, TimeCurrent(), "resistance border", clrYellow);
         
         double midPoints = calcPoints(initPointMacro, endPointMacro) * 0.25;
         if(midPoints > PONTUATION_ESTIMATE){
            channelSize = midPoints;
         }
      }else{
         if(closePrice >  bordersSupportAndResistanceMacro.max){
            bordersSupportAndResistanceMacro.max = closePrice;
         }else if(closePrice <  bordersSupportAndResistanceMacro.min){
            bordersSupportAndResistanceMacro.min = closePrice;
         }
      }
   }
   
   return (initPointMacro != 0 && endPointMacro != 0);
}

void toBuyOrToSellMediaRobot(ORIENTATION orient, double stopLoss, double takeProfit){
  toBuyOrToSell(orient,ACTIVE_VOLUME,stopLoss,takeProfit);
  if(verifyResultTrade()){
     valueDealEntryPriceMacro = 0;
     waitNewCandleMacro = 1;
  }
}

ORIENTATION recoverOrientation(double closePrice){
   if(closePrice > initPointMacro){
      return UP;
   }else if(closePrice < endPointMacro){
      return DOWN;
   }
   
   return MEDIUM;
}

void  activeStopMovelPerPointsMacroRobot(MqlRates& candleSecondLast, MqlRates& candleLast, MqlRates& actualCandle){
  if(hasPositionOpen()){ 
      double entryPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      double bodyLast = calcPoints(candleLast.close, candleLast.open);
      double bodySecLast = calcPoints(candleSecondLast.close, candleSecondLast.open);
      double shadowH, shadowL, points;
      
      if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ){
         if(verifyIfOpenBiggerThanClose(candleLast)){
            shadowH = calcPoints(candleLast.high, candleLast.open);
            shadowL = calcPoints(candleLast.low, candleLast.close);
            points = calcPoints(initPointMacro, actualCandle.close);
            // martelo
            bool isHammer = (shadowH > shadowL + bodyLast);
            if((bodyLast > bodySecLast || isHammer) && actualCandle.close < candleLast.open){
               closeBuyOrSell(0);
               crossOverBorderMacro = true;
               if(verifyResultTrade()){
                  toBuyOrToSellMediaRobot(DOWN, channelSize, points);
              }
            }
         }
      }else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL ){
         if(!verifyIfOpenBiggerThanClose(candleLast)){
            shadowH = calcPoints(candleLast.close, candleLast.high);
            shadowL = calcPoints(candleLast.low, candleLast.open);
            points = calcPoints(endPointMacro, actualCandle.close);
            // martelo
            bool isHammer = (shadowL > shadowH + bodyLast);
            if((bodyLast > bodySecLast || isHammer) && actualCandle.close > candleLast.open){
               closeBuyOrSell(0);
               crossOverBorderMacro = true;
               if(verifyResultTrade()){
                   toBuyOrToSellMediaRobot(UP, channelSize, points);
               }
            }
         }
      }
   }
}
    