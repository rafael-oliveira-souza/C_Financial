//+------------------------------------------------------------------+
//|                                                        Media.mq5 |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include "MainFunctionBackup.mqh"

input double INIT_POINT = 0;
input double END_POINT = 0;

double channelsMacro[22];
ORIENTATION orientationMacroMedia = MEDIUM;
datetime startedDatetimeMacroRobot = 0;
ResultOperation resultDealsRobotMedia;
double valueDealEntryPriceMacro = 0;
int waitNewCandleMacro = 0;
int lastDayMediaRobot = 0;
BordersOperation selectedBordersMacro;
bool overCrossChannel = false;
double pontuationMacro = 0;
bool achievedGain = false;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
     resultDealsRobotMedia.total = 0;
     startedDatetimeMacroRobot = TimeCurrent();
     pontuationMacro = calcPoints(INIT_POINT, END_POINT);
     
     if(INIT_POINT > END_POINT){
         drawChannels(END_POINT, INIT_POINT);
     }else{
         drawChannels(INIT_POINT, END_POINT);
     }
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
      int copiedPrice = CopyRates(_Symbol,_Period,0,2,candles);
      if(copiedPrice == 2){
         if(hasNewCandle()){
            //waitNewCandleMacro--;
               orientationMacroMedia = movingInChannels(candles[0], candles[1]);
               startMacroRobot(orientationMacroMedia, candles[1].close);
         }else{
            //if(hasPositionOpen() == false){
              // valueDealEntryPriceMacro = activeStopMovel(valueDealEntryPriceMacro, candles[0]);
            //}
         }
     }
  }else{
      closeBuyOrSell(0);
  }
}

void drawChannels(double initPoint, double endPoint){
     datetime actualTime = TimeCurrent();
      
     for(int i = 0; i <= 10; i++){
         channelsMacro[10-i] = NormalizeDouble(endPoint + (pontuationMacro * i * _Point), _Digits);
         channelsMacro[11+i] = NormalizeDouble(initPoint - (pontuationMacro * i * _Point), _Digits);
         drawHorizontalLine(channelsMacro[10-i], actualTime, "channel" + IntegerToString(10-i), clrYellow);
         drawHorizontalLine(channelsMacro[11+i], actualTime, "channel" + IntegerToString(11+i), clrYellow);
     }
     selectedBordersMacro.max = endPoint;
     selectedBordersMacro.min = initPoint;
}

ORIENTATION movingInChannels(MqlRates& prevClosePrice, MqlRates& actualClosePrice){
   ORIENTATION orient = MEDIUM;
   double aux, minPontuation = 0.2;
   double margin = (pontuationMacro * minPontuation);
   if(selectedBordersMacro.max < actualClosePrice.close){
      double points = calcPoints(selectedBordersMacro.max, actualClosePrice.close);
      if( points >= margin){
         aux = selectedBordersMacro.max;
         selectedBordersMacro.min = aux;
         selectedBordersMacro.max = NormalizeDouble(aux + (pontuationMacro * _Point), _Digits);
         if(prevClosePrice.open < actualClosePrice.open){
            orient = UP;
         }
      }
   }else if(selectedBordersMacro.min > actualClosePrice.close){
      double points = calcPoints(selectedBordersMacro.min, actualClosePrice.close);
      if( points >= margin){
         aux = selectedBordersMacro.min;
         selectedBordersMacro.max = aux;
         selectedBordersMacro.min = NormalizeDouble(aux - (pontuationMacro * _Point), _Digits);
         if(prevClosePrice.open > actualClosePrice.open){
            orient = DOWN;
         }
      }
   }
   resetChannels(actualClosePrice.close);
   
   return orient;
}

void resetChannels(double closePrice){
   double initPoint, endPoint;
   if(closePrice >= channelsMacro[0]){
      endPoint = NormalizeDouble(channelsMacro[0] + (pontuationMacro * _Point), _Digits);
      initPoint = channelsMacro[0];
      drawChannels(initPoint, endPoint);
   }else if(closePrice <= channelsMacro[21]){
      initPoint = NormalizeDouble(channelsMacro[21] - (pontuationMacro * _Point), _Digits);
      endPoint = channelsMacro[21];
      drawChannels(initPoint, endPoint);
   }
}

void startMacroRobot(ORIENTATION orient, double closePrice){
   if(hasPositionOpen() == false){
      double pointsMax = 0, pointsMin = 0;
      if(orient == UP){
         pointsMin = calcPoints(closePrice, selectedBordersMacro.min);
         pointsMax = calcPoints(closePrice, selectedBordersMacro.max);
         toBuyOrToSellMediaRobot(orient, (pointsMin+ pontuationMacro)*2, pointsMax);
      }else if(orient == DOWN){
         pointsMin = calcPoints(closePrice, selectedBordersMacro.max);
         pointsMax = calcPoints(closePrice, selectedBordersMacro.min);
         toBuyOrToSellMediaRobot(orient, (pointsMin+ pontuationMacro)*2, pointsMax);
      }
   }
   
}

void toBuyOrToSellMediaRobot(ORIENTATION orient, double stopLoss, double takeProfit){
  toBuyOrToSell(orient,ACTIVE_VOLUME,stopLoss,takeProfit);
  if(verifyResultTrade()){
     valueDealEntryPriceMacro = 0;
     waitNewCandleMacro = 1;
  }
}
//+------------------------------------------------------------------+


bool verifyResultToday(){
    if(LOSS_PER_DAY > 0 && PROFIT_PER_DAY > 0){
       int actDay = getActualDay(startedDatetimeMacroRobot);
       if(lastDayMediaRobot == actDay){
          if(!achievedGain){
             double total = calcTotal();
             if(total !=  resultDealsRobotMedia.total){
               resultDealsRobotMedia.total = total;
               bool resultAchieved = verifyResultPerDay(total);
               
               if(resultAchieved){
                  achievedGain = true;
                  Print("Lucro do dia atingido");
               }
               
               return resultAchieved;
             }
          }else{
             return  achievedGain;
          }
      }else{
          achievedGain = false;
          lastDayMediaRobot = actDay;
          resultDealsRobotMedia.total = 0;
          startedDatetimeMacroRobot = TimeCurrent();
      }
   }
   
   return false;
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